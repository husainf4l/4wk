import 'package:flutter/material.dart';
import '../../widgets/report/info_widgets.dart';

/// Widget for building report sections with consistent styling
class ReportSectionWidget extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final List<Widget>? actions;
  final bool hasBorder;

  const ReportSectionWidget({
    super.key,
    required this.title,
    required this.child,
    this.padding,
    this.actions,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration:
          hasBorder
              ? BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      theme.brightness == Brightness.light
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius:
                  hasBorder
                      ? const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      )
                      : BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          // Section content
          Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Widget for building report request sections with edit capabilities
class RequestsSectionWidget extends StatelessWidget {
  final String title;
  final String section;
  final List<Map<String, dynamic>> items;
  final String fieldName;
  final bool isEditing;
  final VoidCallback? onEditAll;
  final VoidCallback? onAddNew;
  final Function(Map<String, dynamic>)? onEdit;
  final Function(Map<String, dynamic>)? onDelete;

  const RequestsSectionWidget({
    required this.title,
    required this.section,
    required this.items,
    required this.fieldName,
    required this.isEditing,
    this.onEditAll,
    this.onAddNew,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ReportSectionWidget(
      title: title,
      actions:
          isEditing
              ? [
                if (onEditAll != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    tooltip: 'Manage all items',
                    onPressed: onEditAll,
                  ),
                if (onAddNew != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Add item',
                    onPressed: onAddNew,
                  ),
              ]
              : null,
      hasBorder: false,
      child:
          items.isEmpty
              ? const EmptyStateWidget(message: 'No items added yet')
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder:
                    (context, index) =>
                        _buildRequestItem(context, items[index]),
              ),
    );
  }

  Widget _buildRequestItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isVisible = item['visible'] ?? true;

    // Get urgency color
    Color urgencyColor;
    switch ((item['argancy'] ?? 'low').toLowerCase()) {
      case 'high':
        urgencyColor = Colors.red;
        break;
      case 'medium':
        urgencyColor = Colors.orange;
        break;
      default:
        urgencyColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isVisible
                ? Colors.white
                : Colors.grey[200], // Light background for light theme
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isVisible
                  ? theme.primaryColor.withAlpha(51)
                  : Colors.grey.withAlpha(77),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4, right: 10),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item[fieldName] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              isVisible
                                  ? Colors.black
                                  : Colors
                                      .grey, // Changed to black for light theme
                          decoration:
                              isVisible ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      if (item['price'] != null && item['price'] > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${item['price']} AED',
                          style: TextStyle(
                            color: isVisible ? theme.primaryColor : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons section
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isVisible)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.visibility_off,
                            color: Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hidden',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: () => onEdit!(item),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: () => onDelete!(item),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget for displaying report notes with edit capabilities
class NotesSectionWidget extends StatelessWidget {
  final String title;
  final String? notes;
  final bool isEditing;
  final VoidCallback? onEdit;

  const NotesSectionWidget({
    required this.title,
    required this.notes,
    this.isEditing = false,
    this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ReportSectionWidget(
      title: title,
      actions:
          isEditing && onEdit != null
              ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: onEdit,
                ),
              ]
              : null,
      child: Text(
        notes ?? 'No notes recorded',
        style: TextStyle(
          color:
              notes != null
                  ? Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors
                          .black // Black text in light mode
                  : Colors.grey[500],
          fontStyle: notes != null ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }
}

/// Widget for image sections with management capabilities
class ImagesSectionWidget extends StatelessWidget {
  final String title;
  final String section;
  final List<String> images;
  final bool isEditing;
  final VoidCallback? onManageImages;
  final Function(int)? onRemoveImage;

  const ImagesSectionWidget({
    required this.title,
    required this.section,
    required this.images,
    required this.isEditing,
    this.onManageImages,
    this.onRemoveImage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            if (isEditing && onManageImages != null)
              IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.white70),
                tooltip: 'Manage images',
                onPressed: onManageImages,
              ),
          ],
        ),
        const SizedBox(height: 8),
        images.isEmpty
            ? const EmptyStateWidget(message: 'No images added')
            : _buildImageGrid(),
      ],
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[300], // Lighter gray for light theme
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.red,
                        ), // Red icon for broken image
                      ),
                    ),
              ),
            ),
            // Remove button
            if (isEditing && onRemoveImage != null)
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => onRemoveImage!(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
