import 'package:cloud_firestore/cloud_firestore.dart';

class Garage {
  final String id;
  final String garageName;
  final String? logoUrl;
  final String? openAiKey;
  final String? quickBooksKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Garage({
    required this.id,
    required this.garageName,
    this.logoUrl,
    this.openAiKey,
    this.quickBooksKey,
    this.createdAt,
    this.updatedAt,
  });

  // Create a Garage from Firestore document
  factory Garage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Garage(
      id: doc.id,
      garageName: data['garageName'] ?? '',
      logoUrl: data['logoUrl'],
      openAiKey: data['openAiKey'],
      quickBooksKey: data['quickBooksKey'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Convert Garage to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'garageName': garageName,
      'logoUrl': logoUrl,
      'openAiKey': openAiKey,
      'quickBooksKey': quickBooksKey,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a copy of Garage with updated fields
  Garage copyWith({
    String? garageName,
    String? logoUrl,
    String? openAiKey,
    String? quickBooksKey,
  }) {
    return Garage(
      id: id,
      garageName: garageName ?? this.garageName,
      logoUrl: logoUrl ?? this.logoUrl,
      openAiKey: openAiKey ?? this.openAiKey,
      quickBooksKey: quickBooksKey ?? this.quickBooksKey,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Create an empty garage
  factory Garage.empty() {
    return Garage(id: '', garageName: '');
  }

  // Check if garage is empty
  bool get isEmpty => id.isEmpty;

  // Check if garage is not empty
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'Garage(id: $id, garageName: $garageName)';
  }
}
