import 'package:flutter/material.dart';

class NotesEditorWidget extends StatelessWidget {
  final String? notes;
  final bool isEditing;
  final Function() onEditPressed;

  const NotesEditorWidget({
    super.key,
    this.notes,
    required this.isEditing,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isEditing ? onEditPressed : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isEditing
                  ? Colors.grey[100] // Subtle light gray for edit mode
                  : Colors.white, // White for view mode
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isEditing
                    ? theme.primaryColor.withAlpha(77)
                    : Colors.grey.withAlpha(51),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notes == null || notes!.isEmpty)
              Row(
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Tap to add notes' : 'No notes added yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              Text(notes!, style: theme.textTheme.bodyMedium),
            if (isEditing && (notes?.isNotEmpty ?? false))
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Tap to edit',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static void showEditDialog(
    BuildContext context, {
    required String initialValue,
    required Function(String) onSave,
  }) {
    final TextEditingController notesController = TextEditingController(
      text: initialValue,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white, // White background for dialog
            title: const Text(
              'Edit Notes',
              style: TextStyle(color: Colors.black),
            ), // Black text for title
            content: TextField(
              controller: notesController,
              autofocus: true,
              maxLines: 5,
              style: const TextStyle(
                color: Colors.black,
              ), // Black text for input
              decoration: InputDecoration(
                hintText: 'Enter notes here',
                hintStyle: TextStyle(color: Colors.grey[500]), // Grey hint text
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                  ), // Use primary color for focused border
                ),
                prefixIcon: Icon(
                  Icons.note_alt,
                  color: Colors.grey[600],
                ), // Grey icon
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  onSave(notesController.text.trim());
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(
                        context,
                      ).primaryColor, // Primary color background
                  foregroundColor: Colors.white, // White text
                ),
                child: const Text('SAVE'),
              ),
            ],
          ),
    );
  }
}
