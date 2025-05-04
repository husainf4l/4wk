import 'package:flutter/material.dart';

class ReportAddItemSection extends StatefulWidget {
  final String title;
  final String itemType; // 'request', 'finding', or 'observation'
  final String
  fieldName; // The field name in the data - 'request', 'finding', or 'observation'
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onUpdate;
  final bool isEditing;
  final Function()? onAddButtonPressed;
  final String addButtonText;
  final String emptyStateText;

  const ReportAddItemSection({
    super.key,
    required this.title,
    required this.itemType,
    required this.fieldName,
    required this.items,
    required this.onUpdate,
    this.isEditing = false,
    this.onAddButtonPressed,
    this.addButtonText = 'Add Item',
    this.emptyStateText = 'No items added yet',
  });

  @override
  State<ReportAddItemSection> createState() => _ReportAddItemSectionState();
}

class _ReportAddItemSectionState extends State<ReportAddItemSection> {
  final TextEditingController _textController = TextEditingController();
  String _selectedArgancy = 'low';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _textController.clear();
    _selectedArgancy = 'low';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Add ${widget.itemType.capitalize()}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter ${widget.itemType} description',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
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
                          _selectedArgancy,
                          (value) {
                            setState(() => _selectedArgancy = value);
                          },
                        ),
                        _buildUrgencyOption(
                          'Medium',
                          Colors.orange,
                          _selectedArgancy,
                          (value) {
                            setState(() => _selectedArgancy = value);
                          },
                        ),
                        _buildUrgencyOption(
                          'High',
                          Colors.red,
                          _selectedArgancy,
                          (value) {
                            setState(() => _selectedArgancy = value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        _addItem(text, _selectedArgancy);
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('ADD'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _addItem(String text, String argancy) {
    final newItem = {
      widget.fieldName: text,
      'argancy': argancy,
      'price': 0,
      'visible': true,
    };

    final updatedItems = List<Map<String, dynamic>>.from(widget.items);
    updatedItems.add(newItem);
    widget.onUpdate(updatedItems);
  }

  void _updateItem(Map<String, dynamic> updatedItem) {
    final index = widget.items.indexWhere(
      (item) => item[widget.fieldName] == updatedItem[widget.fieldName],
    );

    if (index != -1) {
      final updatedItems = List<Map<String, dynamic>>.from(widget.items);
      updatedItems[index] = updatedItem;
      widget.onUpdate(updatedItems);
    }
  }

  void _deleteItem(Map<String, dynamic> itemToDelete) {
    final updatedItems = List<Map<String, dynamic>>.from(widget.items);
    updatedItems.removeWhere(
      (item) => item[widget.fieldName] == itemToDelete[widget.fieldName],
    );
    widget.onUpdate(updatedItems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            if (widget.isEditing)
              TextButton.icon(
                icon: const Icon(Icons.add_circle),
                label: Text(widget.addButtonText),
                onPressed: widget.onAddButtonPressed ?? _showAddDialog,
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (widget.items.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return _buildItemWidget(widget.items[index]);
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForType(widget.itemType),
              size: 48,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 8),
            Text(
              widget.emptyStateText,
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onAddButtonPressed ?? _showAddDialog,
                icon: const Icon(Icons.add),
                label: Text(widget.addButtonText),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.withAlpha(100)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemWidget(Map<String, dynamic> item) {
    return _buildReportItemWidget(
      item: item,
      fieldName: widget.fieldName,
      itemType: widget.itemType,
      isEditing: widget.isEditing,
      onUpdate: _updateItem,
      onDelete: _deleteItem,
    );
  }

  Widget _buildReportItemWidget({
    required Map<String, dynamic> item,
    required String fieldName,
    required String itemType,
    required bool isEditing,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    // Using the extension method to create the widget
    // In a real application, you would use your ReportEditableRequest widget here
    final theme = Theme.of(context);
    final visible = item['visible'] ?? true;

    Color argancyColor;
    final argancy = item['argancy'] ?? 'low';
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

    if (!isEditing) {
      // Display mode
      if (!visible) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withAlpha(100)),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility_off, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item[fieldName] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              Text(
                'Hidden from client',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primaryColor.withAlpha(26)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: argancyColor,
                shape: BoxShape.circle,
              ),
              margin: const EdgeInsets.only(top: 3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item[fieldName] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            if (item['price'] != null && item['price'] > 0)
              Text(
                '${item['price']} AED',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      );
    }

    // Edit mode - simplified for now, but you would use ReportEditableRequest
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withAlpha(26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: argancyColor,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(top: 3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item[fieldName] ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item['price'] != null && item['price'] > 0)
                Text(
                  '${item['price']} AED',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              IconButton(
                icon: Icon(
                  visible ? Icons.visibility : Icons.visibility_off,
                  color: visible ? Colors.white : Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  final updatedItem = Map<String, dynamic>.from(item);
                  updatedItem['visible'] = !visible;
                  onUpdate(updatedItem);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                onPressed: () {
                  // Show edit dialog
                  _editItem(item);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => onDelete(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editItem(Map<String, dynamic> item) {
    _textController.text = item[widget.fieldName] ?? '';
    _selectedArgancy = item['argancy'] ?? 'low';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Edit ${widget.itemType.capitalize()}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter ${widget.itemType} description',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
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
                          _selectedArgancy,
                          (value) {
                            setState(() => _selectedArgancy = value);
                          },
                        ),
                        _buildUrgencyOption(
                          'Medium',
                          Colors.orange,
                          _selectedArgancy,
                          (value) {
                            setState(() => _selectedArgancy = value);
                          },
                        ),
                        _buildUrgencyOption(
                          'High',
                          Colors.red,
                          _selectedArgancy,
                          (value) {
                            setState(() => _selectedArgancy = value);
                          },
                        ),
                      ],
                    ),
                    // Price field
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (AED)',
                        hintText: '0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      controller: TextEditingController(
                        text: (item['price'] ?? 0).toString(),
                      ),
                      onChanged: (value) {
                        item['price'] = int.tryParse(value) ?? 0;
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        final updatedItem = Map<String, dynamic>.from(item);
                        updatedItem[widget.fieldName] = text;
                        updatedItem['argancy'] = _selectedArgancy;
                        _updateItem(updatedItem);
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('SAVE'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildUrgencyOption(
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
            color: isSelected ? color : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withAlpha(25) : null,
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

  IconData _getIconForType(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'request':
        return Icons.build;
      case 'finding':
        return Icons.search;
      case 'observation':
        return Icons.directions_car;
      default:
        return Icons.note;
    }
  }
}

extension ReportItemStringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
