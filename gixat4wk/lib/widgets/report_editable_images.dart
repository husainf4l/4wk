import 'dart:io';

import 'package:flutter/material.dart';
import '../services/image_handling_service.dart';

class ReportEditableImages extends StatefulWidget {
  final List<String> images;
  final String title;
  final Function(List<String>) onUpdate;
  final bool isEditing;
  final bool showIfEmpty;

  const ReportEditableImages({
    super.key,
    required this.images,
    required this.title,
    required this.onUpdate,
    this.isEditing = false,
    this.showIfEmpty = true,
  });

  @override
  State<ReportEditableImages> createState() => _ReportEditableImagesState();
}

class _ReportEditableImagesState extends State<ReportEditableImages> {
  final ImageHandlingService _imageHandlingService = ImageHandlingService();
  final List<File> _selectedImages = [];
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _imageUrls = List<String>.from(widget.images);
  }

  @override
  void didUpdateWidget(ReportEditableImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _imageUrls = List<String>.from(widget.images);
    }
  }

  void _showImageSourceOptions() {
    _imageHandlingService.showImageSourceOptions(
      context,
      onImageSelected: (File? file) {
        if (file != null && mounted) {
          setState(() {
            _selectedImages.add(file);
          });
          _uploadImages();
        }
      },
      onMultipleImagesSelected: (List<File> files) {
        if (mounted) {
          setState(() {
            _selectedImages.addAll(files);
          });
          _uploadImages();
        }
      },
      allowMultiple: true,
    );
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    try {
      final List<String> newImageUrls = await _imageHandlingService
          .uploadImagesToFirebase(
            imageFiles: _selectedImages,
            storagePath: 'report_images',
            uniqueIdentifier: DateTime.now().millisecondsSinceEpoch.toString(),
          );

      setState(() {
        _imageUrls.addAll(newImageUrls);
        _selectedImages.clear();
      });

      widget.onUpdate(_imageUrls);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
    widget.onUpdate(_imageUrls);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _imageUrls.removeAt(oldIndex);
      _imageUrls.insert(newIndex, item);
    });
    widget.onUpdate(_imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    // Don't show the component if there are no images and showIfEmpty is false
    if (_imageUrls.isEmpty && !widget.showIfEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (widget.isEditing)
              IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate,
                  color: Colors.white,
                ),
                onPressed: _showImageSourceOptions,
                tooltip: 'Add Images',
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_imageUrls.isEmpty && widget.isEditing)
          _buildEmptyState()
        else if (_imageUrls.isNotEmpty)
          _buildImageGrid(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text(
              'No images added yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showImageSourceOptions,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.withAlpha(100)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return widget.isEditing
        ? ReorderableGridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          onReorder: _reorderImages,
          itemCount: _imageUrls.length,
          itemBuilder: (context, index) {
            return _buildImageItem(index, _imageUrls[index], true);
          },
        )
        : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _imageUrls.length,
          itemBuilder: (context, index) {
            return _buildImageItem(index, _imageUrls[index], false);
          },
        );
  }

  Widget _buildImageItem(int index, String imageUrl, bool canDelete) {
    return Stack(
      key: ValueKey(imageUrl),
      children: [
        GestureDetector(
          onTap: () {
            // Show full-screen image viewer
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      body: Container(
                        color: Colors.black,
                        child: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(51)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
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
                errorBuilder:
                    (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
              ),
            ),
          ),
        ),
        if (canDelete && widget.isEditing)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeImage(index),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                tooltip: 'Remove image',
              ),
            ),
          ),
        if (widget.isEditing)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.drag_indicator,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Drag to reorder',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Custom ReorderableGridView that combines GridView with reordering capabilities
class ReorderableGridView extends StatefulWidget {
  final SliverGridDelegate gridDelegate;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final Function(int oldIndex, int newIndex) onReorder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ReorderableGridView.builder({
    super.key,
    required this.gridDelegate,
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    this.shrinkWrap = true,
    this.physics,
  });

  @override
  State<ReorderableGridView> createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<ReorderableGridView> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      buildDefaultDragHandles: false,
      onReorder: widget.onReorder,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        final child = widget.itemBuilder(context, index);
        return ReorderableDragStartListener(
          key: child.key!,
          index: index,
          child: child,
        );
      },
      // This hack makes it look like a grid
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final animValue = Curves.easeInOut.transform(animation.value);
            final scale = 1.0 + animValue * 0.1;
            return Transform.scale(scale: scale, child: child);
          },
          child: child,
        );
      },
    );
  }
}
