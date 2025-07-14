// class ChatMessage {
//   final String id;
//   final String text;
//   final DateTime timestamp;
//   final bool isUserMessage;
//   final String sessionId;
//   final Map<String, dynamic>?
//   databaseInfo; // Added to store associated vehicle/client data

//   ChatMessage({
//     required this.id,
//     required this.text,
//     required this.timestamp,
//     required this.isUserMessage,
//     required this.sessionId,
//     this.databaseInfo,
//   });

//   // Convert to map for storage
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'text': text,
//       'timestamp': timestamp.millisecondsSinceEpoch,
//       'isUserMessage': isUserMessage,
//       'sessionId': sessionId,
//       'databaseInfo': databaseInfo,
//     };
//   }

//   // Create from map (for retrieving from storage)
//   factory ChatMessage.fromMap(Map<String, dynamic> map) {
//     return ChatMessage(
//       id: map['id'] ?? '',
//       text: map['text'] ?? '',
//       timestamp: DateTime.fromMillisecondsSinceEpoch(
//         map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
//       ),
//       isUserMessage: map['isUserMessage'] ?? false,
//       sessionId: map['sessionId'] ?? '',
//       databaseInfo:
//           map['databaseInfo'] != null
//               ? Map<String, dynamic>.from(map['databaseInfo'])
//               : null,
//     );
//   }
// }

// class ChatSession {
//   final String id;
//   final String name;
//   final String avatarUrl;
//   final DateTime lastMessageTime;
//   final String lastMessageText;
//   final int unreadCount;

//   ChatSession({
//     required this.id,
//     required this.name,
//     this.avatarUrl = '',
//     required this.lastMessageTime,
//     required this.lastMessageText,
//     this.unreadCount = 0,
//   });

//   // To map for caching/storage
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'avatar': avatarUrl,
//       'time': lastMessageTime.millisecondsSinceEpoch,
//       'lastMessage': lastMessageText,
//       'unread': unreadCount,
//     };
//   }

//   // Create from map
//   factory ChatSession.fromMap(Map<String, dynamic> map) {
//     return ChatSession(
//       id: map['id'] ?? '',
//       name: map['name'] ?? '',
//       avatarUrl: map['avatar'] ?? '',
//       lastMessageTime:
//           map['time'] is DateTime
//               ? map['time']
//               : DateTime.fromMillisecondsSinceEpoch(
//                 map['time'] ?? DateTime.now().millisecondsSinceEpoch,
//               ),
//       lastMessageText: map['lastMessage'] ?? '',
//       unreadCount: map['unread'] ?? 0,
//     );
//   }
// }
