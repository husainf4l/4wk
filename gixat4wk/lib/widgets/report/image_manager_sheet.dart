import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import '../../services/image_handling_service.dart';

/// Service to pick and upload images in one step
class ImagePickerService {
  final ImageHandlingService _imageHandlingService =
      Get.find<ImageHandlingService>();

  Future<List<String>> pickAndUploadMultipleImages() async {
    try {
      final List<File> images =
          await _imageHandlingService.pickMultipleImages();
      if (images.isEmpty) return [];

      return await _imageHandlingService.uploadImagesToFirebase(
        imageFiles: images,
        storagePath: 'reports',
      );
    } catch (e) {
      debugPrint('Error picking/uploading images: $e');
      rethrow;
    }
  }
}

/// Widget for managing images in a bottom sheet
class ImageManagerSheet extends StatefulWidget {
  final String title;
  final List<String> images;
  final Function(List<String>) onUpdate;

  const ImageManagerSheet({
    required this.title,
    required this.images,
    required this.onUpdate,
    super.key,
  });

  @override
  State<ImageManagerSheet> createState() => _ImageManagerSheetState();
}

class _ImageManagerSheetState extends State<ImageManagerSheet> {
  late List<String> _images;
  final List<String> _selectedImages = [];
  final ImagePickerService _imagePickerService = ImagePickerService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (_selectedImages.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _deleteSelectedImages,
                          ),
                        IconButton(
                          icon:
                              _isUploading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.add_photo_alternate),
                          onPressed: _isUploading ? null : _pickAndUploadImages,
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            widget.onUpdate(_images);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Grid
              Expanded(
                child:
                    _images.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                color: Colors.grey[600],
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No images added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _pickAndUploadImages,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Add Images'),
                              ),
                            ],
                          ),
                        )
                        : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            final imageUrl = _images[index];
                            final isSelected = _selectedImages.contains(
                              imageUrl,
                            );

                            return GestureDetector(
                              onTap: () => _toggleImageSelection(imageUrl),
                              onLongPress:
                                  () => _showFullImage(context, imageUrl),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Container(
                                            color:
                                                Colors
                                                    .grey[300], // Lighter color for light mode
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                  // Selection overlay
                                  if (isSelected)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withAlpha(76),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleImageSelection(String imageUrl) {
    setState(() {
      if (_selectedImages.contains(imageUrl)) {
        _selectedImages.remove(imageUrl);
      } else {
        _selectedImages.add(imageUrl);
      }
    });
  }

  Future<void> _pickAndUploadImages() async {
    try {
      setState(() => _isUploading = true);

      final newUrls = await _imagePickerService.pickAndUploadMultipleImages();

      if (newUrls.isNotEmpty) {
        setState(() {
          _images.addAll(newUrls);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _deleteSelectedImages() {
    if (_selectedImages.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text('Delete Images'),
            content: Text(
              'Are you sure you want to delete ${_selectedImages.length} selected image${_selectedImages.length > 1 ? 's' : ''}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  setState(() {
                    _images.removeWhere((url) => _selectedImages.contains(url));
                    _selectedImages.clear();
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('DELETE'),
              ),
            ],
          ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(8),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }
}
