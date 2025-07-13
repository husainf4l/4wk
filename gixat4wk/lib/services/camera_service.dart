import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'aws_s3_service.dart';

/// Service that handles all camera and image-related functionality.
/// This includes picking images from gallery or camera and uploading to S3.
class CameraService {
  final ImagePicker _imagePicker = ImagePicker();
  final AwsS3Service _s3Service = AwsS3Service();

  /// Picks a single image from the given source.
  /// Returns a File object representing the selected image or null if cancelled.
  Future<File?> pickSingleImage({
    required ImageSource source,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
      return null;
    }
  }

  /// Picks multiple images from the gallery.
  /// Returns a list of File objects representing the selected images.
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      _showErrorSnackbar('Failed to pick images: $e');
      return [];
    }
  }

  /// Shows a modal sheet to select image source (camera or gallery).
  void showImageSourceOptions(
    BuildContext context, {
    required Function(File?) onImageSelected,
    Function(List<File>)? onMultipleImagesSelected,
    bool allowMultiple = false,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickSingleImage(
                    source: ImageSource.camera,
                  );
                  onImageSelected(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickSingleImage(
                    source: ImageSource.gallery,
                  );
                  onImageSelected(file);
                },
              ),
              if (allowMultiple)
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Select Multiple Images'),
                  onTap: () async {
                    Navigator.pop(context);
                    final files = await pickMultipleImages();
                    if (files.isNotEmpty) {
                      // Use the multiple images callback if provided
                      if (onMultipleImagesSelected != null) {
                        onMultipleImagesSelected(files);
                      } else {
                        // Fall back to single image callback with just the first image
                        onImageSelected(files.first);
                      }
                    } else {
                      onImageSelected(null);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Uploads a list of image files to S3 Storage with compression.
  /// Returns a list of download URLs for successfully uploaded images.
  Future<List<String>> uploadImagesToS3({
    required List<File> imageFiles,
    required String storagePath,
    String? uniqueIdentifier,
    bool compress = true,
  }) async {
    if (imageFiles.isEmpty) return [];

    try {
      List<String> uploadedUrls = [];

      for (var imageFile in imageFiles) {
        try {
          // Create a unique file name with timestamp and optional identifier
          String fileName =
              '${uniqueIdentifier ?? 'image'}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
          String objectKey = '$storagePath/$fileName';

          // Upload the file with compression
          String? downloadUrl = await _s3Service.uploadFile(
            file: imageFile,
            objectKey: objectKey,
            compress: compress,
          );

          // Check if URL is valid
          if (downloadUrl != null && downloadUrl.startsWith('http')) {
            uploadedUrls.add(downloadUrl);
          }
        } catch (e) {
          _showErrorSnackbar('Failed to upload image: $e');
        }
      }

      // Show success message if any images were uploaded
      if (uploadedUrls.isNotEmpty) {
        Get.snackbar(
          'Success',
          'Images uploaded successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      return uploadedUrls;
    } catch (e) {
      _showErrorSnackbar('Failed to upload images: $e');
      return [];
    }
  }

  /// Legacy method for backward compatibility
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

  /// Helper method to show error snackbar
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
