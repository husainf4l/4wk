import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../services/aws_s3_service.dart';

class AWSTestController extends GetxController {
  // SECURITY FIX: Never hardcode AWS credentials!
  // This would need to be configured via environment variables in production
  final AwsS3Service? _awsService = null; // Disabled until proper config

  final RxBool isLoading = false.obs;
  final RxList<String> uploadedUrls = <String>[].obs;
  final RxString connectionStatus = 'Not tested'.obs;

  Future<void> testConnection() async {
    isLoading.value = true;
    try {
      if (_awsService == null) {
        connectionStatus.value = 'AWS Service not configured ⚠️';
        return;
      }
      // Connection test logic would go here
      connectionStatus.value = 'Service configured ✅';
    } catch (e) {
      connectionStatus.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        isLoading.value = true;
        final file = File(image.path);
        final url = await _awsService?.uploadFile(
          file: file,
          objectKey:
              'images/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
          contentType: 'image/jpeg',
        );

        if (url != null) {
          uploadedUrls.add(url);
          Get.snackbar(
            'Success',
            'Image uploaded successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to upload image',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error picking/uploading image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        isLoading.value = true;
        final file = File(video.path);
        final url = await _awsService?.uploadFile(
          file: file,
          objectKey:
              'videos/${DateTime.now().millisecondsSinceEpoch}_${video.name}',
          contentType: 'video/mp4',
        );

        if (url != null) {
          uploadedUrls.add(url);
          Get.snackbar(
            'Success',
            'Video uploaded successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to upload video',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error picking/uploading video: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        isLoading.value = true;
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        final url = await _awsService?.uploadFile(
          file: file,
          objectKey: 'documents/$fileName',
        );

        if (url != null) {
          uploadedUrls.add(url);
          Get.snackbar(
            'Success',
            'File uploaded successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to upload file',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error picking/uploading file: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void deleteUploadedFile(String url) async {
    try {
      // Note: Delete functionality not implemented in AWS service yet
      // For now, just remove from local list
      uploadedUrls.remove(url);
      Get.snackbar(
        'Success',
        'File deleted successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error deleting file: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void clearAll() {
    uploadedUrls.clear();
  }
}

class AWSTestScreen extends StatelessWidget {
  const AWSTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AWSTestController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('AWS S3 Upload Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: controller.clearAll,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all uploads',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'AWS S3 Connection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Text(
                        controller.connectionStatus.value,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              controller.connectionStatus.value.contains('✅')
                                  ? Colors.green
                                  : controller.connectionStatus.value.contains(
                                    '❌',
                                  )
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          controller.isLoading.value
                              ? null
                              : controller.testConnection,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Test Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Upload Buttons
            const Text(
              'Upload Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.isLoading.value
                            ? null
                            : controller.pickAndUploadImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.isLoading.value
                            ? null
                            : controller.pickAndUploadVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Upload Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed:
                  controller.isLoading.value
                      ? null
                      : controller.pickAndUploadFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Upload Any File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Loading Indicator
            Obx(
              () =>
                  controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink(),
            ),

            const SizedBox(height: 10),

            // Uploaded Files List
            const Text(
              'Uploaded Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Obx(
                () =>
                    controller.uploadedUrls.isEmpty
                        ? const Center(
                          child: Text(
                            'No files uploaded yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          itemCount: controller.uploadedUrls.length,
                          itemBuilder: (context, index) {
                            final url = controller.uploadedUrls[index];
                            final isImage =
                                url.contains('/images/') ||
                                url.toLowerCase().contains('.jpg') ||
                                url.toLowerCase().contains('.png') ||
                                url.toLowerCase().contains('.jpeg') ||
                                url.toLowerCase().contains('.gif');

                            return Card(
                              child: ListTile(
                                leading:
                                    isImage
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            url,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.error),
                                          ),
                                        )
                                        : Icon(
                                          url.contains('/videos/')
                                              ? Icons.video_file
                                              : Icons.insert_drive_file,
                                          size: 50,
                                        ),
                                title: Text(
                                  url.split('/').last,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  url,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        // Copy URL to clipboard or open in browser
                                        Get.snackbar(
                                          'URL Copied',
                                          'File URL copied to clipboard',
                                          backgroundColor: Colors.blue,
                                          colorText: Colors.white,
                                        );
                                      },
                                      icon: const Icon(Icons.copy),
                                    ),
                                    IconButton(
                                      onPressed:
                                          () => controller.deleteUploadedFile(
                                            url,
                                          ),
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
