import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../models/unified_session_activity.dart';
import '../../services/session/unified_session_service.dart';
import '../../services/image_handling_service.dart';
import '../../config/aws_config.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/session/notes_section.dart';
import '../../widgets/session/media_section.dart';
import '../../widgets/session/requests_section.dart';
import '../../widgets/session/session_context_section.dart';
import '../../widgets/session/mileage_section.dart';
import '../../widgets/session/findings_section.dart';
import '../../widgets/session/observations_section.dart';
import '../../widgets/session/report_data_section.dart';
import '../../widgets/session/finding_dialog.dart';
import '../../widgets/session/observation_dialog.dart';

enum ActivityView { details, media }

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

  // View switcher state
  Set<ActivityView> _selectedView = {ActivityView.details};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isAddingImage = false; // Prevent rapid image additions
  double _uploadProgress = 0.0;

  // Track individual image upload progress
  final Map<String, double> _imageUploadProgress =
      {}; // File path -> progress (0.0 to 1.0)
  final Map<String, bool> _imageUploadCompleted =
      {}; // File path -> completed status

  // Form controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _requestController = TextEditingController();

  // Focus nodes
  final FocusNode _notesFocusNode = FocusNode();
  final FocusNode _requestFocusNode = FocusNode();

  // Selected urgency for quick requests
  String _selectedUrgency = 'Medium';

  // Common data
  List<String> _images = []; // Uploaded image URLs
  List<String> _videos = []; // Uploaded video URLs
  final List<File> _pendingImages = []; // Local images waiting to be uploaded
  final List<File> _pendingVideos = []; // Local videos waiting to be uploaded
  final List<String> _videosToDelete = []; // Track videos to delete from S3
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

    // Listen to focus changes to update the UI
    _notesFocusNode.addListener(() => setState(() {}));
    _requestFocusNode.addListener(() => setState(() {}));

    _loadExistingActivity();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _mileageController.dispose();
    _requestController.dispose();
    _notesFocusNode.dispose();
    _requestFocusNode.dispose();
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
      case ActivityStage.jobCard:
        return 'Job Card';
    }
  }

  IconData get _stageIconData {
    switch (widget.stage) {
      case ActivityStage.clientNotes:
        return Icons.notes;
      case ActivityStage.inspection:
        return Icons.search;
      case ActivityStage.testDrive:
        return Icons.directions_car;
      case ActivityStage.report:
        return Icons.assignment;
      case ActivityStage.jobCard:
        return Icons.assignment_outlined;
    }
  }

  Future<void> _saveActivity() async {
    debugPrint('🔄 Save activity started for stage: ${widget.stage}');

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
    });

    try {
      // Step 1: Upload any remaining pending images (if any)
      if (_pendingImages.isNotEmpty) {
        setState(() {
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
          setState(() {});
        }

        // Show feedback briefly
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Step 2: Upload pending videos (if any)
      if (_pendingVideos.isNotEmpty) {
        setState(() {
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
            });
          }
        } catch (e) {
          debugPrint('Failed to upload video batch: $e');
          setState(() {});
        }

        // Show success feedback briefly
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Step 3: Delete removed videos from S3
      if (_videosToDelete.isNotEmpty) {
        setState(() {
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

        String? activityId;
        if (widget.stage == ActivityStage.jobCard) {
          // Use createJobCard method for job card activities to automatically create job orders
          debugPrint(
            '🔄 Creating job card activity with automatic job order creation...',
          );
          activityId = await _unifiedService.createJobCard(
            sessionId: widget.sessionId,
            clientId: widget.clientId,
            carId: widget.carId,
            garageId: widget.garageId,
            notes: activity.notes,
            jobCardItems: activity.requests,
            images: activity.images,
            requests: activity.requests,
          );
        } else {
          // Use regular createActivity for other stages
          activityId = await _unifiedService.createActivity(activity);
        }

        success = activityId != null;
        if (success) {
          debugPrint('✅ Activity created successfully with ID: $activityId');
          if (widget.stage == ActivityStage.jobCard) {
            debugPrint('✅ Job order also created automatically');
          }
        } else {
          debugPrint('❌ Failed to create activity');
        }
      }

      setState(() {
        _uploadProgress = 1.0;
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
      setState(() {});
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      debugPrint('🏁 Save process finished');
      setState(() {
        _isSaving = false;
        _uploadProgress = 0.0;
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

      case ActivityStage.jobCard:
        return UnifiedSessionActivity(
          id: id,
          sessionId: widget.sessionId,
          clientId: widget.clientId,
          carId: widget.carId,
          garageId: widget.garageId,
          stage: ActivityStage.jobCard,
          notes: _notesController.text.trim(),
          requests: _requests, // jobCardItems are stored in 'requests'
          images: _images,
          videos: _videos,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading $_stageTitle...'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // A slightly off-white background
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_stageIconData, color: theme.primaryColor),
            const SizedBox(width: 12),
            Text(
              _stageTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveActivity,
                icon:
                    _isSaving
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                        : const Icon(Icons.save, size: 18),
                label: Text(
                  _isSaving ? '${(_uploadProgress * 100).toInt()}%' : 'Save',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: SegmentedButton<ActivityView>(
              segments: const [
                ButtonSegment<ActivityView>(
                  value: ActivityView.details,
                  label: Text('Details'),
                  icon: Icon(Icons.description),
                ),
                ButtonSegment<ActivityView>(
                  value: ActivityView.media,
                  label: Text('Media'),
                  icon: Icon(Icons.perm_media),
                ),
              ],
              selected: _selectedView,
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedView = newSelection;
                });
              },
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                selectedForegroundColor: theme.primaryColor,
                selectedBackgroundColor: theme.primaryColor.withValues(
                  alpha: 0.1,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _selectedView.first == ActivityView.details
                    ? _buildDetailsView()
                    : _buildMediaView(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session context (optional)
          if (widget.sessionData != null)
            SessionContextSection(sessionData: widget.sessionData!),

          // Stage-specific sections
          ..._buildStageSpecificSections(),

          // Notes section (always visible)
          NotesSection(
            controller: _notesController,
            focusNode: _notesFocusNode,
          ),

          // Service Requests section
          RequestsSection(
            requests: _requests,
            selectedUrgency: _selectedUrgency,
            onUrgencyChanged: (value) {
              setState(() {
                _selectedUrgency = value;
              });
            },
            onAddRequest: _addQuickRequest,
            onRemoveRequest: _removeRequest,
            requestController: _requestController,
            requestFocusNode: _requestFocusNode,
          ),

          const SizedBox(height: 100), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildMediaView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaSection(
            images: _images,
            videos: _videos,
            pendingImages: _pendingImages,
            pendingVideos: _pendingVideos,
            imageUploadProgress: _imageUploadProgress,
            imageUploadCompleted: _imageUploadCompleted,
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
            onAddImage: _addImage,
            onAddVideo: _addVideo,
            onRemoveExistingVideo: _removeExistingVideo,
            onRemovePendingVideo: _removePendingVideo,
            onOpenVideoPlayer: _openVideoPlayer,
          ),
          const SizedBox(height: 100), // Extra space for FAB
        ],
      ),
    );
  }

  List<Widget> _buildStageSpecificSections() {
    switch (widget.stage) {
      case ActivityStage.clientNotes:
        return [
          MileageSection(
            controller: _mileageController,
            onChanged: (value) => _mileage = value,
          ),
        ];
      case ActivityStage.inspection:
        return [
          FindingsSection(
            findings: _findings,
            onAdd: _addFinding,
            onRemove: _removeFinding,
            onEdit: _editFinding,
          ),
        ];
      case ActivityStage.testDrive:
        return [
          ObservationsSection(
            observations: _observations,
            onAdd: _addObservation,
            onRemove: _removeObservation,
            onEdit: _editObservation,
          ),
        ];
      case ActivityStage.report:
        return [
          ReportDataSection(
            reportData: _reportData,
            onTitleChanged: (value) => _reportData['title'] = value,
            onSummaryChanged: (value) => _reportData['summary'] = value,
          ),
        ];
      case ActivityStage.jobCard:
        return [_buildJobCardSection()];
    }
  }

  Widget _buildJobCardSection() {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _getJobCardItemsGroupedByCar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading job card data: ${snapshot.error}'),
            ),
          );
        }

        final groupedItems = snapshot.data ?? {};

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Job Card Items',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (groupedItems.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No job card items found',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Items from client notes, inspection, and test drive will appear here',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...groupedItems.entries.map(
                    (entry) => _buildCarJobSection(entry.key, entry.value),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarJobSection(String carId, List<Map<String, dynamic>> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Car ID: ${carId.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildJobCardItem(item, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCardItem(Map<String, dynamic> item, int index) {
    final itemType = item['type'] ?? 'Unknown';
    final itemText =
        item['text'] ??
        item['request'] ??
        item['description'] ??
        'No description';
    final priority = item['priority'] ?? item['argancy'] ?? 'Medium';
    final isCompleted = item['completed'] ?? false;

    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isCompleted ? Colors.green : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion checkbox
          Checkbox(
            value: isCompleted,
            onChanged: (bool? value) {
              _updateJobCardItemCompletion(index, value ?? false);
            },
          ),
          const SizedBox(width: 8),
          // Item content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      itemType,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  itemText,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  _getJobCardItemsGroupedByCar() async {
    final Map<String, List<Map<String, dynamic>>> groupedItems = {};

    try {
      // Get all activities for this session
      final activities = await _unifiedService.getActivitiesForSession(
        sessionId: widget.sessionId,
      );

      for (final activity in activities) {
        final carId = activity.carId;
        if (!groupedItems.containsKey(carId)) {
          groupedItems[carId] = [];
        }

        // Add requests from all stages
        for (final request in activity.requests) {
          groupedItems[carId]!.add({
            'type': 'Request',
            'text': request['request'] ?? request['description'] ?? '',
            'priority': request['argancy'] ?? request['priority'] ?? 'Medium',
            'completed': request['completed'] ?? false,
            'source': activity.stage.displayName,
            'activityId': activity.id,
          });
        }

        // Add findings from inspection
        if (activity.findings != null) {
          for (final finding in activity.findings!) {
            groupedItems[carId]!.add({
              'type': 'Finding',
              'text': finding['description'] ?? finding['issue'] ?? '',
              'priority':
                  finding['severity'] ?? finding['priority'] ?? 'Medium',
              'completed': finding['completed'] ?? false,
              'source': 'Inspection',
              'activityId': activity.id,
            });
          }
        }

        // Add observations from test drive
        if (activity.observations != null) {
          for (final observation in activity.observations!) {
            groupedItems[carId]!.add({
              'type': 'Observation',
              'text': observation['description'] ?? observation['issue'] ?? '',
              'priority':
                  observation['severity'] ??
                  observation['priority'] ??
                  'Medium',
              'completed': observation['completed'] ?? false,
              'source': 'Test Drive',
              'activityId': activity.id,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching job card items: $e');
    }

    return groupedItems;
  }

  void _updateJobCardItemCompletion(int index, bool isCompleted) {
    setState(() {
      if (index < _requests.length) {
        _requests[index]['completed'] = isCompleted;
      }
    });
  }

  // Finding methods
  void _addFinding() async {
    final result = await Get.dialog<Map<String, dynamic>>(
      const FindingDialog(),
    );
    if (result != null) {
      setState(() {
        _findings.add(result);
      });
    }
  }

  void _editFinding(int index, Map<String, dynamic> finding) async {
    final result = await Get.dialog<Map<String, dynamic>>(
      FindingDialog(finding: finding),
    );
    if (result != null) {
      setState(() {
        _findings[index] = result;
      });
    }
  }

  void _removeFinding(int index) {
    setState(() => _findings.removeAt(index));
  }

  // Observation methods
  void _addObservation() async {
    final result = await Get.dialog<Map<String, dynamic>>(
      const ObservationDialog(),
    );
    if (result != null) {
      setState(() {
        _observations.add(result);
      });
    }
  }

  void _editObservation(int index, Map<String, dynamic> observation) async {
    final result = await Get.dialog<Map<String, dynamic>>(
      ObservationDialog(observation: observation),
    );
    if (result != null) {
      setState(() {
        _observations[index] = result;
      });
    }
  }

  void _removeObservation(int index) {
    setState(() => _observations.removeAt(index));
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
          backgroundColor: Colors.orange.withValues(alpha: 0.8),
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
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
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
      case ActivityStage.jobCard:
        return '${AWSConfig.carImagesFolder}/job-cards';
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
  void _addQuickRequest(String requestText) {
    setState(() {
      _requests.add({
        'request': requestText,
        'argancy': _selectedUrgency,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Clear the input field and keep focus for next entry
    _requestController.clear();

    // Show quick feedback
    Get.snackbar(
      'Request Added',
      '$requestText (${_selectedUrgency.toLowerCase()} priority)',
      duration: const Duration(seconds: 1),
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  void _removeRequest(int index) {
    setState(() {
      _requests.removeAt(index);
    });
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
