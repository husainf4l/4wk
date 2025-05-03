class Session {
  final String id;
  final Map<String, dynamic> car; // Nested car object
  final Map<String, dynamic> client; // Nested client object
  final String garageId;
  final String status; // OPEN, IN_PROGRESS, COMPLETED, etc.
  final String? clientNoteId; // ID of associated client notes
  final String? inspectionId; // ID of associated inspection
  final String? testDriveId; // ID of associated test drive
  final String? reportId; // ID of associated test drive
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Session({
    required this.id,
    required this.car,
    required this.client,
    required this.garageId,
    required this.status,
    this.clientNoteId,
    this.inspectionId,
    this.testDriveId,
    this.reportId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'car': car,
      'client': client,
      'garageId': garageId,
      'status': status,
      'clientNoteId': clientNoteId,
      'inspectionId': inspectionId,
      'testDriveId': testDriveId,
      'reportId': reportId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map, String id) {
    return Session(
      id: id,
      car: map['car'] ?? {},
      client: map['client'] ?? {},
      garageId: map['garageId'] ?? '',
      status: map['status'] ?? 'UNKNOWN',
      clientNoteId: map['clientNoteId'],
      inspectionId: map['inspectionId'],
      reportId: map['reportId'],
      testDriveId: map['testDriveId'],
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  bool isClosed() {
    return status == 'CLOSED';
  }
}
