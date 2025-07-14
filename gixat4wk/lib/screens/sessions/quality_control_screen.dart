import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QualityControlScreen extends StatefulWidget {
  final String sessionId;
  final String clientId;
  final String carId;
  final String garageId;
  final Map<String, dynamic> sessionData;

  const QualityControlScreen({
    super.key,
    required this.sessionId,
    required this.clientId,
    required this.carId,
    required this.garageId,
    required this.sessionData,
  });

  @override
  State<QualityControlScreen> createState() => _QualityControlScreenState();
}

class _QualityControlScreenState extends State<QualityControlScreen> {
  final TextEditingController _qcNotesController = TextEditingController();
  final TextEditingController _qualityScoreController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  // QC Checklist items
  final Map<String, bool> _qcChecklist = {
    'Work Quality': false,
    'Cleanliness': false,
    'Client Satisfaction': false,
    'Documentation Complete': false,
    'No Damage Added': false,
    'All Issues Addressed': false,
    'Photos Verified': false,
    'Final Inspection': false,
  };

  String _overallRating = 'Excellent';
  final List<String> _ratingOptions = ['Excellent', 'Good', 'Fair', 'Poor'];

  Map<String, dynamic>? _existingQcData;

  @override
  void initState() {
    super.initState();
    _loadExistingQcData();
  }

  @override
  void dispose() {
    _qcNotesController.dispose();
    _qualityScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingQcData() async {
    setState(() => _isLoading = true);

    try {
      final qcDoc =
          await FirebaseFirestore.instance
              .collection('qc_reports')
              .where('sessionId', isEqualTo: widget.sessionId)
              .limit(1)
              .get();

      if (qcDoc.docs.isNotEmpty) {
        _existingQcData = qcDoc.docs.first.data();
        _populateFormWithExistingData();
      }
    } catch (e) {
      debugPrint('Error loading QC data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFormWithExistingData() {
    if (_existingQcData != null) {
      _qcNotesController.text = _existingQcData!['notes'] ?? '';
      _qualityScoreController.text =
          (_existingQcData!['qualityScore'] ?? '').toString();
      _overallRating = _existingQcData!['overallRating'] ?? 'Excellent';

      final checklist =
          _existingQcData!['checklist'] as Map<String, dynamic>? ?? {};
      checklist.forEach((key, value) {
        if (_qcChecklist.containsKey(key)) {
          _qcChecklist[key] = value ?? false;
        }
      });

      setState(() {});
    }
  }

  Future<void> _saveQcReport() async {
    setState(() => _isSaving = true);

    try {
      final qcData = {
        'sessionId': widget.sessionId,
        'clientId': widget.clientId,
        'carId': widget.carId,
        'garageId': widget.garageId,
        'notes': _qcNotesController.text.trim(),
        'qualityScore': int.tryParse(_qualityScoreController.text) ?? 0,
        'overallRating': _overallRating,
        'checklist': _qcChecklist,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_existingQcData != null) {
        // Update existing QC report
        final qcDoc =
            await FirebaseFirestore.instance
                .collection('qc_reports')
                .where('sessionId', isEqualTo: widget.sessionId)
                .limit(1)
                .get();

        if (qcDoc.docs.isNotEmpty) {
          await qcDoc.docs.first.reference.update(qcData);
        }
      } else {
        // Create new QC report
        qcData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('qc_reports').add(qcData);
      }

      Get.snackbar(
        'Success',
        'QC Report saved successfully',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.TOP,
      );

      // Navigate back with success result
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save QC Report: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFFE82127);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quality Control'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quality Control'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveQcReport,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.save, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
            // Session Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Session Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Car: ${widget.sessionData['car']['make']} ${widget.sessionData['car']['model']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Client: ${widget.sessionData['client']['name']}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Plate: ${widget.sessionData['car']['plateNumber'] ?? 'N/A'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // QC Checklist Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Quality Checklist',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._qcChecklist.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(entry.key),
                        value: entry.value,
                        onChanged: (bool? value) {
                          setState(() {
                            _qcChecklist[entry.key] = value ?? false;
                          });
                        },
                        activeColor: accentColor,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Overall Rating Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star_rate, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Overall Rating',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _overallRating,
                      decoration: InputDecoration(
                        labelText: 'Service Quality Rating',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items:
                          _ratingOptions.map((String rating) {
                            return DropdownMenuItem<String>(
                              value: rating,
                              child: Text(rating),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _overallRating = newValue ?? 'Excellent';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _qualityScoreController,
                      decoration: InputDecoration(
                        labelText: 'Quality Score (1-100)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // QC Notes Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note_alt, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'QC Notes & Observations',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _qcNotesController,
                      decoration: InputDecoration(
                        labelText: 'Quality Control Notes',
                        hintText:
                            'Enter any observations, recommendations, or quality concerns...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      maxLines: 5,
                      minLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
