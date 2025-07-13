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
import '../../widgets/video_player_widget.dart';

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
  List<String> _images = []; // Uploaded image URLs
  List<String> _videos = []; // Uploaded video URLs
  List<File> _pendingImages = []; // Local images waiting to be uploaded
  List<File> _pendingVideos = []; // Local videos waiting to be uploaded
  List<String> _videosToDelete = []; // Track videos to delete from S3
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
    // Clean up pending compressed images
    _cleanupPendingImages();
    super.dispose();
  }

  void _cleanupPendingImages() {
    for (File image in _pendingImages) {
      try {
        if (image.existsSync() && image.path.contains('_compressed')) {
          image.deleteSync();
        }
      } catch (e) {
        debugPrint('Failed to cleanup compressed image: $e');
      }
    }

    for (File video in _pendingVideos) {
      try {
        if (video.existsSync()) {
          video.deleteSync();
        }
      } catch (e) {
        debugPrint('Failed to cleanup video: $e');
      }
    }
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
      _videos = List.from(activity.videos);
      _pendingImages
          .clear(); // Clear any pending images when loading existing activity
      _pendingVideos
          .clear(); // Clear any pending videos when loading existing activity
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
    debugPrint('🔄 Save activity started for stage: ${widget.stage}');

    setState(() => _isSaving = true);

    try {
      debugPrint(
        '📤 Uploading ${_pendingImages.length} pending images and ${_pendingVideos.length} pending videos...',
      );

      // Upload pending images first
      if (_pendingImages.isNotEmpty) {
        final String storagePath = _getStoragePath();
        final List<String> uploadedUrls = await _imageService.uploadImagesToS3(
          imageFiles: _pendingImages,
          storagePath: storagePath,
          uniqueIdentifier: widget.sessionId,
          compress: false, // Already compressed
        );

        if (uploadedUrls.isNotEmpty) {
          _images.addAll(uploadedUrls);
          _pendingImages
              .clear(); // Clear pending images after successful upload
          debugPrint('✅ Images uploaded successfully: ${uploadedUrls.length}');
        }
      }

      // Upload pending videos
      if (_pendingVideos.isNotEmpty) {
        final String storagePath = _getStoragePath();
        final List<String> uploadedVideoUrls = await _imageService
            .uploadVideosToS3(
              videoFiles: _pendingVideos,
              storagePath: storagePath,
              uniqueIdentifier: widget.sessionId,
            );

        if (uploadedVideoUrls.isNotEmpty) {
          _videos.addAll(uploadedVideoUrls);
          _pendingVideos
              .clear(); // Clear pending videos after successful upload
          debugPrint(
            '✅ Videos uploaded successfully: ${uploadedVideoUrls.length}',
          );
        }
      }

      // Delete removed videos from S3
      if (_videosToDelete.isNotEmpty) {
        debugPrint('🗑️ Deleting ${_videosToDelete.length} videos from S3...');
        for (String videoUrl in _videosToDelete) {
          try {
            await _imageService.deleteVideoFromS3(videoUrl);
            debugPrint('✅ Deleted video: $videoUrl');
          } catch (e) {
            debugPrint('❌ Failed to delete video: $videoUrl, error: $e');
          }
        }
        _videosToDelete.clear();
      }

      bool success = false;
      if (_currentActivity != null) {
        debugPrint('🔄 Updating existing activity: ${_currentActivity!.id}');
        // Update existing activity
        final updatedActivity = _createActivityFromForm(_currentActivity!.id);
        success = await _unifiedService.updateActivity(
          _currentActivity!.id,
          updatedActivity,
        );
        if (success) {
          debugPrint('✅ Activity updated successfully');
          Get.snackbar('Success', '$_stageTitle updated successfully');
        } else {
          debugPrint('❌ Failed to update activity');
          Get.snackbar('Error', 'Failed to update $_stageTitle');
        }
      } else {
        debugPrint('🔄 Creating new activity...');
        // Create new activity
        final activity = _createActivityFromForm('');
        final activityId = await _unifiedService.createActivity(activity);
        success = activityId != null;
        if (success) {
          debugPrint('✅ Activity created successfully with ID: $activityId');
          Get.snackbar('Success', '$_stageTitle saved successfully');
        } else {
          debugPrint('❌ Failed to create activity');
          Get.snackbar('Error', 'Failed to save $_stageTitle');
        }
      }

      debugPrint('🔄 Save operation completed. Success: $success');

      // Navigate back to session details after a short delay
      debugPrint('⏳ Waiting before navigation...');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        debugPrint('🚀 Navigating back with result: $success');
        debugPrint(
          '📍 Current route: ${ModalRoute.of(context)?.settings.name}',
        );
        debugPrint('📍 Can pop: ${Navigator.of(context).canPop()}');

        // Try multiple navigation methods
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(success);
            debugPrint('✅ Navigator.pop() executed');
          } else {
            debugPrint('⚠️ Cannot pop, trying Get.back()');
            Get.back(result: success);
          }
        } catch (e) {
          debugPrint('⚠️ Navigation failed: $e');
          // Force back navigation
          Get.until((route) => route.isFirst);
        }
      } else {
        debugPrint('⚠️ Widget not mounted, skipping navigation');
      }
    } catch (e) {
      debugPrint('💥 Error during save: $e');
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      debugPrint('🏁 Save process finished, setting _isSaving to false');
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
          videos: _videos,
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
          videos: _videos,
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
          videos: _videos,
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
          videos: _videos,
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
            Text('Media', style: Theme.of(context).textTheme.titleLarge),
            Row(
              children: [
                IconButton(
                  onPressed: _addImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  tooltip: 'Add Images',
                ),
                IconButton(
                  onPressed: _addVideo,
                  icon: const Icon(Icons.videocam),
                  tooltip: 'Add Videos',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Images section
        if (_images.isNotEmpty || _pendingImages.isNotEmpty) ...[
          Text(
            'Images (${_images.length + _pendingImages.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ImageGridWidget(
            uploadedImageUrls: _images,
            selectedImages: _pendingImages,
            isEditing: true,
            onRemoveUploadedImage: (index) async {
              await _removeImage(index);
            },
            onRemoveSelectedImage: (index) {
              setState(() {
                _pendingImages.removeAt(index);
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Videos section
        if (_videos.isNotEmpty || _pendingVideos.isNotEmpty) ...[
          Text(
            'Videos (${_videos.length + _pendingVideos.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildVideosList(),
        ],

        // Empty state
        if (_images.isEmpty &&
            _pendingImages.isEmpty &&
            _videos.isEmpty &&
            _pendingVideos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No media added yet. Tap + to add images or videos.'),
            ),
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

  // Image and Video methods
  void _addImage() {
    _imageService.showImageSourceOptions(
      context,
      onImageSelected: (File? image) async {
        if (image != null) {
          await _compressAndAddImage(image);
        }
      },
      onMultipleImagesSelected: (List<File> images) async {
        await _compressAndAddMultipleImages(images);
      },
      allowMultiple: true,
    );
  }

  void _addVideo() {
    _imageService.showVideoSourceOptions(
      context,
      onVideoSelected: (File? video) async {
        if (video != null) {
          await _addVideoFile(video);
        }
      },
      onMultipleVideosSelected: (List<File> videos) async {
        await _addMultipleVideoFiles(videos);
      },
      allowMultiple: false, // Single video for now
    );
  }

  Future<void> _addVideoFile(File video) async {
    setState(() {
      _pendingVideos.add(video);
    });
  }

  Future<void> _addMultipleVideoFiles(List<File> videos) async {
    setState(() {
      _pendingVideos.addAll(videos);
    });
  }

  Widget _buildVideosList() {
    // Convert existing video URLs to display items
    List<Widget> videoWidgets = [];

    // Add existing videos (URLs)
    for (String videoUrl in _videos) {
      videoWidgets.add(
        Stack(
          children: [
            GestureDetector(
              onTap: () => _openVideoPlayer(videoUrl: videoUrl),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => _removeExistingVideo(videoUrl),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Add pending videos (Files)
    for (File video in _pendingVideos) {
      videoWidgets.add(
        Stack(
          children: [
            GestureDetector(
              onTap: () => _openVideoPlayer(videoFile: video),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  size: 40,
                  color: Colors.orange,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => _removePendingVideo(video),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (videoWidgets.isEmpty) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: videoWidgets),
      ],
    );
  }

  void _removeExistingVideo(String videoUrl) {
    setState(() {
      _videos.remove(videoUrl);
      _videosToDelete.add(videoUrl); // Store URL for deletion from S3
    });
  }

  void _removePendingVideo(File video) {
    setState(() {
      _pendingVideos.remove(video);
    });
  }

  Future<void> _compressAndAddImage(File image) async {
    setState(() => _isSaving = true);

    try {
      // Only compress the image, don't upload yet
      final compressedImage = await _imageService.compressImage(image);

      if (compressedImage != null) {
        setState(() {
          _pendingImages.add(compressedImage);
        });
        Get.snackbar('Success', 'Image prepared for upload');
      } else {
        setState(() {
          _pendingImages.add(image); // Use original if compression failed
        });
        Get.snackbar('Info', 'Image added (compression skipped)');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to process image: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _compressAndAddMultipleImages(List<File> images) async {
    if (images.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      int successCount = 0;
      for (File image in images) {
        try {
          // Only compress the image, don't upload yet
          final compressedImage = await _imageService.compressImage(image);

          setState(() {
            _pendingImages.add(compressedImage ?? image);
          });
          successCount++;
        } catch (e) {
          // Continue with other images even if one fails
          debugPrint('Failed to process image: $e');
        }
      }

      if (successCount > 0) {
        Get.snackbar('Success', '$successCount images prepared for upload');
      } else {
        Get.snackbar('Error', 'Failed to process images');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to process images: $e');
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
        content: const Text(
          'Are you sure you want to delete this image? This action cannot be undone.',
        ),
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
        Get.snackbar(
          'Warning',
          'Image removed from list but may still exist in storage',
        );
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

  void _openVideoPlayer({String? videoUrl, File? videoFile}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VideoPlayerWidget(
              videoUrl: videoUrl,
              videoFile: videoFile,
              title: videoUrl != null ? 'Video' : 'Preview Video',
            ),
      ),
    );
  }
}
