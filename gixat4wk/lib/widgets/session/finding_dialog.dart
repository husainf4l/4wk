import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FindingDialog extends StatefulWidget {
  final Map<String, dynamic>? finding;

  const FindingDialog({super.key, this.finding});

  @override
  State<FindingDialog> createState() => _FindingDialogState();
}

class _FindingDialogState extends State<FindingDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.finding?['title'] ?? '');
    _descController =
        TextEditingController(text: widget.finding?['description'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Title cannot be empty');
      return;
    }
    final result = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    Get.back(result: result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.finding != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.plagiarism_outlined, color: Colors.blue),
          const SizedBox(width: 10),
          Text(isEditing ? 'Edit Finding' : 'Add Finding'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Finding Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
