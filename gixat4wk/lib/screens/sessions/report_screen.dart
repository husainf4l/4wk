import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
              .get();

      for (var doc in snapshot.docs) {
        final activity = doc.data();
        final stage = activity['stage'] as String?;

        // Helper to safely convert List<dynamic> to List<String>
        List<String> _dynamicListToStringList(List<dynamic>? dynamicList) {
          if (dynamicList == null) return [];
          return dynamicList.map((e) => e.toString()).toList();
        }

        switch (stage) {
          case 'clientNotes':
            _clientNotesController.text = activity['notes'] ?? '';
            _clientImages = _dynamicListToStringList(
              activity['images'] as List?,
            );
            _clientRequestsControllers =
                _dynamicListToStringList(
                  activity['requests'] as List?,
                ).map((text) => TextEditingController(text: text)).toList();
            break;
          case 'inspection':
            _inspectionNotesController.text = activity['notes'] ?? '';
            _inspectionImages = _dynamicListToStringList(
              activity['images'] as List?,
            );
            _inspectionFindingsControllers =
                _dynamicListToStringList(
                  activity['findings'] as List?,
                ).map((text) => TextEditingController(text: text)).toList();
            break;
          case 'testDrive':
            _testDriveNotesController.text = activity['notes'] ?? '';
            _testDriveImages = _dynamicListToStringList(
              activity['images'] as List?,
            );
            _testDriveObservationsControllers =
                _dynamicListToStringList(
                  activity['observations'] as List?,
                ).map((text) => TextEditingController(text: text)).toList();
            break;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load session data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      Share.share('Hello, please review the vehicle report: $reportLink');
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
        Share.share('Hello, please review the vehicle report: $reportLink');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('📋 G Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text('📋'), SizedBox(width: 8), Text('G Report')],
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _shareReport,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Report',
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveReport,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sessionData != null) _buildSessionContext(),
            _buildReportContent(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionContext() {
    final session = widget.sessionData!;
    final client = session['client'] ?? {};
    final car = session['car'] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Context',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Client: ${client['name'] ?? 'Unknown'}'),
            Text(
              'Vehicle: ${car['make'] ?? ''} ${car['model'] ?? ''} (${car['plateNumber'] ?? ''})',
            ),
            Text('Status: ${session['status'] ?? 'Unknown'}'),
          ],
        ),
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
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Edit notes here...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF8F8F8),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  detailTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddDetail,
                  tooltip: 'Add New Item',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (detailControllers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text('No items yet.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detailControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: detailControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Enter detail...',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed:
                              () => setState(
                                () => detailControllers.removeAt(index),
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Images', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 40);
                      },
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
}
