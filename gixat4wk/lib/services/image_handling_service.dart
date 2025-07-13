import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'error_service.dart';
import 'aws_s3_service.dart';
import '../config/aws_config.dart';

class ImageHandlingService {
  final ImagePicker _picker = ImagePicker();
  final AwsS3Service _s3Service = AwsS3Service();

  // Prevent concurrent image picker operations
  bool _isPickerActive = false;

  // Get error service for error logging
  final ErrorService _errorService = Get.find<ErrorService>(
    tag: 'ErrorService',
  );

  // Pick a single image from camera or gallery
  Future<File?> pickSingleImage({required ImageSource source}) async {
    // Prevent concurrent operations
    if (_isPickerActive) {
      debugPrint('ImagePicker already active, ignoring request');
      return null;
    }

    _isPickerActive = true;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Lower for better performance
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ImageHandlingService.pickSingleImage',
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isPickerActive = false;
    }
  }

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    // Prevent concurrent operations
    if (_isPickerActive) {
      debugPrint('ImagePicker already active, ignoring request');
      return [];
    }

    _isPickerActive = true;

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ImageHandlingService.pickMultipleImages',
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isPickerActive = false;
    }
  }

  // Show dialog for selecting image source
  void showImageSourceOptions(
    BuildContext context, {
    required Function(File?) onImageSelected,
    Function(List<File>)? onMultipleImagesSelected,
    bool allowMultiple = false,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final File? image = await pickSingleImage(
                      source: ImageSource.camera,
                    );
                    onImageSelected(image);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (allowMultiple && onMultipleImagesSelected != null) {
                      final List<File> images = await pickMultipleImages();
                      onMultipleImagesSelected(images);
                    } else {
                      final File? image = await pickSingleImage(
                        source: ImageSource.gallery,
                      );
                      onImageSelected(image);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  // Upload images to S3 Storage with compression and parallel processing
  Future<List<String>> uploadImagesToS3({
    required List<File> imageFiles,
    required String storagePath,
    String? uniqueIdentifier,
    bool compress = true,
    int maxConcurrency = 6, // Increased default concurrency for speed
  }) async {
    if (imageFiles.isEmpty) return [];

    final String identifier = uniqueIdentifier ?? const Uuid().v4();

    // Process uploads in batches for optimal performance
    List<String> allUrls = [];

    for (int i = 0; i < imageFiles.length; i += maxConcurrency) {
      final int end = (i + maxConcurrency).clamp(0, imageFiles.length);
      final List<File> batch = imageFiles.sublist(i, end);

      // Upload batch in parallel
      final List<Future<String?>> uploadFutures =
          batch.asMap().entries.map((entry) {
            final int batchIndex = entry.key;
            final File imageFile = entry.value;
            final String fileName =
                '${DateTime.now().millisecondsSinceEpoch + batchIndex}_${path.basename(imageFile.path)}';
            final String objectKey = '$storagePath/${identifier}_$fileName';

            return _uploadSingleImage(imageFile, objectKey, compress);
          }).toList();

      try {
        final List<String?> batchResults = await Future.wait(uploadFutures);

        // Filter out null results and add successful uploads
        final List<String> successfulUrls =
            batchResults.where((url) => url != null).cast<String>().toList();

        allUrls.addAll(successfulUrls);

        debugPrint(
          'Batch ${(i ~/ maxConcurrency) + 1}: ${successfulUrls.length}/${batch.length} uploads successful',
        );
      } catch (e, stackTrace) {
        _errorService.logError(
          e,
          context:
              'ImageHandlingService.uploadImagesToS3 - batch ${(i ~/ maxConcurrency) + 1}',
          stackTrace: stackTrace,
        );
      }
    }

    debugPrint(
      'Total uploads completed: ${allUrls.length}/${imageFiles.length}',
    );
    return allUrls;
  }

  // Helper method for single image upload
  Future<String?> _uploadSingleImage(
    File imageFile,
    String objectKey,
    bool compress,
  ) async {
    try {
      return await _s3Service.uploadFile(
        file: imageFile,
        objectKey: objectKey,
        compress: compress,
      );
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ImageHandlingService._uploadSingleImage',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Legacy method for backward compatibility
  Future<List<String>> uploadImagesToFirebase({
    required List<File> imageFiles,
    required String storagePath,
    String? uniqueIdentifier,
  }) async {
    return uploadImagesToS3(
      imageFiles: imageFiles,
      storagePath: storagePath,
      uniqueIdentifier: uniqueIdentifier,
    );
  }

  // Delete image from S3 Storage
  Future<bool> deleteImageFromS3(String imageUrl) async {
    try {
      final String objectKey = AWSConfig.extractKeyFromUrl(imageUrl);
      return await _s3Service.deleteFile(objectKey);
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ImageHandlingService.deleteImageFromS3',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> deleteImageFromFirebase(String imageUrl) async {
    return deleteImageFromS3(imageUrl);
  }

  // Compress image without uploading
  Future<File?> compressImage(File imageFile) async {
    try {
      return await _s3Service.compressImage(imageFile);
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ImageHandlingService.compressImage',
        stackTrace: stackTrace,
      );
      return imageFile; // Return original if compression fails
    }
  }

  // Pick a single video from camera or gallery
  Future<File?> pickSingleVideo({required ImageSource source}) async {
    // Prevent concurrent operations
    if (_isPickerActive) {
      debugPrint('Video picker already active, ignoring request');
      return null;
    }

    _isPickerActive = true;

    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5), // 5 minute limit
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ImageHandlingService.pickSingleVideo',
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isPickerActive = false;
    }
  }

  // Show dialog for selecting video source
  void showVideoSourceOptions(
    BuildContext context, {
    required Function(File?) onVideoSelected,
    Function(List<File>)? onMultipleVideosSelected,
    bool allowMultiple = false,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Record a video'),
                  onTap: () async {
                    Navigator.pop(context);
                    final File? video = await pickSingleVideo(
                      source: ImageSource.camera,
                    );
                    onVideoSelected(video);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final File? video = await pickSingleVideo(
                      source: ImageSource.gallery,
                    );
                    onVideoSelected(video);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  // Upload videos to S3 Storage with parallel processing
  Future<List<String>> uploadVideosToS3({
    required List<File> videoFiles,
    required String storagePath,
    String? uniqueIdentifier,
    int maxConcurrency = 4, // Increased for faster video uploads
  }) async {
    if (videoFiles.isEmpty) return [];

    final String identifier = uniqueIdentifier ?? const Uuid().v4();

    // Process videos in smaller batches due to larger file sizes
    List<String> allUrls = [];

    for (int i = 0; i < videoFiles.length; i += maxConcurrency) {
      final int end = (i + maxConcurrency).clamp(0, videoFiles.length);
      final List<File> batch = videoFiles.sublist(i, end);

      // Upload batch in parallel
      final List<Future<String?>> uploadFutures =
          batch.asMap().entries.map((entry) {
            final int batchIndex = entry.key;
            final File videoFile = entry.value;
            final String fileName =
                '${DateTime.now().millisecondsSinceEpoch + batchIndex}_${path.basename(videoFile.path)}';
            final String objectKey =
                '$storagePath/videos/${identifier}_$fileName';

            return _uploadSingleVideo(videoFile, objectKey);
          }).toList();

      try {
        final List<String?> batchResults = await Future.wait(uploadFutures);

        // Filter out null results and add successful uploads
        final List<String> successfulUrls =
            batchResults.where((url) => url != null).cast<String>().toList();

        allUrls.addAll(successfulUrls);

        debugPrint(
          'Video batch ${(i ~/ maxConcurrency) + 1}: ${successfulUrls.length}/${batch.length} uploads successful',
        );
      } catch (e, stackTrace) {
        _errorService.logError(
          e,
          context:
              'ImageHandlingService.uploadVideosToS3 - batch ${(i ~/ maxConcurrency) + 1}',
          stackTrace: stackTrace,
        );
      }
    }

    debugPrint(
      'Total video uploads completed: ${allUrls.length}/${videoFiles.length}',
    );
    return allUrls;
  }

  // Helper method for single video upload
  Future<String?> _uploadSingleVideo(File videoFile, String objectKey) async {
    try {
      return await _s3Service.uploadFile(
        file: videoFile,
        objectKey: objectKey,
        compress: false, // Don't compress videos
      );
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ImageHandlingService._uploadSingleVideo',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Upload single video to S3 Storage
  Future<String?> uploadSingleVideoToS3({
    required File videoFile,
    required String storagePath,
    String? uniqueIdentifier,
  }) async {
    final List<String> urls = await uploadVideosToS3(
      videoFiles: [videoFile],
      storagePath: storagePath,
      uniqueIdentifier: uniqueIdentifier,
    );
    return urls.isNotEmpty ? urls.first : null;
  }

  // Delete video from S3 Storage
  Future<bool> deleteVideoFromS3(String videoUrl) async {
    try {
      final String objectKey = AWSConfig.extractKeyFromUrl(videoUrl);
      return await _s3Service.deleteFile(objectKey);
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ImageHandlingService.deleteVideoFromS3',
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
