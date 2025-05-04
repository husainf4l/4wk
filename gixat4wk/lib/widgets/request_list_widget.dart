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
    final theme = Theme.of(context);

    if (requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(51)),
        ),
        child: Center(
          child: Text(
            'No service requests added',
            style: TextStyle(
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
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
        switch (argancy) {
          case 'high':
            argancyColor = Colors.red;
            break;
          case 'medium':
            argancyColor = Colors.orange;
            break;
          default:
            argancyColor = Colors.green;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: InkWell(
              onTap:
                  isEditing && onEditArgancy != null
                      ? () => _showArgancyDialog(context, request)
                      : null,
              customBorder: const CircleBorder(),
              child: Tooltip(
                message: isEditing ? 'Tap to change urgency' : 'Urgency level',
                child: CircleAvatar(
                  backgroundColor: argancyColor,
                  child: Text(argancy[0].toUpperCase()),
                ),
              ),
            ),
            title: Text(request['request'] ?? 'Unknown Request'),

            trailing:
                isEditing && onRemoveRequest != null
                    ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
    String selectedArgancy = 'low';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final textController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Request'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter service request',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.build_circle),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text('Urgency Level:'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildUrgencyOption(
                        'Low',
                        Colors.green,
                        selectedArgancy,
                        (value) {
                          setState(() => selectedArgancy = value);
                        },
                      ),
                      _buildUrgencyOption(
                        'Medium',
                        Colors.orange,
                        selectedArgancy,
                        (value) {
                          setState(() => selectedArgancy = value);
                        },
                      ),
                      _buildUrgencyOption('High', Colors.red, selectedArgancy, (
                        value,
                      ) {
                        setState(() => selectedArgancy = value);
                      }),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final request = textController.text.trim();
                    if (request.isNotEmpty) {
                      onAddRequest(request, selectedArgancy);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildUrgencyOption(
    String label,
    Color color,
    String selectedValue,
    Function(String) onSelect,
  ) {
    final isSelected = selectedValue.toLowerCase() == label.toLowerCase();

    return InkWell(
      onTap: () => onSelect(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withAlpha(77) : null,
        ),
        child: Column(
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
