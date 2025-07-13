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

  // Get error service for error logging
  final ErrorService _errorService = Get.find<ErrorService>(
    tag: 'ErrorService',
  );

  // Pick a single image from camera or gallery
  Future<File?> pickSingleImage({required ImageSource source}) async {
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
    }
  }

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
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

  // Upload images to S3 Storage with compression
  Future<List<String>> uploadImagesToS3({
    required List<File> imageFiles,
    required String storagePath,
    String? uniqueIdentifier,
    bool compress = true,
  }) async {
    if (imageFiles.isEmpty) return [];

    final List<String> uploadedUrls = [];
    final String identifier = uniqueIdentifier ?? const Uuid().v4();

    for (int i = 0; i < imageFiles.length; i++) {
      final File imageFile = imageFiles[i];
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final String objectKey = '$storagePath/${identifier}_$fileName';

      try {
        final String? downloadUrl = await _s3Service.uploadFile(
          file: imageFile,
          objectKey: objectKey,
          compress: compress,
        );

        if (downloadUrl != null) {
          uploadedUrls.add(downloadUrl);
        }
      } catch (e, stackTrace) {
        _errorService.logError(
          e,
          context: 'ImageHandlingService.uploadImagesToS3',
          stackTrace: stackTrace,
        );
        // Continue with other uploads even if one fails
      }
    }

    return uploadedUrls;
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
}
