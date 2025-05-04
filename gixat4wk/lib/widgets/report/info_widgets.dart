import 'package:flutter/material.dart';

/// Helper widget for displaying information rows with label and value
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditing;

  const InfoRow({
    required this.label,
    required this.value,
    this.isEditing = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: TextStyle(
              color: value.isNotEmpty ? Colors.white : Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for text field input rows with labels
class TextFieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const TextFieldRow({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black12,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withAlpha(77)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying a generic empty state with a message
class EmptyStateWidget extends StatelessWidget {
  final String message;

  const EmptyStateWidget({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
