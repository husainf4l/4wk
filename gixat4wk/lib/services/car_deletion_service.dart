import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum CarStatus {
  active,
  inactive,
  deleted,
  suspended,
  sold,
  totaled,
}

class CarDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> softDeleteCar({
    required String carId,
    required String deletedBy,
    String? reason,
    CarStatus status = CarStatus.deleted,
  }) async {
    try {
      debugPrint('Starting soft delete for car: $carId');
      
      // Start batch operation
      final batch = _firestore.batch();
      final deleteTime = DateTime.now();
      
      // Update car status
      await _updateCarStatus(carId, status, deleteTime, deletedBy, reason, batch);
      
      // Update related sessions
      await _updateRelatedSessions(carId, status, deleteTime, deletedBy, batch);
      
      // Update related job orders
      await _updateRelatedJobOrders(carId, status, deleteTime, deletedBy, batch);
      
      // Update related session activities
      await _updateRelatedSessionActivities(carId, status, deleteTime, deletedBy, batch);
      
      // Commit all changes
      await batch.commit();
      
      debugPrint('Successfully soft deleted car: $carId');
      return true;
    } catch (e) {
      debugPrint('Error soft deleting car: $e');
      return false;
    }
  }

  static Future<bool> restoreCar({
    required String carId,
    required String restoredBy,
    String? reason,
  }) async {
    try {
      debugPrint('Starting restore for car: $carId');
      
      final batch = _firestore.batch();
      final restoreTime = DateTime.now();
      
      // Restore car status
      await _updateCarStatus(
        carId, 
        CarStatus.active, 
        restoreTime, 
        restoredBy, 
        reason ?? 'Car restored',
        batch,
      );
      
      // Note: Sessions and job orders are not automatically restored
      // They need to be manually reviewed and restored if needed
      
      await batch.commit();
      
      debugPrint('Successfully restored car: $carId');
      return true;
    } catch (e) {
      debugPrint('Error restoring car: $e');
      return false;
    }
  }

  static Future<void> _updateCarStatus(
    String carId,
    CarStatus status,
    DateTime timestamp,
    String actionBy,
    String? reason,
    WriteBatch batch,
  ) async {
    final carDoc = _firestore.collection('cars').doc(carId);
    
    final updates = {
      'status': status.name,
      'isDeleted': status == CarStatus.deleted,
      'isActive': status == CarStatus.active,
      'isSold': status == CarStatus.sold,
      'isTotaled': status == CarStatus.totaled,
      'lastStatusChange': timestamp.millisecondsSinceEpoch,
      'statusChangedBy': actionBy,
      'statusChangeReason': reason ?? 'Status changed to ${status.name}',
      'lastUpdated': timestamp.millisecondsSinceEpoch,
    };
    
    // Add deletion-specific fields
    if (status == CarStatus.deleted) {
      updates['deletedAt'] = timestamp.millisecondsSinceEpoch;
      updates['deletedBy'] = actionBy;
      updates['deletionReason'] = reason ?? 'Car deleted';
    }
    
    // Add restoration-specific fields
    if (status == CarStatus.active) {
      updates['restoredAt'] = timestamp.millisecondsSinceEpoch;
      updates['restoredBy'] = actionBy;
      updates['restorationReason'] = reason ?? 'Car restored';
    }
    
    // Add sold-specific fields
    if (status == CarStatus.sold) {
      updates['soldAt'] = timestamp.millisecondsSinceEpoch;
      updates['soldBy'] = actionBy;
      updates['saleReason'] = reason ?? 'Car sold';
    }
    
    // Add totaled-specific fields
    if (status == CarStatus.totaled) {
      updates['totaledAt'] = timestamp.millisecondsSinceEpoch;
      updates['totaledBy'] = actionBy;
      updates['totaledReason'] = reason ?? 'Car totaled';
    }
    
    batch.update(carDoc, updates);
  }

  static Future<void> _updateRelatedSessions(
    String carId,
    CarStatus status,
    DateTime timestamp,
    String actionBy,
    WriteBatch batch,
  ) async {
    final sessionsQuery = await _firestore
        .collection('sessions')
        .where('carId', isEqualTo: carId)
        .get();
    
    for (final doc in sessionsQuery.docs) {
      final updates = {
        'carStatus': status.name,
        'isCarDeleted': status == CarStatus.deleted,
        'isCarSold': status == CarStatus.sold,
        'isCarTotaled': status == CarStatus.totaled,
        'carStatusChangedAt': timestamp.millisecondsSinceEpoch,
        'carStatusChangedBy': actionBy,
        'lastUpdated': timestamp.millisecondsSinceEpoch,
      };
      
      batch.update(doc.reference, updates);
    }
  }

  static Future<void> _updateRelatedJobOrders(
    String carId,
    CarStatus status,
    DateTime timestamp,
    String actionBy,
    WriteBatch batch,
  ) async {
    // Get job orders through carData field
    final jobOrdersQuery = await _firestore
        .collection('jobOrders')
        .where('carData.id', isEqualTo: carId)
        .get();
    
    for (final doc in jobOrdersQuery.docs) {
      final updates = {
        'carStatus': status.name,
        'isCarDeleted': status == CarStatus.deleted,
        'isCarSold': status == CarStatus.sold,
        'isCarTotaled': status == CarStatus.totaled,
        'carStatusChangedAt': timestamp.millisecondsSinceEpoch,
        'carStatusChangedBy': actionBy,
        'lastUpdated': timestamp.millisecondsSinceEpoch,
      };
      
      batch.update(doc.reference, updates);
    }
  }

  static Future<void> _updateRelatedSessionActivities(
    String carId,
    CarStatus status,
    DateTime timestamp,
    String actionBy,
    WriteBatch batch,
  ) async {
    final activitiesQuery = await _firestore
        .collection('session_activities')
        .where('carId', isEqualTo: carId)
        .get();
    
    for (final doc in activitiesQuery.docs) {
      final updates = {
        'carStatus': status.name,
        'isCarDeleted': status == CarStatus.deleted,
        'isCarSold': status == CarStatus.sold,
        'isCarTotaled': status == CarStatus.totaled,
        'carStatusChangedAt': timestamp.millisecondsSinceEpoch,
        'carStatusChangedBy': actionBy,
        'lastUpdated': timestamp.millisecondsSinceEpoch,
      };
      
      batch.update(doc.reference, updates);
    }
  }

  static Future<List<Map<String, dynamic>>> getDeletedCars({
    int limit = 50,
    String? lastDocumentId,
  }) async {
    Query query = _firestore
        .collection('cars')
        .where('isDeleted', isEqualTo: true)
        .orderBy('deletedAt', descending: true);
    
    if (limit > 0) {
      query = query.limit(limit);
    }
    
    if (lastDocumentId != null) {
      final lastDoc = await _firestore
          .collection('cars')
          .doc(lastDocumentId)
          .get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getCarsByStatus(
    CarStatus status, {
    int limit = 50,
    String? lastDocumentId,
  }) async {
    Query query = _firestore
        .collection('cars')
        .where('status', isEqualTo: status.name)
        .orderBy('lastStatusChange', descending: true);
    
    if (limit > 0) {
      query = query.limit(limit);
    }
    
    if (lastDocumentId != null) {
      final lastDoc = await _firestore
          .collection('cars')
          .doc(lastDocumentId)
          .get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<Map<String, dynamic>?> getCarDeletionInfo(String carId) async {
    try {
      final carDoc = await _firestore
          .collection('cars')
          .doc(carId)
          .get();
      
      if (!carDoc.exists) {
        return null;
      }
      
      final data = carDoc.data() as Map<String, dynamic>;
      
      // Get related data counts
      final sessionsCount = await _getRelatedSessionsCount(carId);
      final jobOrdersCount = await _getRelatedJobOrdersCount(carId);
      final activitiesCount = await _getRelatedActivitiesCount(carId);
      
      return {
        'car': data,
        'relatedData': {
          'sessions': sessionsCount,
          'jobOrders': jobOrdersCount,
          'activities': activitiesCount,
        },
      };
    } catch (e) {
      debugPrint('Error getting car deletion info: $e');
      return null;
    }
  }

  static Future<int> _getRelatedSessionsCount(String carId) async {
    final sessionsQuery = await _firestore
        .collection('sessions')
        .where('carId', isEqualTo: carId)
        .get();
    return sessionsQuery.docs.length;
  }

  static Future<int> _getRelatedJobOrdersCount(String carId) async {
    final jobOrdersQuery = await _firestore
        .collection('jobOrders')
        .where('carData.id', isEqualTo: carId)
        .get();
    return jobOrdersQuery.docs.length;
  }

  static Future<int> _getRelatedActivitiesCount(String carId) async {
    final activitiesQuery = await _firestore
        .collection('session_activities')
        .where('carId', isEqualTo: carId)
        .get();
    return activitiesQuery.docs.length;
  }

  static Query getActiveCarsQuery() {
    return _firestore
        .collection('cars')
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true);
  }

  static Query getAllCarsQuery({bool includeDeleted = false}) {
    if (includeDeleted) {
      return _firestore.collection('cars');
    }
    return _firestore
        .collection('cars')
        .where('isDeleted', isEqualTo: false);
  }

  static Stream<QuerySnapshot> getCarsStream({
    bool includeDeleted = false,
    bool includeSold = false,
    bool includeTotaled = false,
    CarStatus? filterByStatus,
  }) {
    Query query = _firestore.collection('cars');
    
    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
    
    if (!includeSold) {
      query = query.where('isSold', isEqualTo: false);
    }
    
    if (!includeTotaled) {
      query = query.where('isTotaled', isEqualTo: false);
    }
    
    if (filterByStatus != null) {
      query = query.where('status', isEqualTo: filterByStatus.name);
    }
    
    return query.snapshots();
  }

  static String getStatusDisplayName(CarStatus status) {
    switch (status) {
      case CarStatus.active:
        return 'Active';
      case CarStatus.inactive:
        return 'Inactive';
      case CarStatus.deleted:
        return 'Deleted';
      case CarStatus.suspended:
        return 'Suspended';
      case CarStatus.sold:
        return 'Sold';
      case CarStatus.totaled:
        return 'Totaled';
    }
  }

  static Color getStatusColor(CarStatus status) {
    switch (status) {
      case CarStatus.active:
        return const Color(0xFF4CAF50); // Green
      case CarStatus.inactive:
        return const Color(0xFFFF9800); // Orange
      case CarStatus.deleted:
        return const Color(0xFFF44336); // Red
      case CarStatus.suspended:
        return const Color(0xFF9C27B0); // Purple
      case CarStatus.sold:
        return const Color(0xFF2196F3); // Blue
      case CarStatus.totaled:
        return const Color(0xFF795548); // Brown
    }
  }

  static CarStatus? getStatusFromString(String? statusString) {
    if (statusString == null) return null;
    
    try {
      return CarStatus.values.firstWhere(
        (status) => status.name == statusString,
      );
    } catch (e) {
      return null;
    }
  }

  static String getStatusDescription(CarStatus status) {
    switch (status) {
      case CarStatus.active:
        return 'Car is active and available for service';
      case CarStatus.inactive:
        return 'Car is temporarily inactive';
      case CarStatus.deleted:
        return 'Car has been deleted from active records';
      case CarStatus.suspended:
        return 'Car service has been suspended';
      case CarStatus.sold:
        return 'Car has been sold';
      case CarStatus.totaled:
        return 'Car has been declared totaled';
    }
  }
}