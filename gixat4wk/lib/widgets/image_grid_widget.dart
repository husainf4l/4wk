import 'package:flutter/material.dart';
import 'dart:io';

class ImageGridWidget extends StatelessWidget {
  final List<String> uploadedImageUrls;
  final List<File> selectedImages;
  final bool isEditing;
  final Function(int)? onRemoveUploadedImage;
  final Function(int)? onRemoveSelectedImage;
  final Function(String)? onImageTap;
  final Map<String, double>?
  uploadProgress; // File path -> progress (0.0 to 1.0)
  final Map<String, bool>? uploadCompleted; // File path -> completed status

  const ImageGridWidget({
    super.key,
    required this.uploadedImageUrls,
    this.selectedImages = const [],
    this.isEditing = false,
    this.onRemoveUploadedImage,
    this.onRemoveSelectedImage,
    this.onImageTap,
    this.uploadProgress,
    this.uploadCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uploaded images section
        if (uploadedImageUrls.isNotEmpty) ...[
          _buildUploadedImagesGrid(context),
          const SizedBox(height: 16),
        ],

        // Selected images waiting to be uploaded
        if (selectedImages.isNotEmpty) ...[
          _buildSelectedImagesNotice(context),
          _buildSelectedImagesGrid(context),
        ],
      ],
    );
  }

  Widget _buildUploadedImagesGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: uploadedImageUrls.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (onImageTap != null) {
                  onImageTap!(uploadedImageUrls[index]);
                } else {
                  _showFullScreenImage(context, uploadedImageUrls[index]);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white, // White background for light theme
                  child: Image.network(
                    uploadedImageUrls[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (isEditing && onRemoveUploadedImage != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemoveUploadedImage!(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedImagesNotice(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'These images will be uploaded when you save',
              style: TextStyle(color: Colors.amber[800], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImagesGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: selectedImages.length,
      itemBuilder: (context, index) {
        final File currentImage = selectedImages[index];
        final String imagePath = currentImage.path;
        final double? progress = uploadProgress?[imagePath];
        final bool? isCompleted = uploadCompleted?[imagePath];

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                currentImage,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Upload progress overlay
            if (progress != null && progress > 0.0 && isCompleted != true)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Uploading...',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

            // Upload completed overlay
            if (isCompleted == true)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withOpacity(0.8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 32),
                      SizedBox(height: 4),
                      Text(
                        'Uploaded!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Default upload icon when not uploading
            if ((progress == null || progress == 0.0) && isCompleted != true)
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withAlpha(153), Colors.transparent],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.file_upload_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

            if (isEditing &&
                onRemoveSelectedImage != null &&
                isCompleted != true)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemoveSelectedImage!(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }
}
