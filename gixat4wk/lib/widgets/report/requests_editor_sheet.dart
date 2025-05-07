import 'package:flutter/material.dart';
import '../../utils/report_utils.dart';

/// Bottom sheet widget for editing requests, findings, and observations
class RequestsEditorSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String itemType;
  final String fieldName;
  final Function(List<Map<String, dynamic>>) onUpdate;

  const RequestsEditorSheet({
    required this.title,
    required this.items,
    required this.itemType,
    required this.fieldName,
    required this.onUpdate,
    super.key,
  });

  @override
  State<RequestsEditorSheet> createState() => _RequestsEditorSheetState();
}

class _RequestsEditorSheetState extends State<RequestsEditorSheet> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                          ),
                          onPressed: _addNewItem,
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            widget.onUpdate(_items);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child:
                    _items.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.list_alt_outlined,
                                color: Colors.grey[600],
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No items added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _addNewItem,
                                icon: const Icon(Icons.add),
                                label: Text(
                                  'Add ${widget.itemType.capitalize()}',
                                ),
                              ),
                            ],
                          ),
                        )
                        : ReorderableListView.builder(
                          scrollController: scrollController,
                          padding: const EdgeInsets.all(16),
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = _items.removeAt(oldIndex);
                              _items.insert(newIndex, item);
                            });
                          },
                          itemCount: _items.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildRequestItem(_items[index], index),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> item, int index) {
    final theme = Theme.of(context);
    final isVisible = item['visible'] ?? true;

    Color urgencyColor;
    switch ((item['argancy'] ?? 'low').toLowerCase()) {
      case 'high':
        urgencyColor = Colors.red;
        break;
      case 'medium':
        urgencyColor = Colors.orange;
        break;
      default:
        urgencyColor = Colors.green;
    }

    return Card(
      key: ValueKey(item['id'] ?? index),
      color:
          isVisible
              ? Colors.white
              : Colors.grey[200], // Light color for light theme
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: urgencyColor,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              item[widget.fieldName] ?? '',
              style: TextStyle(
                color:
                    isVisible
                        ? Colors.black
                        : Colors.grey, // Changed to black for light theme
                decoration: isVisible ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle:
                item['price'] != null && item['price'] > 0
                    ? Text(
                      '${item['price']} AED',
                      style: TextStyle(
                        color: isVisible ? theme.primaryColor : Colors.grey,
                      ),
                    )
                    : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isVisible)
                  const Icon(
                    Icons.visibility_off,
                    color: Colors.grey,
                    size: 18,
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.black54,
                  ), // Changed from white70 to black54 for light mode
                  onPressed: () => _editItem(item, index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
                const Icon(Icons.drag_handle, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addNewItem() {
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      widget.fieldName: '',
      'argancy': 'low',
      'price': 0,
      'visible': true,
    };

    _editItem(newItem, -1); // -1 indicates new item
  }

  void _editItem(Map<String, dynamic> item, int index) {
    final TextEditingController textController = TextEditingController(
      text: item[widget.fieldName] ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: (item['price'] ?? 0).toString(),
    );
    String currentUrgency = item['argancy'] ?? 'low';
    bool isVisible = item['visible'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(index == -1 ? 'Add Item' : 'Edit Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description field
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price field
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Price (AED)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Urgency selector
                    Text(
                      'Urgency Level',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialogUrgencyOption(
                          'Low',
                          Colors.green,
                          currentUrgency,
                          (value) =>
                              setDialogState(() => currentUrgency = value),
                        ),
                        _buildDialogUrgencyOption(
                          'Medium',
                          Colors.orange,
                          currentUrgency,
                          (value) =>
                              setDialogState(() => currentUrgency = value),
                        ),
                        _buildDialogUrgencyOption(
                          'High',
                          Colors.red,
                          currentUrgency,
                          (value) =>
                              setDialogState(() => currentUrgency = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Visibility toggle
                    Row(
                      children: [
                        Text(
                          'Visible in Report',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const Spacer(),
                        Switch(
                          value: isVisible,
                          onChanged:
                              (value) =>
                                  setDialogState(() => isVisible = value),
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedItem = Map<String, dynamic>.from(item);
                    updatedItem[widget.fieldName] = textController.text;
                    updatedItem['argancy'] = currentUrgency;
                    updatedItem['price'] =
                        int.tryParse(priceController.text) ?? 0;
                    updatedItem['visible'] = isVisible;

                    setState(() {
                      if (index == -1) {
                        _items.add(updatedItem);
                      } else {
                        _items[index] = updatedItem;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text('Delete Item'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  setState(() {
                    _items.removeAt(index);
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('DELETE'),
              ),
            ],
          ),
    );
  }

  Widget _buildDialogUrgencyOption(
    String label,
    Color color,
    String currentValue,
    Function(String) onChanged,
  ) {
    final isSelected = currentValue.toLowerCase() == label.toLowerCase();

    return InkWell(
      onTap: () => onChanged(label.toLowerCase()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(77) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withAlpha(77),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
