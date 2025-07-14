import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the different stages of a session activity
enum ActivityStage { clientNotes, inspection, testDrive, report, jobCard }

/// Represents the status of an activity
enum ActivityStatus { draft, completed, reviewed }

/// Extension to provide user-friendly names for ActivityStage
extension ActivityStageExtension on ActivityStage {
  String get displayName {
    switch (this) {
      case ActivityStage.clientNotes:
        return 'Client Notes';
      case ActivityStage.inspection:
        return 'Inspection';
      case ActivityStage.testDrive:
        return 'Test Drive';
      case ActivityStage.report:
        return 'Report';
      case ActivityStage.jobCard:
        return 'Job Card';
    }
  }

  String get firestoreValue => toString().split('.').last;
}

/// Extension to provide user-friendly names for ActivityStatus
extension ActivityStatusExtension on ActivityStatus {
  String get displayName {
    switch (this) {
      case ActivityStatus.draft:
        return 'Draft';
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.reviewed:
        return 'Reviewed';
    }
  }

  String get firestoreValue => toString().split('.').last;
}

/// Unified model for all session activities across different stages
class UnifiedSessionActivity {
  final String id;
  final String sessionId;
  final String clientId;
  final String carId;
  final String garageId;

  // Stage/Type of activity
  final ActivityStage stage; // CLIENT_NOTES, INSPECTION, TEST_DRIVE, REPORT

  // Common fields for all stages
  final String notes;
  final List<String> images;
  final List<String> videos;
  final List<Map<String, dynamic>> requests;

  // Stage-specific fields (optional)
  final List<Map<String, dynamic>>? findings; // For INSPECTION
  final List<Map<String, dynamic>>? observations; // For TEST_DRIVE
  final Map<String, dynamic>? reportData; // For REPORT

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final ActivityStatus status; // DRAFT, COMPLETED, REVIEWED

  UnifiedSessionActivity({
    required this.id,
    required this.sessionId,
    required this.clientId,
    required this.carId,
    required this.garageId,
    required this.stage,
    required this.notes,
    required this.images,
    required this.videos,
    required this.requests,
    this.findings,
    this.observations,
    this.reportData,
    DateTime? createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.status = ActivityStatus.draft,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Converts the activity to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sessionId': sessionId,
      'clientId': clientId,
      'carId': carId,
      'garageId': garageId,
      'stage': stage.firestoreValue,
      'notes': notes,
      'images': images,
      'videos': videos,
      'requests': requests,
      'status': status.firestoreValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };

    // Add stage-specific fields only if they exist
    if (findings != null) map['findings'] = findings;
    if (observations != null) map['observations'] = observations;
    if (reportData != null) map['reportData'] = reportData;

    return map;
  }

  /// Creates an activity instance from a Map (typically from Firestore)
  factory UnifiedSessionActivity.fromMap(Map<String, dynamic> map, String id) {
    return UnifiedSessionActivity(
      id: id,
      sessionId: map['sessionId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      carId: map['carId'] as String? ?? '',
      garageId: map['garageId'] as String? ?? '',
      stage: _parseActivityStage(map['stage'] as String?),
      notes: map['notes'] as String? ?? '',
      images: List<String>.from(map['images'] as List? ?? <String>[]),
      videos: List<String>.from(map['videos'] as List? ?? <String>[]),
      requests: List<Map<String, dynamic>>.from(
        map['requests'] as List? ?? <Map<String, dynamic>>[],
      ),
      findings:
          map['findings'] != null
              ? List<Map<String, dynamic>>.from(map['findings'] as List)
              : null,
      observations:
          map['observations'] != null
              ? List<Map<String, dynamic>>.from(map['observations'] as List)
              : null,
      reportData: map['reportData'] as Map<String, dynamic>?,
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(map['updatedAt']),
      createdBy: map['createdBy'] as String?,
      updatedBy: map['updatedBy'] as String?,
      status: _parseActivityStatus(map['status'] as String?),
    );
  }

  /// Creates an activity instance from a Firestore document snapshot
  factory UnifiedSessionActivity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists || snapshot.data() == null) {
      throw ArgumentError('Document does not exist or has no data');
    }

    return UnifiedSessionActivity.fromMap(snapshot.data()!, snapshot.id);
  }

  /// Helper method to parse ActivityStage from string
  static ActivityStage _parseActivityStage(String? stageString) {
    if (stageString == null) return ActivityStage.clientNotes;

    return ActivityStage.values.firstWhere(
      (stage) => stage.firestoreValue == stageString,
      orElse: () => ActivityStage.clientNotes,
    );
  }

  /// Helper method to parse ActivityStatus from string
  static ActivityStatus _parseActivityStatus(String? statusString) {
    if (statusString == null) return ActivityStatus.draft;

    return ActivityStatus.values.firstWhere(
      (status) => status.firestoreValue == statusString,
      orElse: () => ActivityStatus.draft,
    );
  }

  /// Helper method to parse Timestamp to DateTime
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  // Helper methods for different stages
  bool get isClientNotes => stage == ActivityStage.clientNotes;
  bool get isInspection => stage == ActivityStage.inspection;
  bool get isTestDrive => stage == ActivityStage.testDrive;
  bool get isReport => stage == ActivityStage.report;
  bool get isJobCard => stage == ActivityStage.jobCard;

  /// Creates a specialized instance for client notes
  static UnifiedSessionActivity forClientNotes({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> requests,
    List<String> images = const [],
    List<String> videos = const [],
    String? createdBy,
  }) {
    return UnifiedSessionActivity(
      id: '', // Will be set by Firestore
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      stage: ActivityStage.clientNotes,
      notes: notes,
      images: images,
      videos: videos,
      requests: requests,
      createdBy: createdBy,
    );
  }

  static UnifiedSessionActivity forInspection({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> findings,
    List<String> images = const [],
    List<String> videos = const [],
    List<Map<String, dynamic>> requests = const [],
    String? createdBy,
  }) {
    return UnifiedSessionActivity(
      id: '', // Will be set by Firestore
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      stage: ActivityStage.inspection,
      notes: notes,
      images: images,
      videos: videos,
      requests: requests,
      findings: findings,
      createdBy: createdBy,
    );
  }

  static UnifiedSessionActivity forTestDrive({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> observations,
    List<String> images = const [],
    List<String> videos = const [],
    List<Map<String, dynamic>> requests = const [],
    String? createdBy,
  }) {
    return UnifiedSessionActivity(
      id: '', // Will be set by Firestore
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      stage: ActivityStage.testDrive,
      notes: notes,
      images: images,
      videos: videos,
      requests: requests,
      observations: observations,
      createdBy: createdBy,
    );
  }

  static UnifiedSessionActivity forReport({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required Map<String, dynamic> reportData,
    List<String> images = const [],
    List<String> videos = const [],
    List<Map<String, dynamic>> requests = const [],
    String? createdBy,
  }) {
    return UnifiedSessionActivity(
      id: '', // Will be set by Firestore
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      stage: ActivityStage.report,
      notes: notes,
      images: images,
      videos: videos,
      requests: requests,
      reportData: reportData,
      createdBy: createdBy,
    );
  }

  /// Creates a specialized instance for job card activities
  static UnifiedSessionActivity forJobCard({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> jobCardItems,
    List<String> images = const [],
    List<String> videos = const [],
    String? createdBy,
  }) {
    return UnifiedSessionActivity(
      id: '', // Will be set by Firestore
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      stage: ActivityStage.jobCard,
      notes: notes,
      images: images,
      videos: videos,
      requests: jobCardItems,
      createdBy: createdBy,
    );
  }

  // Copy with method for updates
  UnifiedSessionActivity copyWith({
    String? notes,
    List<String>? images,
    List<String>? videos,
    List<Map<String, dynamic>>? requests,
    List<Map<String, dynamic>>? findings,
    List<Map<String, dynamic>>? observations,
    Map<String, dynamic>? reportData,
    ActivityStatus? status,
    String? createdBy,
    String? updatedBy,
  }) {
    return UnifiedSessionActivity(
      id: id,
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      stage: stage,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      requests: requests ?? this.requests,
      findings: findings ?? this.findings,
      observations: observations ?? this.observations,
      reportData: reportData ?? this.reportData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UnifiedSessionActivity &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.stage == stage;
  }

  @override
  int get hashCode => Object.hash(id, sessionId, stage);

  @override
  String toString() {
    return 'UnifiedSessionActivity(id: $id, sessionId: $sessionId, stage: ${stage.displayName}, notes: ${notes.length} chars)';
  }
}
