import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/unified_session_activity.dart';
import '../services/session/unified_session_service.dart';
import '../services/image_handling_service.dart';
import '../config/aws_config.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/session/finding_dialog.dart';
import '../widgets/session/observation_dialog.dart';
import '../models/activity_view.dart';

class UnifiedSessionActivityController extends GetxController {
  // Services
  final UnifiedSessionService _unifiedService = Get.find();
  final ImageHandlingService _imageService = Get.find();

  // Screen arguments
  final String sessionId;
  final String clientId;
  final String carId;
  final String garageId;
  final ActivityStage stage;
  final String? activityId;
  final Map<String, dynamic>? sessionData;

  UnifiedSessionActivityController({
    required this.sessionId,
    required this.clientId,
    required this.carId,
    required this.garageId,
    required this.stage,
    this.activityId,
    this.sessionData,
  });

  // UI State
  final selectedView = {ActivityView.details}.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isAddingImage = false.obs;
  final uploadProgress = 0.0.obs;

  // Image Upload Tracking
  final imageUploadProgress = <String, double>{}.obs;
  final imageUploadCompleted = <String, bool>{}.obs;

  // Form Controllers
  late TextEditingController notesController;
  late TextEditingController mileageController;
  late TextEditingController requestController;

  // Focus Nodes
  late FocusNode notesFocusNode;
  late FocusNode requestFocusNode;

  // Data
  final selectedUrgency = 'Medium'.obs;
  final images = <String>[].obs;
  final videos = <String>[].obs;
  final pendingImages = <File>[].obs;
  final pendingVideos = <File>[].obs;
  final videosToDelete = <String>[];
  final requests = <Map<String, dynamic>>[].obs;
  final findings = <Map<String, dynamic>>[].obs;
  final observations = <Map<String, dynamic>>[].obs;
  final reportData = <String, dynamic>{}.obs;
  final mileage = ''.obs;

  UnifiedSessionActivity? _currentActivity;

  String get stageTitle {
    switch (stage) {
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

  IconData get stageIconData {
    switch (stage) {
      case ActivityStage.clientNotes:
        return Icons.notes;
      case ActivityStage.inspection:
        return Icons.search;
      case ActivityStage.testDrive:
        return Icons.directions_car;
      case ActivityStage.report:
        return Icons.assignment;
      case ActivityStage.jobCard:
        return Icons.assignment_turned_in_outlined;
    }
  }

  @override
  void onInit() {
    super.onInit();
    notesController = TextEditingController();
    mileageController = TextEditingController();
    requestController = TextEditingController();
    notesFocusNode = FocusNode();
    requestFocusNode = FocusNode();

    notesFocusNode.addListener(() => update());
    requestFocusNode.addListener(() => update());

    _loadExistingActivity();
  }

  @override
  void onClose() {
    notesController.dispose();
    mileageController.dispose();
    requestController.dispose();
    notesFocusNode.dispose();
    requestFocusNode.dispose();
    _cleanupPendingImages();
    imageUploadProgress.clear();
    imageUploadCompleted.clear();
    super.onClose();
  }

  void _cleanupPendingImages() {
    for (File image in pendingImages) {
      try {
        if (image.existsSync() && image.path.contains('_compressed')) {
          image.deleteSync();
        }
      } catch (e) {
        debugPrint('Failed to cleanup compressed image: $e');
      }
    }
    for (File video in pendingVideos) {
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
    isLoading.value = true;
    try {
      UnifiedSessionActivity? activity;
      if (activityId != null) {
        activity = await _unifiedService.getActivity(activityId!);
      } else {
        final activities = await _unifiedService.getActivitiesForSession(
          sessionId: sessionId,
          stage: stage,
        );
        if (activities.isNotEmpty) {
          activity = activities.first;
        }
      }

      if (activity != null) {
        _populateFormWithActivity(activity);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load activity data');
    } finally {
      isLoading.value = false;
    }
  }

  void _populateFormWithActivity(UnifiedSessionActivity activity) {
    _currentActivity = activity;
    notesController.text = activity.notes;
    images.assignAll(activity.images);
    videos.assignAll(activity.videos);
    pendingImages.clear();
    pendingVideos.clear();
    requests.assignAll(activity.requests);

    if (activity.findings != null) {
      findings.assignAll(activity.findings!);
    }
    if (activity.observations != null) {
      observations.assignAll(activity.observations!);
    }
    if (activity.reportData != null) {
      reportData.value = Map.from(activity.reportData!);
      if (activity.stage == ActivityStage.clientNotes &&
          activity.reportData!.containsKey('mileage')) {
        mileage.value = activity.reportData!['mileage'] ?? '';
        mileageController.text = mileage.value;
      }
    }
  }

  Future<void> saveActivity() async {
    debugPrint('🔄 Save activity started for stage: $stage');
    isSaving.value = true;
    uploadProgress.value = 0.0;

    try {
      await _uploadMedia();
      await _deleteRemovedVideos();
      await _saveActivityData();
    } catch (e) {
      debugPrint('💥 Error during save: $e');
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      debugPrint('🏁 Save process finished');
      isSaving.value = false;
      uploadProgress.value = 0.0;
    }
  }

  Future<void> _uploadMedia() async {
    if (pendingImages.isNotEmpty) {
      uploadProgress.value = 0.1;
      final String storagePath = _getStoragePath();
      final List<File> remainingImages =
          pendingImages
              .where((image) => !(imageUploadCompleted[image.path] ?? false))
              .toList();
      if (remainingImages.isNotEmpty) {
        debugPrint(
          '📤 Uploading ${remainingImages.length} remaining images...',
        );
        for (File image in remainingImages) {
          _animateImageProgress(image.path);
        }
        final List<String> uploadedUrls = await _imageService.uploadImagesToS3(
          imageFiles: remainingImages,
          storagePath: storagePath,
          uniqueIdentifier: sessionId,
          compress: false,
          maxConcurrency: 6,
        );
        if (uploadedUrls.isNotEmpty) {
          images.addAll(uploadedUrls);
        }
      }
      pendingImages.clear();
      uploadProgress.value = 0.4;
      Future.delayed(const Duration(milliseconds: 500), () {
        imageUploadProgress.clear();
        imageUploadCompleted.clear();
      });
    }

    if (pendingVideos.isNotEmpty) {
      uploadProgress.value = 0.5;
      final String storagePath = _getStoragePath();
      final List<String> uploadedVideoUrls = await _imageService
          .uploadVideosToS3(
            videoFiles: pendingVideos,
            storagePath: storagePath,
            uniqueIdentifier: sessionId,
            maxConcurrency: 4,
          );
      if (uploadedVideoUrls.isNotEmpty) {
        videos.addAll(uploadedVideoUrls);
        pendingVideos.clear();
        uploadProgress.value = 0.7;
      }
    }
  }

  Future<void> _deleteRemovedVideos() async {
    if (videosToDelete.isNotEmpty) {
      uploadProgress.value = 0.8;
      debugPrint('🗑️ Deleting ${videosToDelete.length} videos from S3...');
      for (String videoUrl in videosToDelete) {
        try {
          await _imageService.deleteVideoFromS3(videoUrl);
        } catch (e) {
          debugPrint('❌ Failed to delete video: $videoUrl, error: $e');
        }
      }
      videosToDelete.clear();
    }
  }

  Future<void> _saveActivityData() async {
    uploadProgress.value = 0.9;
    bool success = false;
    final activity = _createActivityFromForm(_currentActivity?.id ?? '');

    if (_currentActivity != null) {
      success = await _unifiedService.updateActivity(activity.id, activity);
    } else {
      String? newActivityId;
      if (stage == ActivityStage.jobCard) {
        // Use createJobCard method for job card activities to automatically create job orders
        debugPrint(
          '🔄 Creating job card activity with automatic job order creation...',
        );
        newActivityId = await _unifiedService.createJobCard(
          sessionId: sessionId,
          clientId: clientId,
          carId: carId,
          garageId: garageId,
          notes: activity.notes,
          jobCardItems: activity.requests,
          images: activity.images,
          requests: activity.requests,
        );
        if (newActivityId != null) {
          debugPrint('✅ Job order also created automatically');
        }
      } else {
        // Use regular createActivity for other stages
        newActivityId = await _unifiedService.createActivity(activity);
      }
      success = newActivityId != null;
    }

    uploadProgress.value = 1.0;

    if (success) {
      Get.snackbar('Success', '$stageTitle saved successfully');
      await Future.delayed(const Duration(milliseconds: 800));
      Get.back(result: true);
    } else {
      Get.snackbar('Error', 'Failed to save $stageTitle');
    }
  }

  UnifiedSessionActivity _createActivityFromForm(String id) {
    switch (stage) {
      case ActivityStage.clientNotes:
        return UnifiedSessionActivity(
          id: id,
          sessionId: sessionId,
          clientId: clientId,
          carId: carId,
          garageId: garageId,
          stage: ActivityStage.clientNotes,
          notes: notesController.text.trim(),
          requests: requests,
          images: images,
          videos: videos,
          reportData: {'mileage': mileage.value},
        );
      case ActivityStage.inspection:
        return UnifiedSessionActivity.forInspection(
          sessionId: sessionId,
          clientId: clientId,
          carId: carId,
          garageId: garageId,
          notes: notesController.text.trim(),
          findings: findings,
          images: images,
          videos: videos,
          requests: requests,
        );
      case ActivityStage.testDrive:
        return UnifiedSessionActivity.forTestDrive(
          sessionId: sessionId,
          clientId: clientId,
          carId: carId,
          garageId: garageId,
          notes: notesController.text.trim(),
          observations: observations,
          images: images,
          videos: videos,
          requests: requests,
        );
      case ActivityStage.report:
        return UnifiedSessionActivity.forReport(
          sessionId: sessionId,
          clientId: clientId,
          carId: carId,
          garageId: garageId,
          notes: notesController.text.trim(),
          reportData: reportData,
          images: images,
          videos: videos,
          requests: requests,
        );
      case ActivityStage.jobCard:
        return UnifiedSessionActivity.forJobCard(
          sessionId: sessionId,
          clientId: clientId,
          carId: carId,
          garageId: garageId,
          notes: notesController.text.trim(),
          jobCardItems: requests.toList(), // Use toList() for type safety
          images: images.toList(),
          videos: videos.toList(),
        );
    }
  }

  // Finding methods
  void addFinding() async {
    final result = await Get.dialog<Map<String, dynamic>>(
      const FindingDialog(),
    );
    if (result != null) {
      findings.add(result);
    }
  }

  void editFinding(int index, Map<String, dynamic> finding) async {
    final result = await Get.dialog<Map<String, dynamic>>(
      FindingDialog(finding: finding),
    );
    if (result != null) {
      findings[index] = result;
    }
  }

  void removeFinding(int index) {
    findings.removeAt(index);
  }

  // Observation methods
  void addObservation() async {
    final result = await Get.dialog<Map<String, dynamic>>(
      const ObservationDialog(),
    );
    if (result != null) {
      observations.add(result);
    }
  }

  void editObservation(int index, Map<String, dynamic> observation) async {
    final result = await Get.dialog<Map<String, dynamic>>(
      ObservationDialog(observation: observation),
    );
    if (result != null) {
      observations[index] = result;
    }
  }

  void removeObservation(int index) {
    observations.removeAt(index);
  }

  // Media methods
  void addImage(BuildContext context) {
    if (isAddingImage.value) return;
    isAddingImage.value = true;

    _imageService.showImageSourceOptions(
      context,
      onImageSelected: (File? image) async {
        if (image != null) await _compressAndAddImage(image);
        isAddingImage.value = false;
      },
      onMultipleImagesSelected: (List<File> images) async {
        await _compressAndAddMultipleImages(images);
        isAddingImage.value = false;
      },
      allowMultiple: true,
    );

    Future.delayed(const Duration(seconds: 2), () {
      isAddingImage.value = false;
    });
  }

  void addVideo(BuildContext context) {
    _imageService.showVideoSourceOptions(
      context,
      onVideoSelected: (File? video) async {
        if (video != null) pendingVideos.add(video);
      },
      onMultipleVideosSelected: (List<File> videos) async {
        pendingVideos.addAll(videos);
      },
      allowMultiple: false,
    );
  }

  void removeUploadedImage(int index) async {
    final String imageUrl = images[index];
    final bool? shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
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

    isSaving.value = true;
    try {
      final bool deleted = await _imageService.deleteImageFromS3(imageUrl);
      if (deleted) {
        images.removeAt(index);
        Get.snackbar('Success', 'Image deleted successfully');
      } else {
        images.removeAt(index);
        Get.snackbar('Warning', 'Image removed but may still exist in storage');
      }
    } catch (e) {
      images.removeAt(index);
      Get.snackbar('Error', 'Failed to delete image: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void removeSelectedImage(int index) {
    final File imageToRemove = pendingImages[index];
    pendingImages.removeAt(index);
    imageUploadProgress.remove(imageToRemove.path);
    imageUploadCompleted.remove(imageToRemove.path);
  }

  void removeExistingVideo(String videoUrl) {
    videos.remove(videoUrl);
    videosToDelete.add(videoUrl);
  }

  void removePendingVideo(File video) {
    pendingVideos.remove(video);
  }

  Future<void> _compressAndAddImage(File image) async {
    pendingImages.add(image);
    imageUploadProgress[image.path] = 0.0;
    imageUploadCompleted[image.path] = false;
    _compressAndUploadInBackground(image);
  }

  Future<void> _compressAndAddMultipleImages(List<File> images) async {
    if (images.isEmpty) return;
    pendingImages.addAll(images);
    for (File image in images) {
      imageUploadProgress[image.path] = 0.0;
      imageUploadCompleted[image.path] = false;
      _compressAndUploadInBackground(image);
    }
    Get.snackbar(
      'Images Added',
      '${images.length} images are being processed in the background',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _compressAndUploadInBackground(File originalImage) async {
    try {
      final String imagePath = originalImage.path;
      imageUploadProgress[imagePath] = 0.1;
      final compressedImage = await _imageService.compressImage(originalImage);
      final File imageToUpload = compressedImage ?? originalImage;
      imageUploadProgress[imagePath] = 0.3;
      _animateImageProgress(imagePath);

      final String storagePath = _getStoragePath();
      final List<String> uploadedUrls = await _imageService.uploadImagesToS3(
        imageFiles: [imageToUpload],
        storagePath: storagePath,
        uniqueIdentifier: sessionId,
        compress: false,
        maxConcurrency: 1,
      );

      final String? uploadedUrl =
          uploadedUrls.isNotEmpty ? uploadedUrls.first : null;

      if (uploadedUrl != null) {
        final int pendingIndex = pendingImages.indexWhere(
          (f) => f.path == imagePath,
        );
        if (pendingIndex != -1) {
          pendingImages.removeAt(pendingIndex);
        }
        images.add(uploadedUrl);
        imageUploadProgress[imagePath] = 1.0;
        imageUploadCompleted[imagePath] = true;

        Future.delayed(const Duration(milliseconds: 2000), () {
          imageUploadProgress.remove(imagePath);
          imageUploadCompleted.remove(imagePath);
        });

        if (compressedImage != null &&
            compressedImage.path != originalImage.path) {
          try {
            await compressedImage.delete();
          } catch (e) {
            debugPrint('Failed to cleanup compressed file: $e');
          }
        }
      } else {
        imageUploadProgress[imagePath] = 0.0;
        imageUploadCompleted[imagePath] = false;
        Get.snackbar(
          'Upload Failed',
          'Failed to upload image. Will retry on save.',
        );
      }
    } catch (e) {
      imageUploadProgress[originalImage.path] = 0.0;
      imageUploadCompleted[originalImage.path] = false;
      Get.snackbar(
        'Processing Error',
        'Image added but will be processed on save.',
      );
    }
  }

  String _getStoragePath() {
    switch (stage) {
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

  void openVideoPlayer({String? videoUrl, File? videoFile}) {
    Get.to(
      () => VideoPlayerWidget(
        videoUrl: videoUrl,
        videoFile: videoFile,
        title: videoUrl != null ? 'Video' : 'Preview Video',
      ),
    );
  }

  void _animateImageProgress(String imagePath) async {
    for (double progress = 0.1; progress <= 0.9; progress += 0.15) {
      if (imageUploadProgress.containsKey(imagePath) &&
          imageUploadCompleted[imagePath] != true) {
        imageUploadProgress[imagePath] = progress;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  // Request methods
  void addQuickRequest() {
    final String requestText = requestController.text.trim();
    if (requestText.isEmpty) return;

    requests.add({
      'request': requestText,
      'argancy': selectedUrgency.value,
      'timestamp': DateTime.now().toIso8601String(),
    });

    requestController.clear();

    Get.snackbar(
      'Request Added',
      '$requestText (${selectedUrgency.value.toLowerCase()} priority)',
      duration: const Duration(seconds: 1),
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  void removeRequest(int index) {
    requests.removeAt(index);
  }

  void updateUrgency(String value) {
    selectedUrgency.value = value;
  }
}
