import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final String? garageId;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  User({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.garageId,
    this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  // Create a User from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return User(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      garageId: data['garageId'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      lastLoginAt:
          data['lastLoginAt'] != null
              ? (data['lastLoginAt'] as Timestamp).toDate()
              : null,
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert User to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'garageId': garageId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
    };
  }

  // Create a copy of User with updated fields
  User copyWith({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? garageId,
    bool? isActive,
  }) {
    return User(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      garageId: garageId ?? this.garageId,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Create an empty user
  factory User.empty() {
    return User(uid: '', email: '');
  }

  // Check if user is empty
  bool get isEmpty => uid.isEmpty;

  // Check if user is not empty
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, displayName: $displayName)';
  }
}
