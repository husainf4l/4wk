import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum CustomerStatus {
  active,
  inactive,
  deleted,
  suspended,
}

class CustomerDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> softDeleteCustomer({
    required String customerId,
    required String deletedBy,
    String? reason,
    CustomerStatus status = CustomerStatus.deleted,
  }) async {
    try {
      debugPrint('Starting soft delete for customer: $customerId');
      
      // Start batch operation
      final batch = _firestore.batch();
      final deleteTime = DateTime.now();
      
      // Update customer status
      await _updateCustomerStatus(customerId, status, deleteTime, deletedBy, reason, batch);
      
      // Update related cars
      await _updateRelatedCars(customerId, status, deleteTime, deletedBy, batch);
      
      // Update related sessions
      await _updateRelatedSessions(customerId, status, deleteTime, deletedBy, batch);
      
      // Update related job orders
      await _updateRelatedJobOrders(customerId, status, deleteTime, deletedBy, batch);
      
      // Commit all changes
      await batch.commit();
      
      debugPrint('Successfully soft deleted customer: $customerId');
      return true;
    } catch (e) {
      debugPrint('Error soft deleting customer: $e');
      return false;
    }
  }

  static Future<bool> restoreCustomer({
    required String customerId,
    required String restoredBy,
    String? reason,
  }) async {
    try {
      debugPrint('Starting restore for customer: $customerId');
      
      final batch = _firestore.batch();
      final restoreTime = DateTime.now();
      
      // Restore customer status
      await _updateCustomerStatus(
        customerId, 
        CustomerStatus.active, 
        restoreTime, 
        restoredBy, 
        reason ?? 'Customer restored',
        batch,
      );
      
      // Restore related cars
      await _updateRelatedCars(customerId, CustomerStatus.active, restoreTime, restoredBy, batch);
      
      // Note: Sessions and job orders are not automatically restored
      // They need to be manually reviewed and restored if needed
      
      await batch.commit();
      
      debugPrint('Successfully restored customer: $customerId');
      return true;
    } catch (e) {
      debugPrint('Error restoring customer: $e');
      return false;
    }
  }

  static Future<void> _updateCustomerStatus(
    String customerId,
    CustomerStatus status,
    DateTime timestamp,
    String actionBy,
    String? reason,
    WriteBatch batch,
  ) async {
    final customerDoc = _firestore.collection('clients').doc(customerId);
    
    final updates = {
      'status': status.name,
      'isDeleted': status == CustomerStatus.deleted,
      'isActive': status == CustomerStatus.active,
      'lastStatusChange': timestamp.millisecondsSinceEpoch,
      'statusChangedBy': actionBy,
      'statusChangeReason': reason ?? 'Status changed to ${status.name}',
      'lastUpdated': timestamp.millisecondsSinceEpoch,
    };
    
    // Add deletion-specific fields
    if (status == CustomerStatus.deleted) {
      updates['deletedAt'] = timestamp.millisecondsSinceEpoch;
      updates['deletedBy'] = actionBy;
      updates['deletionReason'] = reason ?? 'Customer deleted';
    }
    
    // Add restoration-specific fields
    if (status == CustomerStatus.active) {
      updates['restoredAt'] = timestamp.millisecondsSinceEpoch;
      updates['restoredBy'] = actionBy;
      updates['restorationReason'] = reason ?? 'Customer restored';
    }
    
    batch.update(customerDoc, updates);
  }

  static Future<void> _updateRelatedCars(
    String customerId,
    CustomerStatus status,
    DateTime timestamp,
    String actionBy,
    WriteBatch batch,
  ) async {
    final carsQuery = await _firestore
        .collection('cars')
        .where('clientId', isEqualTo: customerId)
        .get();
    
    for (final doc in carsQuery.docs) {
      final updates = {
        'status': status.name,
        'isDeleted': status == CustomerStatus.deleted,
        'isActive': status == CustomerStatus.active,
        'lastStatusChange': timestamp.millisecondsSinceEpoch,
        'statusChangedBy': actionBy,
        'statusChangeReason': 'Customer ${status.name}',
        'lastUpdated': timestamp.millisecondsSinceEpoch,
      };
      
      if (status == CustomerStatus.deleted) {
        updates['deletedAt'] = timestamp.millisecondsSinceEpoch;
        updates['deletedBy'] = actionBy;
        updates['deletionReason'] = 'Customer deleted';
      }
      
      batch.update(doc.reference, updates);
    }
  }

  static Future<void> _updateRelatedSessions(
    String customerId,
    CustomerStatus status,
    DateTime timestamp,
    String actionBy,
    WriteBatch batch,
  ) async {
    final sessionsQuery = await _firestore
        .collection('sessions')
        .where('clientId', isEqualTo: customerId)
        .get();
    
    for (final doc in sessionsQuery.docs) {
      final updates = {
        'customerStatus': status.name,
        'isCustomerDeleted': status == CustomerStatus.deleted,
        'customerStatusChangedAt': timestamp.millisecondsSinceEpoch,
        'customerStatusChangedBy': actionBy,
        'lastUpdated': timestamp.millisecondsSinceEpoch,
      };
      
      // Don't automatically delete sessions, just mark customer status
      // This preserves historical data while indicating customer state
      
      batch.update(doc.reference, updates);
    }
  }

  static Future<void> _updateRelatedJobOrders(
    String customerId,
    CustomerStatus status,
    DateTime timestamp,
    String actionBy,
    WriteBatch batch,
  ) async {
    final jobOrdersQuery = await _firestore
        .collection('jobOrders')
        .where('clientId', isEqualTo: customerId)
        .get();
    
    for (final doc in jobOrdersQuery.docs) {
      final updates = {
        'customerStatus': status.name,
        'isCustomerDeleted': status == CustomerStatus.deleted,
        'customerStatusChangedAt': timestamp.millisecondsSinceEpoch,
        'customerStatusChangedBy': actionBy,
        'lastUpdated': timestamp.millisecondsSinceEpoch,
      };
      
      batch.update(doc.reference, updates);
    }
  }

  static Future<List<Map<String, dynamic>>> getDeletedCustomers({
    int limit = 50,
    String? lastDocumentId,
  }) async {
    Query query = _firestore
        .collection('clients')
        .where('isDeleted', isEqualTo: true)
        .orderBy('deletedAt', descending: true);
    
    if (limit > 0) {
      query = query.limit(limit);
    }
    
    if (lastDocumentId != null) {
      final lastDoc = await _firestore
          .collection('clients')
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

  static Future<Map<String, dynamic>?> getCustomerDeletionInfo(String customerId) async {
    try {
      final customerDoc = await _firestore
          .collection('clients')
          .doc(customerId)
          .get();
      
      if (!customerDoc.exists) {
        return null;
      }
      
      final data = customerDoc.data() as Map<String, dynamic>;
      
      // Get related data counts
      final carsCount = await _getRelatedCarsCount(customerId);
      final sessionsCount = await _getRelatedSessionsCount(customerId);
      final jobOrdersCount = await _getRelatedJobOrdersCount(customerId);
      
      return {
        'customer': data,
        'relatedData': {
          'cars': carsCount,
          'sessions': sessionsCount,
          'jobOrders': jobOrdersCount,
        },
      };
    } catch (e) {
      debugPrint('Error getting customer deletion info: $e');
      return null;
    }
  }

  static Future<int> _getRelatedCarsCount(String customerId) async {
    final carsQuery = await _firestore
        .collection('cars')
        .where('clientId', isEqualTo: customerId)
        .get();
    return carsQuery.docs.length;
  }

  static Future<int> _getRelatedSessionsCount(String customerId) async {
    final sessionsQuery = await _firestore
        .collection('sessions')
        .where('clientId', isEqualTo: customerId)
        .get();
    return sessionsQuery.docs.length;
  }

  static Future<int> _getRelatedJobOrdersCount(String customerId) async {
    final jobOrdersQuery = await _firestore
        .collection('jobOrders')
        .where('clientId', isEqualTo: customerId)
        .get();
    return jobOrdersQuery.docs.length;
  }

  static Query getActiveCustomersQuery() {
    return _firestore
        .collection('clients')
        .where('isDeleted', isEqualTo: false)
        .where('isActive', isEqualTo: true);
  }

  static Query getAllCustomersQuery({bool includeDeleted = false}) {
    if (includeDeleted) {
      return _firestore.collection('clients');
    }
    return _firestore
        .collection('clients')
        .where('isDeleted', isEqualTo: false);
  }

  static Stream<QuerySnapshot> getCustomersStream({
    bool includeDeleted = false,
    CustomerStatus? filterByStatus,
  }) {
    Query query = _firestore.collection('clients');
    
    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
    
    if (filterByStatus != null) {
      query = query.where('status', isEqualTo: filterByStatus.name);
    }
    
    return query.snapshots();
  }

  static String getStatusDisplayName(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Active';
      case CustomerStatus.inactive:
        return 'Inactive';
      case CustomerStatus.deleted:
        return 'Deleted';
      case CustomerStatus.suspended:
        return 'Suspended';
    }
  }

  static CustomerStatus? getStatusFromString(String? statusString) {
    if (statusString == null) return null;
    
    try {
      return CustomerStatus.values.firstWhere(
        (status) => status.name == statusString,
      );
    } catch (e) {
      return null;
    }
  }
}