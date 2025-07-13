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
  bool _isAddingImage = false; // Prevent rapid image additions
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Track individual image upload progress
  Map<String, double> _imageUploadProgress =
      {}; // File path -> progress (0.0 to 1.0)
  Map<String, bool> _imageUploadCompleted = {}; // File path -> completed status

  // Form controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();

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
  String _mileage = ''; // For client notes

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
    _mileageController.dispose();
    // Clean up pending compressed images
    _cleanupPendingImages();
    // Clear progress tracking
    _imageUploadProgress.clear();
    _imageUploadCompleted.clear();
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
        // Load mileage for client notes
        if (activity.stage == ActivityStage.clientNotes &&
            activity.reportData!.containsKey('mileage')) {
          _mileage = activity.reportData!['mileage'] ?? '';
          _mileageController.text = _mileage;
        }
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

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing to save...';
    });

    try {
      // Step 1: Upload any remaining pending images (if any)
      if (_pendingImages.isNotEmpty) {
        setState(() {
          _uploadStatus =
              'Uploading remaining ${_pendingImages.length} images...';
          _uploadProgress = 0.1;
        });

        final String storagePath = _getStoragePath();

        try {
          // Only upload images that haven't been uploaded yet
          final List<File> remainingImages =
              _pendingImages.where((image) {
                return !(_imageUploadCompleted[image.path] ?? false);
              }).toList();

          if (remainingImages.isNotEmpty) {
            debugPrint(
              '📤 Uploading ${remainingImages.length} remaining images...',
            );

            // Start progress animation for remaining images
            for (File image in remainingImages) {
              _animateImageProgress(image.path);
            }

            // Use PARALLEL batch upload for maximum speed
            final List<String> uploadedUrls = await _imageService
                .uploadImagesToS3(
                  imageFiles: remainingImages,
                  storagePath: storagePath,
                  uniqueIdentifier: widget.sessionId,
                  compress: false, // Already compressed
                  maxConcurrency: 6, // High concurrency for maximum speed
                );

            if (uploadedUrls.isNotEmpty) {
              _images.addAll(uploadedUrls);
              debugPrint('✅ Remaining images uploaded: ${uploadedUrls.length}');
            }
          } else {
            debugPrint('ℹ️ All images already uploaded in background');
          }

          // Clear all pending images since they're all handled
          _pendingImages.clear();

          setState(() {
            _uploadProgress = 0.4;
            _uploadStatus = 'All images ready!';
          });

          // Clear progress tracking
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              _imageUploadProgress.clear();
              _imageUploadCompleted.clear();
            });
          });
        } catch (e) {
          debugPrint('Failed to upload remaining images: $e');
          setState(() {
            _uploadStatus = 'Some images failed to upload';
          });
        }

        // Show feedback briefly
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Step 2: Upload pending videos (if any)
      if (_pendingVideos.isNotEmpty) {
        setState(() {
          _uploadStatus = 'Uploading ${_pendingVideos.length} videos...';
          _uploadProgress = 0.5;
        });

        final String storagePath = _getStoragePath();

        try {
          // Use parallel batch upload for videos
          final List<String> uploadedVideoUrls = await _imageService
              .uploadVideosToS3(
                videoFiles: _pendingVideos,
                storagePath: storagePath,
                uniqueIdentifier: widget.sessionId,
                maxConcurrency: 4, // Increased concurrency for faster uploads
              );

          if (uploadedVideoUrls.isNotEmpty) {
            _videos.addAll(uploadedVideoUrls);
            _pendingVideos.clear();
            debugPrint(
              '✅ Batch videos uploaded successfully: ${uploadedVideoUrls.length}',
            );
            setState(() {
              _uploadProgress = 0.7;
              _uploadStatus = '${uploadedVideoUrls.length} videos uploaded!';
            });
          }
        } catch (e) {
          debugPrint('Failed to upload video batch: $e');
          setState(() {
            _uploadStatus = 'Some videos failed to upload';
          });
        }

        // Show success feedback briefly
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Step 3: Delete removed videos from S3
      if (_videosToDelete.isNotEmpty) {
        setState(() {
          _uploadStatus = 'Cleaning up removed videos...';
          _uploadProgress = 0.8;
        });

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

      // Step 4: Save activity data
      setState(() {
        _uploadStatus = 'Saving activity data...';
        _uploadProgress = 0.9;
      });

      bool success = false;
      if (_currentActivity != null) {
        debugPrint('🔄 Updating existing activity: ${_currentActivity!.id}');
        final updatedActivity = _createActivityFromForm(_currentActivity!.id);
        success = await _unifiedService.updateActivity(
          _currentActivity!.id,
          updatedActivity,
        );
        if (success) {
          debugPrint('✅ Activity updated successfully');
        } else {
          debugPrint('❌ Failed to update activity');
        }
      } else {
        debugPrint('🔄 Creating new activity...');
        final activity = _createActivityFromForm('');
        final activityId = await _unifiedService.createActivity(activity);
        success = activityId != null;
        if (success) {
          debugPrint('✅ Activity created successfully with ID: $activityId');
        } else {
          debugPrint('❌ Failed to create activity');
        }
      }

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = success ? 'Saved successfully!' : 'Save failed!';
      });

      if (success) {
        Get.snackbar('Success', '$_stageTitle saved successfully');
      } else {
        Get.snackbar('Error', 'Failed to save $_stageTitle');
      }

      debugPrint('🔄 Save operation completed. Success: $success');

      // Navigate back after a short delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        debugPrint('🚀 Navigating back with result: $success');
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
          Get.until((route) => route.isFirst);
        }
      }
    } catch (e) {
      debugPrint('💥 Error during save: $e');
      setState(() {
        _uploadStatus = 'Error occurred!';
      });
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      debugPrint('🏁 Save process finished');
      setState(() {
        _isSaving = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
    }
  }

  UnifiedSessionActivity _createActivityFromForm(String id) {
    switch (widget.stage) {
      case ActivityStage.clientNotes:
        return UnifiedSessionActivity(
          id: id,
          sessionId: widget.sessionId,
          clientId: widget.clientId,
          carId: widget.carId,
          garageId: widget.garageId,
          stage: ActivityStage.clientNotes,
          notes: _notesController.text.trim(),
          requests: _requests,
          images: _images,
          videos: _videos,
          reportData: {'mileage': _mileage}, // Store mileage in reportData
        );

      case ActivityStage.inspection:
        return UnifiedSessionActivity.forInspection(
          sessionId: widget.sessionId,
          clientId: widget.clientId,
          carId: widget.carId,
          garageId: widget.garageId,
          notes: _notesController.text.trim(),
          findings: [], // Removed findings - notes and requests are enough
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
          observations:
              [], // Removed observations - notes and requests are enough
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
          if (_isSaving && _uploadStatus.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    _uploadStatus,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: _isSaving ? null : _saveActivity,
            child:
                _isSaving
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                            color: Colors.white,
                          ),
                        ),
                        if (_uploadProgress > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    )
                    : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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

                // Service Requests section (moved before images)
                _buildRequestsSection(),

                const SizedBox(height: 24),

                // Images section (moved to end)
                _buildImagesSection(),

                const SizedBox(height: 100), // Extra space for FAB
              ],
            ),
          ),
        ],
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
      case ActivityStage.clientNotes:
        return [_buildMileageSection()];
      case ActivityStage.inspection:
        return []; // Notes and service requests are enough
      case ActivityStage.testDrive:
        return []; // Notes and service requests are enough
      case ActivityStage.report:
        return [_buildReportDataSection()];
    }
  }

  Widget _buildMileageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vehicle Mileage', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _mileageController,
                  decoration: const InputDecoration(
                    labelText: 'Current Mileage',
                    hintText: 'Enter vehicle mileage (e.g., 50,000)',
                    suffixText: 'km',
                    prefixIcon: Icon(Icons.speed),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _mileage = value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
            uploadProgress: _imageUploadProgress,
            uploadCompleted: _imageUploadCompleted,
            onRemoveUploadedImage: (index) async {
              await _removeImage(index);
            },
            onRemoveSelectedImage: (index) {
              setState(() {
                final File imageToRemove = _pendingImages[index];
                _pendingImages.removeAt(index);
                // Clean up progress tracking
                _imageUploadProgress.remove(imageToRemove.path);
                _imageUploadCompleted.remove(imageToRemove.path);
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
    // Prevent rapid successive calls
    if (_isAddingImage) {
      debugPrint('Image addition already in progress, ignoring request');
      return;
    }

    setState(() => _isAddingImage = true);

    _imageService.showImageSourceOptions(
      context,
      onImageSelected: (File? image) async {
        if (image != null) {
          await _compressAndAddImage(image);
        }
        setState(() => _isAddingImage = false);
      },
      onMultipleImagesSelected: (List<File> images) async {
        await _compressAndAddMultipleImages(images);
        setState(() => _isAddingImage = false);
      },
      allowMultiple: true,
    );

    // Reset flag after a short delay in case dialog was cancelled
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isAddingImage = false);
      }
    });
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
    // Add image immediately to UI with compression status
    setState(() {
      _pendingImages.add(image);
      // Initialize progress tracking for the new image (starting with compression)
      _imageUploadProgress[image.path] = 0.0;
      _imageUploadCompleted[image.path] = false;
    });

    // Start background compression and upload
    _compressAndUploadInBackground(image);
  }

  Future<void> _compressAndAddMultipleImages(List<File> images) async {
    if (images.isEmpty) return;

    // Add all images immediately to UI
    setState(() {
      _pendingImages.addAll(images);
      // Initialize progress tracking for all new images
      for (File image in images) {
        _imageUploadProgress[image.path] = 0.0;
        _imageUploadCompleted[image.path] = false;
      }
    });

    // Process each image in background
    for (File image in images) {
      _compressAndUploadInBackground(image);
    }

    Get.snackbar(
      'Images Added',
      '${images.length} images are being processed in background',
      duration: const Duration(seconds: 2),
    );
  }

  // Background compression and upload for seamless UX
  Future<void> _compressAndUploadInBackground(File originalImage) async {
    try {
      final String imagePath = originalImage.path;

      // Step 1: Start compression animation
      setState(() {
        _imageUploadProgress[imagePath] = 0.1; // Show compression starting
      });

      // Step 2: Compress image
      final compressedImage = await _imageService.compressImage(originalImage);
      final File imageToUpload = compressedImage ?? originalImage;

      setState(() {
        _imageUploadProgress[imagePath] = 0.3; // Compression complete
      });

      // Step 3: Start upload animation
      _animateImageProgress(imagePath);

      // Step 4: Upload to S3 using batch upload with single image
      final String storagePath = _getStoragePath();

      final List<String> uploadedUrls = await _imageService.uploadImagesToS3(
        imageFiles: [imageToUpload],
        storagePath: storagePath,
        uniqueIdentifier: widget.sessionId,
        compress: false, // Already compressed
        maxConcurrency: 1,
      );

      final String? uploadedUrl =
          uploadedUrls.isNotEmpty ? uploadedUrls.first : null;

      if (uploadedUrl != null) {
        // Success: Move from pending to uploaded
        setState(() {
          // Remove from pending list
          final int pendingIndex = _pendingImages.indexWhere(
            (f) => f.path == imagePath,
          );
          if (pendingIndex != -1) {
            _pendingImages.removeAt(pendingIndex);
          }

          // Add to uploaded list
          _images.add(uploadedUrl);

          // Mark as completed
          _imageUploadProgress[imagePath] = 1.0;
          _imageUploadCompleted[imagePath] = true;
        });

        // Show success feedback
        if (compressedImage != null) {
          final originalSize = await originalImage.length();
          final compressedSize = await imageToUpload.length();
          final reductionPercent =
              ((originalSize - compressedSize) / originalSize * 100).round();

          debugPrint(
            '✅ Image uploaded successfully. Size reduced by $reductionPercent%',
          );
        } else {
          debugPrint('✅ Image uploaded successfully (no compression)');
        }

        // Clean up progress tracking after delay
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _imageUploadProgress.remove(imagePath);
              _imageUploadCompleted.remove(imagePath);
            });
          }
        });

        // Clean up compressed file if different from original
        if (compressedImage != null &&
            compressedImage.path != originalImage.path) {
          try {
            await compressedImage.delete();
          } catch (e) {
            debugPrint('Failed to cleanup compressed file: $e');
          }
        }
      } else {
        // Upload failed
        setState(() {
          _imageUploadProgress[imagePath] = 0.0;
          _imageUploadCompleted[imagePath] = false;
        });

        debugPrint('❌ Failed to upload image');
        Get.snackbar(
          'Upload Failed',
          'Failed to upload image. Will retry on save.',
          backgroundColor: Colors.orange.withOpacity(0.8),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Error occurred
      setState(() {
        _imageUploadProgress[originalImage.path] = 0.0;
        _imageUploadCompleted[originalImage.path] = false;
      });

      debugPrint('❌ Background upload error: $e');
      Get.snackbar(
        'Processing Error',
        'Image added but will be processed on save.',
        backgroundColor: Colors.orange.withOpacity(0.8),
        duration: const Duration(seconds: 2),
      );
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

  // Animate image upload progress for visual feedback
  void _animateImageProgress(String imagePath) async {
    // Animate from 10% to 90% over 2 seconds
    for (double progress = 0.1; progress <= 0.9; progress += 0.15) {
      if (_imageUploadProgress.containsKey(imagePath) &&
          _imageUploadCompleted[imagePath] != true) {
        setState(() {
          _imageUploadProgress[imagePath] = progress;
        });
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }
}
