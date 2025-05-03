class ClientNote {
  final String id;
  final String clientId;
  final String carId;
  final String garageId;
  final String sessionId;
  final String notes;
  final List<Map<String, dynamic>> clientRequests;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClientNote({
    required this.id,
    required this.clientId,
    required this.carId,
    required this.garageId,
    required this.sessionId,
    required this.notes,
    required this.clientRequests,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'carId': carId,
      'garageId': garageId,
      'sessionId': sessionId,
      'notes': notes,
      'clientRequests': clientRequests,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ClientNote.fromMap(Map<String, dynamic> map, String id) {
    return ClientNote(
      id: id,
      clientId: map['clientId'] ?? '',
      carId: map['carId'] ?? '',
      garageId: map['garageId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      notes: map['notes'] ?? '',
      clientRequests: List<Map<String, dynamic>>.from(
        map['clientRequests'] ?? [],
      ),
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : null,
    );
  }
}
