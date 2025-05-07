import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DetailScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isEditing;
  final bool isSaving;
  final Function()? onEditPressed;
  final Function()? onSavePressed;
  final Function()? onCancelPressed;
  final Function()? shareAction;

  const DetailScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.isEditing = false,
    this.isSaving = false,
    this.onEditPressed,
    this.onSavePressed,
    this.onCancelPressed,
    this.shareAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button and title
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.black, // Black icon for back
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Black text for title
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ), // Darker gray for subtitle
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),

          // Edit and Save Buttons
          Row(
            children: [
              if (isEditing && onCancelPressed != null)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: isSaving ? null : onCancelPressed,
                  tooltip: 'Cancel Editing',
                ),
              if (!isEditing && shareAction != null)
                IconButton(
                  icon: Icon(Icons.share, color: const Color(0xFF25D366)),
                  onPressed: shareAction,
                  tooltip: 'Share via WhatsApp',
                ),
              if (isSaving)
                // Show loading indicator when saving
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.black,
                    ), // Black loader
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    isEditing ? Icons.save_outlined : Icons.edit_outlined,
                  ),
                  onPressed: isEditing ? onSavePressed : onEditPressed,
                  tooltip: isEditing ? 'Save Changes' : 'Edit',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
