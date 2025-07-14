// import 'package:flutter/material.dart';

// class ActionButtonBar extends StatelessWidget {
//   final List<ActionButton> actions;
//   final EdgeInsetsGeometry padding;
//   final bool elevated;
//   final Color? backgroundColor;

//   const ActionButtonBar({
//     super.key,
//     required this.actions,
//     this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//     this.elevated = true,
//     this.backgroundColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: padding,
//       decoration:
//           elevated
//               ? BoxDecoration(
//                 color: backgroundColor ?? theme.scaffoldBackgroundColor,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withAlpha(13),
//                     spreadRadius: 1,
//                     blurRadius: 5,
//                     offset: const Offset(0, -3),
//                   ),
//                 ],
//               )
//               : BoxDecoration(color: backgroundColor),
//       child: SafeArea(
//         top: false,
//         child: Row(
//           mainAxisAlignment:
//               actions.length <= 2
//                   ? MainAxisAlignment.spaceEvenly
//                   : MainAxisAlignment.spaceBetween,
//           children:
//               actions.map((action) {
//                 return Expanded(
//                   flex: action.flex,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                     child: _buildButton(context, action),
//                   ),
//                 );
//               }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildButton(BuildContext context, ActionButton action) {
//     final theme = Theme.of(context);

//     // Primary filled button
//     if (action.isPrimary) {
//       return ElevatedButton(
//         onPressed: action.onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: action.color ?? theme.primaryColor,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 12.0),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (action.icon != null) ...[
//               Icon(action.icon, size: 18),
//               const SizedBox(width: 8),
//             ],
//             Text(action.label),
//           ],
//         ),
//       );
//     }

//     // Secondary outlined button
//     return OutlinedButton(
//       onPressed: action.onPressed,
//       style: OutlinedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(vertical: 12.0),
//         side: BorderSide(color: action.color ?? theme.primaryColor),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (action.icon != null) ...[
//             Icon(action.icon, size: 18),
//             const SizedBox(width: 8),
//           ],
//           Text(action.label),
//         ],
//       ),
//     );
//   }
// }

// class ActionButton {
//   final String label;
//   final VoidCallback? onPressed;
//   final IconData? icon;
//   final bool isPrimary;
//   final Color? color;
//   final int flex;

//   const ActionButton({
//     required this.label,
//     required this.onPressed,
//     this.icon,
//     this.isPrimary = false,
//     this.color,
//     this.flex = 1,
//   });

//   // Factory constructor for primary action buttons
//   factory ActionButton.primary({
//     required String label,
//     required VoidCallback? onPressed,
//     IconData? icon,
//     Color? color,
//     int flex = 1,
//   }) {
//     return ActionButton(
//       label: label,
//       onPressed: onPressed,
//       icon: icon,
//       isPrimary: true,
//       color: color,
//       flex: flex,
//     );
//   }

//   // Factory constructor for secondary action buttons
//   factory ActionButton.secondary({
//     required String label,
//     required VoidCallback? onPressed,
//     IconData? icon,
//     Color? color,
//     int flex = 1,
//   }) {
//     return ActionButton(
//       label: label,
//       onPressed: onPressed,
//       icon: icon,
//       isPrimary: false,
//       color: color,
//       flex: flex,
//     );
//   }
// }
