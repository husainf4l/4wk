import 'package:flutter/material.dart';
import 'dart:io';
import '../../widgets/image_grid_widget.dart';
import './section_card.dart';

class MediaSection extends StatefulWidget {
  final List<String> images;
  final List<String> videos;
  final List<File> pendingImages;
  final List<File> pendingVideos;
  final Map<String, double> imageUploadProgress;
  final Map<String, bool> imageUploadCompleted;
  final Function(int) onRemoveUploadedImage;
  final Function(int) onRemoveSelectedImage;
  final Function() onAddImage;
  final Function() onAddVideo;
  final Function(String) onRemoveExistingVideo;
  final Function(File) onRemovePendingVideo;
  final Function({String? videoUrl, File? videoFile}) onOpenVideoPlayer;

  const MediaSection({
    super.key,
    required this.images,
    required this.videos,
    required this.pendingImages,
    required this.pendingVideos,
    required this.imageUploadProgress,
    required this.imageUploadCompleted,
    required this.onRemoveUploadedImage,
    required this.onRemoveSelectedImage,
    required this.onAddImage,
    required this.onAddVideo,
    required this.onRemoveExistingVideo,
    required this.onRemovePendingVideo,
    required this.onOpenVideoPlayer,
  });

  @override
  State<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<MediaSection> {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Media',
      icon: Icons.perm_media,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => widget.onAddImage(),
            icon: const Icon(Icons.add_photo_alternate, color: Colors.green),
            tooltip: 'Add Images',
          ),
          IconButton(
            onPressed: () => widget.onAddVideo(),
            icon: const Icon(Icons.videocam, color: Colors.orange),
            tooltip: 'Add Videos',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images section
          if (widget.images.isNotEmpty || widget.pendingImages.isNotEmpty) ...[
            Text(
              'Images (${widget.images.length + widget.pendingImages.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ImageGridWidget(
              uploadedImageUrls: widget.images,
              selectedImages: widget.pendingImages,
              isEditing: true,
              uploadProgress: widget.imageUploadProgress,
              uploadCompleted: widget.imageUploadCompleted,
              onRemoveUploadedImage: widget.onRemoveUploadedImage,
              onRemoveSelectedImage: widget.onRemoveSelectedImage,
            ),
            const SizedBox(height: 16),
          ],

          // Videos section
          if (widget.videos.isNotEmpty || widget.pendingVideos.isNotEmpty) ...[
            Text(
              'Videos (${widget.videos.length + widget.pendingVideos.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildVideosList(),
          ],

          // Empty state
          if (widget.images.isEmpty &&
              widget.pendingImages.isEmpty &&
              widget.videos.isEmpty &&
              widget.pendingVideos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No media added yet.'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    // Convert existing video URLs to display items
    List<Widget> videoWidgets = [];

    // Add existing videos (URLs)
    for (String videoUrl in widget.videos) {
      videoWidgets.add(
        Stack(
          children: [
            GestureDetector(
              onTap: () => widget.onOpenVideoPlayer(videoUrl: videoUrl),
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
                onTap: () => widget.onRemoveExistingVideo(videoUrl),
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
    for (File video in widget.pendingVideos) {
      videoWidgets.add(
        Stack(
          children: [
            GestureDetector(
              onTap: () => widget.onOpenVideoPlayer(videoFile: video),
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
                onTap: () => widget.onRemovePendingVideo(video),
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
}
