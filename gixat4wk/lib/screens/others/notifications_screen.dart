// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class NotificationsScreen extends StatelessWidget {
//   const NotificationsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     // Sample notifications data - in a real app, this would come from a database
//     final List<Map<String, dynamic>> notifications = [
//       {
//         'id': '1',
//         'title': 'Maintenance Reminder',
//         'message': 'Your vehicle is due for regular maintenance next week.',
//         'type': 'reminder',
//         'isRead': false,
//         'time': DateTime.now().subtract(const Duration(hours: 2)),
//       },
//       {
//         'id': '2',
//         'title': 'Appointment Confirmation',
//         'message':
//             'Your service appointment has been confirmed for tomorrow at 10:00 AM.',
//         'type': 'appointment',
//         'isRead': true,
//         'time': DateTime.now().subtract(const Duration(days: 1)),
//       },
//       {
//         'id': '3',
//         'title': 'Promotion',
//         'message': 'Special discount on oil changes this weekend! Book now.',
//         'type': 'promotion',
//         'isRead': false,
//         'time': DateTime.now().subtract(const Duration(days: 2)),
//       },
//       {
//         'id': '4',
//         'title': 'System Update',
//         'message': 'The app has been updated with new features.',
//         'type': 'system',
//         'isRead': true,
//         'time': DateTime.now().subtract(const Duration(days: 4)),
//       },
//     ];

//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Notifications',
//                   style: theme.textTheme.headlineMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 TextButton.icon(
//                   icon: const Icon(Icons.done_all),
//                   label: const Text('Mark all as read'),
//                   onPressed: () {
//                     Get.snackbar(
//                       'Success',
//                       'All notifications marked as read',
//                       snackPosition: SnackPosition.BOTTOM,
//                     );
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child:
//                   notifications.isEmpty
//                       ? _buildEmptyState()
//                       : ListView.builder(
//                         itemCount: notifications.length,
//                         itemBuilder: (context, index) {
//                           final notification = notifications[index];
//                           return _buildNotificationCard(
//                             context,
//                             notification,
//                             theme,
//                           );
//                         },
//                       ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.notifications_off_outlined,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No notifications',
//             style: TextStyle(color: Colors.grey[600], fontSize: 18),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'We\'ll notify you when something new arrives',
//             style: TextStyle(color: Colors.grey[500]),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationCard(
//     BuildContext context,
//     Map<String, dynamic> notification,
//     ThemeData theme,
//   ) {
//     IconData notificationIcon;
//     Color iconColor;

//     // Determine icon and color based on notification type
//     switch (notification['type']) {
//       case 'reminder':
//         notificationIcon = Icons.calendar_today;
//         iconColor = Colors.blue;
//         break;
//       case 'appointment':
//         notificationIcon = Icons.schedule;
//         iconColor = Colors.green;
//         break;
//       case 'promotion':
//         notificationIcon = Icons.local_offer;
//         iconColor = Colors.orange;
//         break;
//       default:
//         notificationIcon = Icons.system_update;
//         iconColor = Colors.purple;
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 1,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color:
//           notification['isRead']
//               ? theme.cardColor
//               : theme.primaryColor.withAlpha(13),
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(16),
//         leading: CircleAvatar(
//           backgroundColor: iconColor.withAlpha(51),
//           child: Icon(notificationIcon, color: iconColor),
//         ),
//         title: Text(
//           notification['title'],
//           style: theme.textTheme.titleMedium?.copyWith(
//             fontWeight:
//                 notification['isRead'] ? FontWeight.normal : FontWeight.bold,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 4),
//             Text(notification['message']),
//             const SizedBox(height: 8),
//             Text(
//               _getTimeAgo(notification['time']),
//               style: TextStyle(color: Colors.grey[600], fontSize: 12),
//             ),
//           ],
//         ),
//         onTap: () {
//           // Mark as read and show details
//           Get.snackbar(
//             notification['title'],
//             'Notification has been marked as read',
//             snackPosition: SnackPosition.BOTTOM,
//           );
//         },
//       ),
//     );
//   }

//   String _getTimeAgo(DateTime time) {
//     final duration = DateTime.now().difference(time);

//     if (duration.inMinutes < 1) {
//       return 'Just now';
//     } else if (duration.inHours < 1) {
//       return '${duration.inMinutes}m ago';
//     } else if (duration.inDays < 1) {
//       return '${duration.inHours}h ago';
//     } else if (duration.inDays < 30) {
//       return '${duration.inDays}d ago';
//     } else {
//       return '${(duration.inDays / 30).floor()}mo ago';
//     }
//   }
// }
