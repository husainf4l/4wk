// import 'package:flutter/material.dart';

// enum BannerType { info, success, warning, error }

// class StatusBannerWidget extends StatelessWidget {
//   final String message;
//   final BannerType type;
//   final VoidCallback? onActionPressed;
//   final String? actionText;
//   final bool isDismissible;

//   const StatusBannerWidget({
//     super.key,
//     required this.message,
//     this.type = BannerType.info,
//     this.onActionPressed,
//     this.actionText,
//     this.isDismissible = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8.0),
//       decoration: BoxDecoration(
//         color: _getBackgroundColor(),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: _getBorderColor()),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       child: Row(
//         children: [
//           Icon(_getIcon(), color: _getIconColor(), size: 20),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               message,
//               style: TextStyle(color: _getTextColor(), fontSize: 13),
//             ),
//           ),
//           if (actionText != null && onActionPressed != null) ...[
//             const SizedBox(width: 8),
//             TextButton(
//               onPressed: onActionPressed,
//               style: TextButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 4,
//                 ),
//                 minimumSize: Size.zero,
//                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               ),
//               child: Text(
//                 actionText!,
//                 style: TextStyle(
//                   color: _getIconColor(),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//           ],
//           if (isDismissible)
//             GestureDetector(
//               onTap: () {
//                 // Implement dismissal logic here, usually by setting state in parent
//                 if (onActionPressed != null) {
//                   onActionPressed!();
//                 }
//               },
//               child: Padding(
//                 padding: const EdgeInsets.only(left: 8),
//                 child: Icon(
//                   Icons.close,
//                   size: 16,
//                   color: _getIconColor().withAlpha(179),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Color _getBackgroundColor() {
//     switch (type) {
//       case BannerType.info:
//         return Colors.blue.shade50;
//       case BannerType.success:
//         return Colors.green.shade50;
//       case BannerType.warning:
//         return Colors.amber.shade50;
//       case BannerType.error:
//         return Colors.red.shade50;
//     }
//   }

//   Color _getBorderColor() {
//     switch (type) {
//       case BannerType.info:
//         return Colors.blue.shade200;
//       case BannerType.success:
//         return Colors.green.shade200;
//       case BannerType.warning:
//         return Colors.amber.shade200;
//       case BannerType.error:
//         return Colors.red.shade200;
//     }
//   }

//   Color _getIconColor() {
//     switch (type) {
//       case BannerType.info:
//         return Colors.blue.shade700;
//       case BannerType.success:
//         return Colors.green.shade700;
//       case BannerType.warning:
//         return Colors.amber.shade700;
//       case BannerType.error:
//         return Colors.red.shade700;
//     }
//   }

//   Color _getTextColor() {
//     switch (type) {
//       case BannerType.info:
//         return Colors.blue.shade900;
//       case BannerType.success:
//         return Colors.green.shade900;
//       case BannerType.warning:
//         return Colors.amber.shade900;
//       case BannerType.error:
//         return Colors.red.shade900;
//     }
//   }

//   IconData _getIcon() {
//     switch (type) {
//       case BannerType.info:
//         return Icons.info_outline;
//       case BannerType.success:
//         return Icons.check_circle_outline;
//       case BannerType.warning:
//         return Icons.warning_amber;
//       case BannerType.error:
//         return Icons.error_outline;
//     }
//   }
// }
