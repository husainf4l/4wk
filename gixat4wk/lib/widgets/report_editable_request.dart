// import 'package:flutter/material.dart';

// class ReportEditableRequest extends StatefulWidget {
//   final Map<String, dynamic> item;
//   final String itemType; // 'request', 'finding', or 'observation'
//   final String
//   fieldName; // The field name to display - 'request', 'finding', or 'observation'
//   final Function(Map<String, dynamic>) onUpdate;
//   final Function(Map<String, dynamic>) onDelete;
//   final bool isEditing;

//   const ReportEditableRequest({
//     super.key,
//     required this.item,
//     required this.itemType,
//     required this.fieldName,
//     required this.onUpdate,
//     required this.onDelete,
//     this.isEditing = false,
//   });

//   @override
//   State<ReportEditableRequest> createState() => _ReportEditableRequestState();
// }

// class _ReportEditableRequestState extends State<ReportEditableRequest> {
//   late TextEditingController _textController;
//   late TextEditingController _priceController;
//   late String _currentArgancy;
//   bool _visible = true;

//   @override
//   void initState() {
//     super.initState();
//     _textController = TextEditingController(
//       text: widget.item[widget.fieldName] ?? '',
//     );
//     _priceController = TextEditingController(
//       text: (widget.item['price'] ?? 0).toString(),
//     );
//     _currentArgancy = widget.item['argancy'] ?? 'low';
//     _visible = widget.item['visible'] ?? true;
//   }

//   @override
//   void dispose() {
//     _textController.dispose();
//     _priceController.dispose();
//     super.dispose();
//   }

//   void _saveChanges() {
//     final updatedItem = Map<String, dynamic>.from(widget.item);
//     updatedItem[widget.fieldName] = _textController.text;
//     updatedItem['argancy'] = _currentArgancy;
//     updatedItem['price'] = int.tryParse(_priceController.text) ?? 0;
//     updatedItem['visible'] = _visible;
//     widget.onUpdate(updatedItem);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     Color argancyColor;
//     switch (_currentArgancy) {
//       case 'high':
//         argancyColor = Colors.red;
//         break;
//       case 'medium':
//         argancyColor = Colors.orange;
//         break;
//       default:
//         argancyColor = Colors.green;
//     }

//     if (!widget.isEditing) {
//       // Display mode
//       if (!_visible) {
//         // If marked as not visible, show a minimal view indicating it's hidden from client
//         return Container(
//           margin: const EdgeInsets.only(bottom: 8),
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(
//             color: Colors.grey[100], // Light grey for light theme
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.withAlpha(100)),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.visibility_off, size: 18, color: Colors.grey[500]),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   widget.item[widget.fieldName] ?? '',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: Colors.grey[500],
//                     decoration: TextDecoration.lineThrough,
//                   ),
//                 ),
//               ),
//               Text(
//                 'Hidden from client',
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: Colors.grey[500],
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }

//       // Regular display for visible items
//       return Container(
//         margin: const EdgeInsets.only(bottom: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white, // White for light theme
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: theme.primaryColor.withAlpha(26)),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: 14,
//               height: 14,
//               decoration: BoxDecoration(
//                 color: argancyColor,
//                 shape: BoxShape.circle,
//               ),
//               margin: const EdgeInsets.only(top: 3),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 widget.item[widget.fieldName] ?? '',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: Colors.black, // Black text for light theme
//                 ),
//               ),
//             ),
//             if (widget.item['price'] != null && widget.item['price'] > 0)
//               Text(
//                 '${widget.item['price']} AED',
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: theme.primaryColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//           ],
//         ),
//       );
//     }

//     // Edit mode
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[50], // Very light gray for edit mode
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color:
//               _visible
//                   ? theme.primaryColor.withAlpha(51)
//                   : Colors.grey.withAlpha(100),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               // Urgency selector
//               _buildUrgencySelector(theme),
//               const SizedBox(width: 12),

//               // Visibility toggle
//               IconButton(
//                 icon: Icon(
//                   _visible ? Icons.visibility : Icons.visibility_off,
//                   color:
//                       _visible
//                           ? theme.primaryColor
//                           : Colors.grey, // Use primary color (red) when visible
//                 ),
//                 tooltip: _visible ? 'Hide from client' : 'Show to client',
//                 onPressed: () {
//                   setState(() {
//                     _visible = !_visible;
//                   });
//                   _saveChanges();
//                 },
//               ),

//               const Spacer(),

//               // Delete button
//               IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red),
//                 tooltip: 'Delete',
//                 onPressed: () {
//                   // Show a confirmation dialog
//                   showDialog(
//                     context: context,
//                     builder:
//                         (context) => AlertDialog(
//                           title: const Text('Delete Item'),
//                           content: const Text(
//                             'Are you sure you want to delete this item?',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.of(context).pop(),
//                               child: const Text('CANCEL'),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.of(context).pop();
//                                 widget.onDelete(widget.item);
//                               },
//                               style: TextButton.styleFrom(
//                                 foregroundColor: Colors.red,
//                               ),
//                               child: const Text('DELETE'),
//                             ),
//                           ],
//                         ),
//                   );
//                 },
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // Text field for the request/finding/observation
//           TextField(
//             controller: _textController,
//             style: TextStyle(
//               color:
//                   Colors
//                       .black, // Black text for better visibility in light theme
//               decoration: _visible ? null : TextDecoration.lineThrough,
//             ),
//             decoration: InputDecoration(
//               labelText: 'Description',
//               labelStyle: TextStyle(color: Colors.grey[400]),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey.withAlpha(77)),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: theme.primaryColor),
//               ),
//             ),
//             onChanged: (_) => _saveChanges(),
//           ),

//           const SizedBox(height: 12),

//           // Price field
//           TextField(
//             controller: _priceController,
//             style: TextStyle(
//               color: Colors.black,
//             ), // Black text for better visibility in light theme
//             keyboardType: TextInputType.number,
//             decoration: InputDecoration(
//               labelText: 'Price (AED)',
//               labelStyle: TextStyle(color: Colors.grey[400]),
//               prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey.withAlpha(77)),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: theme.primaryColor),
//               ),
//             ),
//             onChanged: (_) => _saveChanges(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUrgencySelector(ThemeData theme) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _buildUrgencyOption('Low', Colors.green),
//         const SizedBox(width: 8),
//         _buildUrgencyOption('Medium', Colors.orange),
//         const SizedBox(width: 8),
//         _buildUrgencyOption('High', Colors.red),
//       ],
//     );
//   }

//   Widget _buildUrgencyOption(String label, Color color) {
//     final isSelected = _currentArgancy.toLowerCase() == label.toLowerCase();

//     return InkWell(
//       onTap: () {
//         setState(() {
//           _currentArgancy = label.toLowerCase();
//         });
//         _saveChanges();
//       },
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withAlpha(76) : Colors.transparent,
//           border: Border.all(
//             color: isSelected ? color : Colors.grey.withAlpha(77),
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSelected ? color : Colors.grey[400],
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ),
//     );
//   }
// }
