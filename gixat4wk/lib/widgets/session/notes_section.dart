import 'package:flutter/material.dart';
import './section_card.dart';

class NotesSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const NotesSection({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Notes',
      icon: Icons.edit_note,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: 'Add notes about this session...',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(16),
          suffixIcon:
              focusNode.hasFocus
                  ? IconButton(
                    icon: const Icon(Icons.check_circle),
                    onPressed: () => focusNode.unfocus(),
                    tooltip: 'Done',
                  )
                  : null,
        ),
        maxLines: 5,
        minLines: 3,
        textInputAction: TextInputAction.newline,
        onChanged: (value) {
          // Auto-save notes as user types (optional)
          // You can add debouncing here if needed
        },
      ),
    );
  }
}
