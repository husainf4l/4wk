// class Activity {
//   final String id;
//   final String sessionId;
//   final String
//   type; // 'note', 'inspection', 'test_drive', 'job_order', 'status_change', etc.
//   final String title;
//   final String? description;
//   final DateTime timestamp;
//   final String? userId;
//   final String? userName;

//   Activity({
//     required this.id,
//     required this.sessionId,
//     required this.type,
//     required this.title,
//     this.description,
//     required this.timestamp,
//     this.userId,
//     this.userName,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'sessionId': sessionId,
//       'type': type,
//       'title': title,
//       'description': description,
//       'timestamp': timestamp,
//       'userId': userId,
//       'userName': userName,
//     };
//   }

//   factory Activity.fromMap(Map<String, dynamic> map, String id) {
//     return Activity(
//       id: id,
//       sessionId: map['sessionId'] ?? '',
//       type: map['type'] ?? '',
//       title: map['title'] ?? '',
//       description: map['description'],
//       timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
//       userId: map['userId'],
//       userName: map['userName'],
//     );
//   }
// }
