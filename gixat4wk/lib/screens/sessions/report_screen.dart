import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingReport();
  }

  Future<void> _loadExistingReport() async {
    if (widget.reportId != null) {
      setState(() => _isLoading = true);

      try {
        // Implementation pending: Load existing report data
        // final report = await reportService.getReport(widget.reportId!);
        // _populateFormWithReport(report);
      } catch (e) {
        Get.snackbar('Error', 'Failed to load report data');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveReport() async {
    setState(() => _isSaving = true);

    try {
      // Implementation pending: Report saving logic
      await Future.delayed(const Duration(seconds: 1)); // Placeholder

      Get.snackbar('Success', 'Report saved successfully');
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save report: $e');
    } finally {
      setState(() => _isSaving = false);
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
            // Session context (optional)
            if (widget.sessionData != null) _buildSessionContext(),

            // Report content placeholder
            _buildReportContent(),

            const SizedBox(height: 100), // Extra space for FAB
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Report Screen Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This dedicated report screen will include specialized fields and functionality for generating comprehensive vehicle reports.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Planned Features:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...const [
                    '• Vehicle condition assessment',
                    '• Inspection findings summary',
                    '• Test drive results',
                    '• Maintenance recommendations',
                    '• Cost estimates',
                    '• Photo documentation',
                    '• Client communication',
                  ].map(
                    (feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          feature,
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
