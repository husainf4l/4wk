import 'package:flutter/material.dart';

class RequestListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final bool isEditing;
  final Function(Map<String, dynamic>)? onRemoveRequest;
  final Function(Map<String, dynamic>, String)? onEditArgancy;
  final Function()? onAddRequest;

  const RequestListWidget({
    super.key,
    required this.requests,
    this.isEditing = false,
    this.onRemoveRequest,
    this.onEditArgancy,
    this.onAddRequest,
  });

  @override
  Widget build(BuildContext context) {

    if (requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Text('No service requests added yet.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final argancy = request['argancy'] ?? 'low';

        Color argancyColor;
        String argancyLabel;
        IconData argancyIcon;

        switch (argancy) {
          case 'high':
            argancyColor = Colors.red;
            argancyLabel = 'High';
            argancyIcon = Icons.arrow_upward;
            break;
          case 'medium':
            argancyColor = Colors.orange;
            argancyLabel = 'Medium';
            argancyIcon = Icons.remove;
            break;
          default:
            argancyColor = Colors.green;
            argancyLabel = 'Low';
            argancyIcon = Icons.arrow_downward;
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              request['request'] ?? 'Unknown Request',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap:
                    isEditing && onEditArgancy != null
                        ? () => _showArgancyDialog(context, request)
                        : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: argancyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(argancyIcon, color: argancyColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        argancyLabel,
                        style: TextStyle(
                          color: argancyColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            trailing:
                isEditing && onRemoveRequest != null
                    ? IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => onRemoveRequest!(request),
                    )
                    : null,
          ),
        );
      },
    );
  }

  void _showArgancyDialog(BuildContext context, Map<String, dynamic> request) {
    if (onEditArgancy == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Urgency Level'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildArgancyOption(context, 'Low', Colors.green, request),
                const SizedBox(height: 8),
                _buildArgancyOption(context, 'Medium', Colors.orange, request),
                const SizedBox(height: 8),
                _buildArgancyOption(context, 'High', Colors.red, request),
              ],
            ),
          ),
    );
  }

  Widget _buildArgancyOption(
    BuildContext context,
    String label,
    Color color,
    Map<String, dynamic> request,
  ) {
    final currentArgancy = request['argancy'] ?? 'low';
    final isSelected = currentArgancy.toLowerCase() == label.toLowerCase();

    return InkWell(
      onTap: () {
        onEditArgancy!(request, label.toLowerCase());
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withAlpha(77) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 14,
              child: Text(
                label[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  static void showAddRequestDialog(
    BuildContext context, {
    required Function(String, String) onAddRequest,
  }) {
    final requestController = TextEditingController();
    String selectedUrgency = 'low'; // Default urgency

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Text('Add Service Request'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: requestController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Request Description',
                      hintText: 'e.g., "Check engine light"',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Urgency Level',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'low',
                        label: Text('Low'),
                        icon: Icon(Icons.arrow_downward, color: Colors.green),
                      ),
                      ButtonSegment(
                        value: 'medium',
                        label: Text('Medium'),
                        icon: Icon(Icons.remove, color: Colors.orange),
                      ),
                      ButtonSegment(
                        value: 'high',
                        label: Text('High'),
                        icon: Icon(Icons.arrow_upward, color: Colors.red),
                      ),
                    ],
                    selected: {selectedUrgency},
                    onSelectionChanged: (newSelection) {
                      setDialogState(() {
                        selectedUrgency = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (requestController.text.trim().isNotEmpty) {
                      onAddRequest(
                        requestController.text.trim(),
                        selectedUrgency,
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
