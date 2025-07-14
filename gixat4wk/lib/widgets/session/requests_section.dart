import 'package:flutter/material.dart';
import './section_card.dart';

class RequestsSection extends StatefulWidget {
  final List<Map<String, dynamic>> requests;
  final String selectedUrgency;
  final Function(String) onUrgencyChanged;
  final Function(String) onAddRequest;
  final Function(int) onRemoveRequest;
  final TextEditingController requestController;
  final FocusNode requestFocusNode;

  const RequestsSection({
    super.key,
    required this.requests,
    required this.selectedUrgency,
    required this.onUrgencyChanged,
    required this.onAddRequest,
    required this.onRemoveRequest,
    required this.requestController,
    required this.requestFocusNode,
  });

  @override
  State<RequestsSection> createState() => _RequestsSectionState();
}

class _RequestsSectionState extends State<RequestsSection> {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Service Requests',
      icon: Icons.build,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick add input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.requestController,
                  focusNode: widget.requestFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a service request and press Enter...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    suffixIcon:
                        widget.requestFocusNode.hasFocus
                            ? IconButton(
                              icon: const Icon(Icons.check_circle),
                              onPressed:
                                  () => widget.requestFocusNode.unfocus(),
                              tooltip: 'Done',
                            )
                            : null,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      widget.onAddRequest(value.trim());
                      // Keep focus on the text field after submitting
                      widget.requestFocusNode.requestFocus();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Urgency selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<String>(
                  value: widget.selectedUrgency,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                    DropdownMenuItem(
                      value: 'Critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) {
                    widget.onUrgencyChanged(value ?? 'Medium');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Display existing requests
          if (widget.requests.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'No service requests added yet.\nType above and press Enter to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.requests.length,
              itemBuilder: (context, index) {
                final request = widget.requests[index];
                return _buildRequestItem(index, request);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(int index, Map<String, dynamic> request) {
    final urgency = request['argancy'] ?? 'Medium';
    Color urgencyColor = _getUrgencyColor(urgency);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: urgencyColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          request['request'] ?? 'Service Request',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.flag, size: 14, color: urgencyColor),
            const SizedBox(width: 4),
            Text(
              urgency,
              style: TextStyle(
                color: urgencyColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick urgency change buttons
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (newUrgency) {
                setState(() {
                  widget.requests[index]['argancy'] = newUrgency;
                });
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'Low',
                      child: Text('Low Priority'),
                    ),
                    const PopupMenuItem(
                      value: 'Medium',
                      child: Text('Medium Priority'),
                    ),
                    const PopupMenuItem(
                      value: 'High',
                      child: Text('High Priority'),
                    ),
                    const PopupMenuItem(
                      value: 'Critical',
                      child: Text('Critical Priority'),
                    ),
                  ],
            ),
            IconButton(
              onPressed: () => widget.onRemoveRequest(index),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
