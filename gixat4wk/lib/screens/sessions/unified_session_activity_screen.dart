import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../models/unified_session_activity.dart';
import '../../services/session/unified_session_service.dart';
import '../../services/image_handling_service.dart';
import '../../config/aws_config.dart';
import '../../widgets/notes_editor_widget.dart';
import '../../widgets/image_grid_widget.dart';
import '../../widgets/request_list_widget.dart';

class UnifiedSessionActivityScreen extends StatefulWidget {
  final String sessionId;
  final String clientId;
  final String carId;
  final String garageId;
  final ActivityStage stage;
  final String? activityId; // For editing existing activity
  final Map<String, dynamic>? sessionData; // For displaying session context

  const UnifiedSessionActivityScreen({
    super.key,
    required this.sessionId,
    required this.clientId,
    required this.carId,
    required this.garageId,
    required this.stage,
    this.activityId,
    this.sessionData,
  });

  @override
  State<UnifiedSessionActivityScreen> createState() =>
      _UnifiedSessionActivityScreenState();
}

class _UnifiedSessionActivityScreenState
    extends State<UnifiedSessionActivityScreen> {
  final UnifiedSessionService _unifiedService = Get.put(
    UnifiedSessionService(),
  );
  final ImageHandlingService _imageService = ImageHandlingService();

  bool _isLoading = false;
  bool _isSaving = false;

  // Form controllers
  final TextEditingController _notesController = TextEditingController();

  // Common data
  List<String> _images = [];
  List<Map<String, dynamic>> _requests = [];

  // Stage-specific data
  List<Map<String, dynamic>> _findings = []; // For inspection
  List<Map<String, dynamic>> _observations = []; // For test drive
  Map<String, dynamic> _reportData = {}; // For report

  // Current activity (if editing)
  UnifiedSessionActivity? _currentActivity;

  @override
  void initState() {
    super.initState();
    _loadExistingActivity();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingActivity() async {
    if (widget.activityId != null) {
      setState(() => _isLoading = true);

      try {
        final activity = await _unifiedService.getActivity(widget.activityId!);
        if (activity != null) {
          _populateFormWithActivity(activity);
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to load activity data');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Load existing activity for this session and stage
      final activities = await _unifiedService.getActivitiesForSession(
        sessionId: widget.sessionId,
        stage: widget.stage,
      );

      if (activities.isNotEmpty) {
        _populateFormWithActivity(activities.first);
      }
    }
  }

  void _populateFormWithActivity(UnifiedSessionActivity activity) {
    setState(() {
      _currentActivity = activity;
      _notesController.text = activity.notes;
      _images = List.from(activity.images);
      _requests = List.from(activity.requests);

      // Populate stage-specific data
      if (activity.findings != null) {
        _findings = List.from(activity.findings!);
      }
      if (activity.observations != null) {
        _observations = List.from(activity.observations!);
      }
      if (activity.reportData != null) {
        _reportData = Map.from(activity.reportData!);
      }
    });
  }

  String get _stageTitle {
    switch (widget.stage) {
      case ActivityStage.clientNotes:
        return 'Client Notes';
      case ActivityStage.inspection:
        return 'Vehicle Inspection';
      case ActivityStage.testDrive:
        return 'Test Drive';
      case ActivityStage.report:
        return 'Report';
    }
  }

  String get _stageIcon {
    switch (widget.stage) {
      case ActivityStage.clientNotes:
        return '📝';
      case ActivityStage.inspection:
        return '🔍';
      case ActivityStage.testDrive:
        return '🚗';
      case ActivityStage.report:
        return '📋';
    }
  }

  Future<void> _saveActivity() async {
    if (_notesController.text.trim().isEmpty && _requests.isEmpty) {
      Get.snackbar('Validation Error', 'Please add notes or requests');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_currentActivity != null) {
        // Update existing activity
        final updatedActivity = _createActivityFromForm(_currentActivity!.id);
        final success = await _unifiedService.updateActivity(
          _currentActivity!.id,
          updatedActivity,
        );

        if (success) {
          Get.snackbar('Success', '$_stageTitle updated successfully');
          Get.back(result: true);
        } else {
          Get.snackbar('Error', 'Failed to update $_stageTitle');
        }
      } else {
        // Create new activity
        final activity = _createActivityFromForm('');
        final activityId = await _unifiedService.createActivity(activity);

        if (activityId != null) {
          Get.snackbar('Success', '$_stageTitle saved successfully');
          Get.back(result: true);
        } else {
          Get.snackbar('Error', 'Failed to save $_stageTitle');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  UnifiedSessionActivity _createActivityFromForm(String id) {
    switch (widget.stage) {
      case ActivityStage.clientNotes:
        return UnifiedSessionActivity.forClientNotes(
          sessionId: widget.sessionId,
          clientId: widget.clientId,
          carId: widget.carId,
          garageId: widget.garageId,
          notes: _notesController.text.trim(),
          requests: _requests,
          images: _images,
        );

      case ActivityStage.inspection:
        return UnifiedSessionActivity.forInspection(
          sessionId: widget.sessionId,
          clientId: widget.clientId,
          carId: widget.carId,
          garageId: widget.garageId,
          notes: _notesController.text.trim(),
          findings: _findings,
          images: _images,
          requests: _requests,
        );

      case ActivityStage.testDrive:
        return UnifiedSessionActivity.forTestDrive(
          sessionId: widget.sessionId,
          clientId: widget.clientId,
          carId: widget.carId,
          garageId: widget.garageId,
          notes: _notesController.text.trim(),
          observations: _observations,
          images: _images,
          requests: _requests,
        );

      case ActivityStage.report:
        return UnifiedSessionActivity.forReport(
          sessionId: widget.sessionId,
          clientId: widget.clientId,
          carId: widget.carId,
          garageId: widget.garageId,
          notes: _notesController.text.trim(),
          reportData: _reportData,
          images: _images,
          requests: _requests,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_stageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_stageIcon),
            const SizedBox(width: 8),
            Text(_stageTitle),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveActivity,
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

            // Notes section (always visible)
            _buildNotesSection(),

            const SizedBox(height: 24),

            // Stage-specific sections
            ..._buildStageSpecificSections(),

            const SizedBox(height: 24),

            // Images section (always visible)
            _buildImagesSection(),

            const SizedBox(height: 24),

            // Requests section (always visible)
            _buildRequestsSection(),

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

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        NotesEditorWidget(
          notes: _notesController.text,
          isEditing: true,
          onEditPressed: () {
            NotesEditorWidget.showEditDialog(
              context,
              initialValue: _notesController.text,
              onSave: (newNotes) {
                setState(() {
                  _notesController.text = newNotes;
                });
              },
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildStageSpecificSections() {
    switch (widget.stage) {
      case ActivityStage.inspection:
        return [_buildFindingsSection()];
      case ActivityStage.testDrive:
        return [_buildObservationsSection()];
      case ActivityStage.report:
        return [_buildReportDataSection()];
      case ActivityStage.clientNotes:
        return [];
    }
  }

  Widget _buildFindingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inspection Findings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(onPressed: _addFinding, icon: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 8),
        ..._findings.asMap().entries.map((entry) {
          final index = entry.key;
          final finding = entry.value;
          return _buildFindingItem(index, finding);
        }),
        if (_findings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No findings added yet. Tap + to add findings.'),
            ),
          ),
      ],
    );
  }

  Widget _buildFindingItem(int index, Map<String, dynamic> finding) {
    return Card(
      child: ListTile(
        title: Text(finding['title'] ?? 'Finding ${index + 1}'),
        subtitle: Text(finding['description'] ?? ''),
        trailing: IconButton(
          onPressed: () => _removeFinding(index),
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
        onTap: () => _editFinding(index, finding),
      ),
    );
  }

  Widget _buildObservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Test Drive Observations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(onPressed: _addObservation, icon: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 8),
        ..._observations.asMap().entries.map((entry) {
          final index = entry.key;
          final observation = entry.value;
          return _buildObservationItem(index, observation);
        }),
        if (_observations.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No observations added yet. Tap + to add observations.',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildObservationItem(int index, Map<String, dynamic> observation) {
    return Card(
      child: ListTile(
        title: Text(observation['title'] ?? 'Observation ${index + 1}'),
        subtitle: Text(observation['description'] ?? ''),
        trailing: IconButton(
          onPressed: () => _removeObservation(index),
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
        onTap: () => _editObservation(index, observation),
      ),
    );
  }

  Widget _buildReportDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Configuration',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Report Title'),
                  initialValue: _reportData['title']?.toString() ?? '',
                  onChanged: (value) => _reportData['title'] = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Summary'),
                  maxLines: 3,
                  initialValue: _reportData['summary']?.toString() ?? '',
                  onChanged: (value) => _reportData['summary'] = value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Images', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              onPressed: _addImage,
              icon: const Icon(Icons.add_photo_alternate),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ImageGridWidget(
          uploadedImageUrls: _images,
          isEditing: true,
          onRemoveUploadedImage: (index) async {
            await _removeImage(index);
          },
        ),
      ],
    );
  }

  Widget _buildRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Service Requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(onPressed: _addRequest, icon: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 8),
        RequestListWidget(
          requests: _requests,
          isEditing: true,
          onRemoveRequest: (request) {
            setState(() => _requests.remove(request));
          },
          onEditArgancy: (request, newUrgency) {
            setState(() {
              final index = _requests.indexOf(request);
              if (index != -1) {
                _requests[index]['argancy'] = newUrgency;
              }
            });
          },
        ),
      ],
    );
  }

  // Finding methods
  void _addFinding() {
    _showFindingDialog();
  }

  void _editFinding(int index, Map<String, dynamic> finding) {
    _showFindingDialog(index: index, finding: finding);
  }

  void _removeFinding(int index) {
    setState(() => _findings.removeAt(index));
  }

  void _showFindingDialog({int? index, Map<String, dynamic>? finding}) {
    final titleController = TextEditingController(
      text: finding?['title'] ?? '',
    );
    final descController = TextEditingController(
      text: finding?['description'] ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: Text(index != null ? 'Edit Finding' : 'Add Finding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Finding Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newFinding = {
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
                'timestamp': DateTime.now().toIso8601String(),
              };

              setState(() {
                if (index != null) {
                  _findings[index] = newFinding;
                } else {
                  _findings.add(newFinding);
                }
              });

              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Observation methods
  void _addObservation() {
    _showObservationDialog();
  }

  void _editObservation(int index, Map<String, dynamic> observation) {
    _showObservationDialog(index: index, observation: observation);
  }

  void _removeObservation(int index) {
    setState(() => _observations.removeAt(index));
  }

  void _showObservationDialog({int? index, Map<String, dynamic>? observation}) {
    final titleController = TextEditingController(
      text: observation?['title'] ?? '',
    );
    final descController = TextEditingController(
      text: observation?['description'] ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: Text(index != null ? 'Edit Observation' : 'Add Observation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Observation Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newObservation = {
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
                'timestamp': DateTime.now().toIso8601String(),
              };

              setState(() {
                if (index != null) {
                  _observations[index] = newObservation;
                } else {
                  _observations.add(newObservation);
                }
              });

              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Image methods
  void _addImage() {
    _imageService.showImageSourceOptions(
      context,
      onImageSelected: (File? image) async {
        if (image != null) {
          await _uploadSingleImage(image);
        }
      },
      onMultipleImagesSelected: (List<File> images) async {
        await _uploadMultipleImages(images);
      },
      allowMultiple: true,
    );
  }

  Future<void> _uploadSingleImage(File image) async {
    setState(() => _isSaving = true);

    try {
      final String storagePath = _getStoragePath();
      final List<String> uploadedUrls = await _imageService.uploadImagesToS3(
        imageFiles: [image],
        storagePath: storagePath,
        uniqueIdentifier: widget.sessionId,
        compress: true,
      );

      if (uploadedUrls.isNotEmpty) {
        setState(() {
          _images.addAll(uploadedUrls);
        });
        Get.snackbar('Success', 'Image uploaded successfully');
      } else {
        Get.snackbar('Error', 'Failed to upload image');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadMultipleImages(List<File> images) async {
    if (images.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final String storagePath = _getStoragePath();
      final List<String> uploadedUrls = await _imageService.uploadImagesToS3(
        imageFiles: images,
        storagePath: storagePath,
        uniqueIdentifier: widget.sessionId,
        compress: true,
      );

      if (uploadedUrls.isNotEmpty) {
        setState(() {
          _images.addAll(uploadedUrls);
        });
        Get.snackbar('Success', '${uploadedUrls.length} images uploaded successfully');
      } else {
        Get.snackbar('Error', 'Failed to upload images');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload images: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _getStoragePath() {
    switch (widget.stage) {
      case ActivityStage.clientNotes:
        return '${AWSConfig.carImagesFolder}/client-notes';
      case ActivityStage.inspection:
        return AWSConfig.inspectionPhotosFolder;
      case ActivityStage.testDrive:
        return '${AWSConfig.carImagesFolder}/test-drive';
      case ActivityStage.report:
        return '${AWSConfig.carImagesFolder}/reports';
    }
  }

  Future<void> _removeImage(int index) async {
    if (index < 0 || index >= _images.length) return;

    final String imageUrl = _images[index];
    
    // Show confirmation dialog
    final bool? shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isSaving = true);

    try {
      // Remove from S3
      final bool deleted = await _imageService.deleteImageFromS3(imageUrl);
      
      if (deleted) {
        setState(() {
          _images.removeAt(index);
        });
        Get.snackbar('Success', 'Image deleted successfully');
      } else {
        Get.snackbar('Warning', 'Image removed from list but may still exist in storage');
        setState(() {
          _images.removeAt(index);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete image: $e');
      // Still remove from UI even if S3 deletion failed
      setState(() {
        _images.removeAt(index);
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Request methods
  void _addRequest() {
    RequestListWidget.showAddRequestDialog(
      context,
      onAddRequest: (request, urgency) {
        setState(() {
          _requests.add({
            'request': request,
            'argancy': urgency,
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
      },
    );
  }
}
