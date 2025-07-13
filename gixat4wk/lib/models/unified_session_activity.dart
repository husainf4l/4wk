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

  Map<String, dynamic> toMap() {
    final map = {
      'sessionId': sessionId,
      'clientId': clientId,
      'carId': carId,
      'garageId': garageId,
      'stage': stage.toString().split('.').last,
      'notes': notes,
      'images': images,
      'videos': videos,
      'requests': requests,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };

    // Add stage-specific fields only if they exist
    if (findings != null) map['findings'] = findings;
    if (observations != null) map['observations'] = observations;
    if (reportData != null) map['reportData'] = reportData;

    return map;
  }

  factory UnifiedSessionActivity.fromMap(Map<String, dynamic> map, String id) {
    return UnifiedSessionActivity(
      id: id,
      sessionId: map['sessionId'] ?? '',
      clientId: map['clientId'] ?? '',
      carId: map['carId'] ?? '',
      garageId: map['garageId'] ?? '',
      stage: ActivityStage.values.firstWhere(
        (s) => s.toString().split('.').last == map['stage'],
        orElse: () => ActivityStage.clientNotes,
      ),
      notes: map['notes'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      videos: List<String>.from(map['videos'] ?? []),
      requests: List<Map<String, dynamic>>.from(map['requests'] ?? []),
      findings:
          map['findings'] != null
              ? List<Map<String, dynamic>>.from(map['findings'])
              : null,
      observations:
          map['observations'] != null
              ? List<Map<String, dynamic>>.from(map['observations'])
              : null,
      reportData: map['reportData'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      status: ActivityStatus.values.firstWhere(
        (s) => s.toString().split('.').last == map['status'],
        orElse: () => ActivityStatus.draft,
      ),
    );
  }

  // Helper methods for different stages
  bool isClientNotes() => stage == ActivityStage.clientNotes;
  bool isInspection() => stage == ActivityStage.inspection;
  bool isTestDrive() => stage == ActivityStage.testDrive;
  bool isReport() => stage == ActivityStage.report;

  // Create specialized instances for each stage
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
}

enum ActivityStage { clientNotes, inspection, testDrive, report }

enum ActivityStatus { draft, completed, reviewed }
