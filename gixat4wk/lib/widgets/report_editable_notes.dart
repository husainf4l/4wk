import 'package:flutter/material.dart';

class ReportEditableNotes extends StatefulWidget {
  final String? notes;
  final String title;
  final Function(String) onUpdate;
  final bool isEditing;
  final bool showIfEmpty;

  const ReportEditableNotes({
    super.key,
    this.notes,
    required this.title,
    required this.onUpdate,
    this.isEditing = false,
    this.showIfEmpty = true,
  });

  @override
  State<ReportEditableNotes> createState() => _ReportEditableNotesState();
}

class _ReportEditableNotesState extends State<ReportEditableNotes> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notes ?? '');
  }

  @override
  void didUpdateWidget(ReportEditableNotes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      _controller.text = widget.notes ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveNotes() {
    widget.onUpdate(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    // Don't show the component if there are no notes and showIfEmpty is false
    if ((widget.notes == null || widget.notes!.isEmpty) &&
        !widget.showIfEmpty &&
        !widget.isEditing) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final hasNotes = widget.notes != null && widget.notes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!widget.isEditing && hasNotes)
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (widget.isEditing)
          _buildEditableNotes()
        else if (hasNotes)
          _buildDisplayNotes()
        else
          _buildEmptyState(),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEditableNotes() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 8,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter notes here...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _saveNotes(),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayNotes() {
    final theme = Theme.of(context);
    final text = widget.notes ?? '';

    // If the text is longer than ~100 chars, show a truncated version unless expanded
    final showTruncatedText = text.length > 100 && !_isExpanded;
    final displayText =
        showTruncatedText ? '${text.substring(0, 100)}...' : text;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primaryColor.withAlpha(26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayText,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            if (showTruncatedText)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Tap to read more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child:
          widget.isEditing
              ? TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Notes'),
                onPressed: () {
                  // Set focus on the text field
                  FocusScope.of(context).requestFocus(FocusNode());
                  setState(() {});
                },
              )
              : Text(
                'No notes available',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
    );
  }
}
