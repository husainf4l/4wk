import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  final String sessionId;
  final String clientId;
  final String carId;
  final String garageId;
  final String? reportId; // For editing existing report
  final Map<String, dynamic>? sessionData; // For displaying session context

  const ReportScreen({
    super.key,
    required this.sessionId,
    required this.clientId,
    required this.carId,
    required this.garageId,
    this.reportId,
    this.sessionData,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for editable text fields
  final _clientNotesController = TextEditingController();
  final _inspectionNotesController = TextEditingController();
  final _testDriveNotesController = TextEditingController();

  // Data holders for aggregated information
  List<String> _clientImages = [];
  List<TextEditingController> _clientRequestsControllers = [];

  List<String> _inspectionImages = [];
  List<TextEditingController> _inspectionFindingsControllers = [];

  List<String> _testDriveImages = [];
  List<TextEditingController> _testDriveObservationsControllers = [];

  // Additional data for enhanced report
  DateTime? _sessionStartTime;
  DateTime? _sessionEndTime;
  String _overallStatus = 'Pending';
  Map<String, dynamic> _reportStats = {};
  final List<Map<String, dynamic>> _timeline = [];

  @override
  void initState() {
    super.initState();
    _loadAndAggregateSessionData();
  }

  @override
  void dispose() {
    _clientNotesController.dispose();
    _inspectionNotesController.dispose();
    _testDriveNotesController.dispose();

    for (var controller in _clientRequestsControllers) {
      controller.dispose();
    }
    for (var controller in _inspectionFindingsControllers) {
      controller.dispose();
    }
    for (var controller in _testDriveObservationsControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadAndAggregateSessionData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('session_activities')
              .where('sessionId', isEqualTo: widget.sessionId)
              .orderBy('createdAt', descending: false)
              .get();

      // Calculate session timing
      if (snapshot.docs.isNotEmpty) {
        _sessionStartTime = (snapshot.docs.first.data()['createdAt'] as Timestamp?)?.toDate();
        _sessionEndTime = (snapshot.docs.last.data()['createdAt'] as Timestamp?)?.toDate();
      }

      for (var doc in snapshot.docs) {
        final activity = doc.data();
        final stage = activity['stage'] as String?;
        final createdAt = (activity['createdAt'] as Timestamp?)?.toDate();

        // Add to timeline
        if (createdAt != null && stage != null) {
          _timeline.add({
            'stage': stage,
            'time': createdAt,
            'notes': activity['notes'] ?? '',
            'hasImages': (activity['images'] as List?)?.isNotEmpty ?? false,
          });
        }

        // Helper to safely convert List<dynamic> to List<String>
        List<String> dynamicListToStringList(List<dynamic>? dynamicList) {
          if (dynamicList == null) return [];
          return dynamicList.map((e) => e.toString()).toList();
        }

        switch (stage) {
          case 'clientNotes':
            _clientNotesController.text = activity['notes'] ?? '';
            _clientImages = dynamicListToStringList(
              activity['images'] as List?,
            );
            _clientRequestsControllers =
                dynamicListToStringList(
                  activity['requests'] as List?,
                ).map((text) => TextEditingController(text: text)).toList();
            break;
          case 'inspection':
            _inspectionNotesController.text = activity['notes'] ?? '';
            _inspectionImages = dynamicListToStringList(
              activity['images'] as List?,
            );
            _inspectionFindingsControllers =
                dynamicListToStringList(
                  activity['findings'] as List?,
                ).map((text) => TextEditingController(text: text)).toList();
            break;
          case 'testDrive':
            _testDriveNotesController.text = activity['notes'] ?? '';
            _testDriveImages = dynamicListToStringList(
              activity['images'] as List?,
            );
            _testDriveObservationsControllers =
                dynamicListToStringList(
                  activity['observations'] as List?,
                ).map((text) => TextEditingController(text: text)).toList();
            break;
        }
      }

      // Calculate report statistics
      _calculateReportStats();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load session data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateReportStats() {
    final totalImages = _clientImages.length + _inspectionImages.length + _testDriveImages.length;
    final totalFindings = _clientRequestsControllers.length + _inspectionFindingsControllers.length + _testDriveObservationsControllers.length;
    final duration = _sessionEndTime?.difference(_sessionStartTime ?? DateTime.now()).inMinutes ?? 0;
    
    _reportStats = {
      'totalImages': totalImages,
      'totalFindings': totalFindings,
      'duration': duration,
      'completedStages': _timeline.length,
    };

    // Determine overall status
    if (_inspectionFindingsControllers.isNotEmpty) {
      _overallStatus = 'Issues Found';
    } else if (_timeline.length >= 3) {
      _overallStatus = 'Completed';
    } else {
      _overallStatus = 'In Progress';
    }
  }

  Future<void> _saveReport() async {
    setState(() => _isSaving = true);

    try {
      final reportData = {
        'id': widget.sessionId,
        'sessionId': widget.sessionId,
        'clientId': widget.clientId,
        'carId': widget.carId,
        'garageId': widget.garageId,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'clientNotes': _clientNotesController.text,
        'clientImages': _clientImages,
        'clientRequests':
            _clientRequestsControllers.map((c) => c.text).toList(),
        'inspectionNotes': _inspectionNotesController.text,
        'inspectionImages': _inspectionImages,
        'inspectionFindings':
            _inspectionFindingsControllers.map((c) => c.text).toList(),
        'testDriveNotes': _testDriveNotesController.text,
        'testDriveImages': _testDriveImages,
        'testDriveObservations':
            _testDriveObservationsControllers.map((c) => c.text).toList(),
      };

      // Save the consolidated report to the 'reports' collection
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.sessionId)
          .set(reportData, SetOptions(merge: true));

      // Create a session activity to log that the report was generated/updated
      await FirebaseFirestore.instance.collection('session_activities').add({
        'sessionId': widget.sessionId,
        'stage': 'report',
        'notes': 'Report was generated or updated.',
        'createdAt': FieldValue.serverTimestamp(),
        'clientId': widget.clientId,
        'carId': widget.carId,
        'garageId': widget.garageId,
      });

      Get.snackbar('Success', 'Report saved successfully!');
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save report: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _shareReport() async {
    final clientPhone = widget.sessionData?['client']?['phone'] as String?;

    if (clientPhone == null || clientPhone.isEmpty) {
      Get.snackbar('Error', 'Client phone number is not available.');
      // Fallback to general share if phone number is missing
      final reportLink = 'https://4wk.ae/report/${widget.sessionId}';
      await SharePlus.instance.share(ShareParams(text: 'Hello, please review the vehicle report: $reportLink'));
      return;
    }

    final reportLink = 'https://4wk.ae/report/${widget.sessionId}';
    final message = Uri.encodeComponent(
      'Hello, please review the vehicle report: $reportLink',
    );

    // Format phone number to E.164 format if it's not already
    final formattedPhone =
        clientPhone.startsWith('+')
            ? clientPhone
            : '+$clientPhone'; // Basic assumption, might need more robust formatting

    final whatsappUri = Uri.parse(
      'https://wa.me/$formattedPhone?text=$message',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Could not open WhatsApp.');
        // Fallback to general share
        await SharePlus.instance.share(ShareParams(text: 'Hello, please review the vehicle report: $reportLink'));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('📋 G Report'),
          elevation: 0,
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
              SizedBox(height: 16),
              Text('Loading report data...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_outlined, size: 28),
            SizedBox(width: 8),
            Text('Professional Report', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _shareReport,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Report',
          ),
          IconButton(
            onPressed: () => _exportReport(),
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Export Report',
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveReport,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportHeader(),
            const SizedBox(height: 16),
            _buildStatsOverview(),
            const SizedBox(height: 16),
            if (widget.sessionData != null) _buildSessionContext(),
            const SizedBox(height: 16),
            _buildTimelineSection(),
            const SizedBox(height: 16),
            _buildReportContent(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '4WK AUTOMOTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Professional Vehicle Inspection Report',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_overallStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _overallStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.assignment_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Report ID: ${widget.sessionId.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.schedule_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Generated: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: '${_reportStats['duration'] ?? 0} min',
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.image_outlined,
                    label: 'Images',
                    value: '${_reportStats['totalImages'] ?? 0}',
                    color: const Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.bug_report_outlined,
                    label: 'Findings',
                    value: '${_reportStats['totalFindings'] ?? 0}',
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.checklist_outlined,
                    label: 'Stages',
                    value: '${_reportStats['completedStages'] ?? 0}/3',
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    if (_timeline.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline_outlined, color: Color(0xFF1E3A8A), size: 24),
                SizedBox(width: 12),
                Text(
                  'Inspection Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeline.length,
              itemBuilder: (context, index) {
                final item = _timeline[index];
                return _buildTimelineItem(item, index == _timeline.length - 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isLast) {
    final stage = item['stage'] as String;
    final time = item['time'] as DateTime;
    final notes = item['notes'] as String;
    final hasImages = item['hasImages'] as bool;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStageColor(stage),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStageTitle(stage),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (hasImages) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Images attached',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionContext() {
    final session = widget.sessionData!;
    final client = session['client'] ?? {};
    final car = session['car'] ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 24),
                SizedBox(width: 12),
                Text(
                  'Session Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_outline, 'Client', client['name'] ?? 'Unknown'),
            _buildInfoRow(Icons.phone_outlined, 'Phone', client['phone'] ?? 'N/A'),
            _buildInfoRow(
              Icons.directions_car_outlined,
              'Vehicle',
              '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim(),
            ),
            _buildInfoRow(Icons.confirmation_number_outlined, 'Plate', car['plateNumber'] ?? 'N/A'),
            _buildInfoRow(Icons.palette_outlined, 'Color', car['color'] ?? 'N/A'),
            _buildInfoRow(Icons.calendar_today_outlined, 'Year', car['year']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          icon: Icons.person_pin_outlined,
          title: 'Client Notes',
          notesController: _clientNotesController,
          images: _clientImages,
          detailControllers: _clientRequestsControllers,
          detailTitle: 'Client Requests',
          onAddDetail:
              () => setState(
                () => _clientRequestsControllers.add(TextEditingController()),
              ),
        ),
        _buildSection(
          icon: Icons.search_outlined,
          title: 'Inspection',
          notesController: _inspectionNotesController,
          images: _inspectionImages,
          detailControllers: _inspectionFindingsControllers,
          detailTitle: 'Findings',
          onAddDetail:
              () => setState(
                () =>
                    _inspectionFindingsControllers.add(TextEditingController()),
              ),
        ),
        _buildSection(
          icon: Icons.directions_car_outlined,
          title: 'Test Drive',
          notesController: _testDriveNotesController,
          images: _testDriveImages,
          detailControllers: _testDriveObservationsControllers,
          detailTitle: 'Observations',
          onAddDetail:
              () => setState(
                () => _testDriveObservationsControllers.add(
                  TextEditingController(),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required TextEditingController notesController,
    required List<String> images,
    required List<TextEditingController> detailControllers,
    required String detailTitle,
    required VoidCallback onAddDetail,
  }) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${detailControllers.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add detailed notes here...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: null,
                minLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  detailTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAddDetail,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (detailControllers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No items added yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detailControllers.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: detailControllers[index],
                            decoration: const InputDecoration(
                              hintText: 'Enter detail...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => detailControllers.removeAt(index),
                          ),
                          tooltip: 'Remove item',
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF374151),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Images (${images.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showImageDialog(images[index]),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 100, color: Colors.white);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    Get.snackbar(
      'Export',
      'Export functionality will be implemented soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1E3A8A),
      colorText: Colors.white,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF059669);
      case 'Issues Found':
        return const Color(0xFFEF4444);
      case 'In Progress':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'clientNotes':
        return const Color(0xFF3B82F6);
      case 'inspection':
        return const Color(0xFFEF4444);
      case 'testDrive':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStageTitle(String stage) {
    switch (stage) {
      case 'clientNotes':
        return 'Client Notes';
      case 'inspection':
        return 'Inspection';
      case 'testDrive':
        return 'Test Drive';
      default:
        return stage;
    }
  }
}
