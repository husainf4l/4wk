import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DataDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> deleteAllUserData({
    required String userId,
    bool anonymizeInsteadOfDelete = true,
  }) async {
    try {
      debugPrint('Starting data deletion process for user: $userId');
      
      // Start a batch write for atomic operations
      final batch = _firestore.batch();
      
      if (anonymizeInsteadOfDelete) {
        await _anonymizeUserData(userId, batch);
      } else {
        await _deleteUserData(userId, batch);
      }
      
      // Commit all operations
      await batch.commit();
      
      // Delete Firebase Auth account (this should be done last)
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
      }
      
      debugPrint('Data deletion completed successfully for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Error during data deletion: $e');
      return false;
    }
  }

  static Future<void> _anonymizeUserData(String userId, WriteBatch batch) async {
    const String anonymizedValue = '[DELETED]';
    final DateTime deletionTime = DateTime.now();
    
    // 1. Anonymize user profile
    await _anonymizeUserProfile(userId, batch, anonymizedValue, deletionTime);
    
    // 2. Anonymize clients created by this user
    await _anonymizeUserClients(userId, batch, anonymizedValue, deletionTime);
    
    // 3. Anonymize cars associated with user's clients
    await _anonymizeUserCars(userId, batch, anonymizedValue, deletionTime);
    
    // 4. Anonymize sessions
    await _anonymizeUserSessions(userId, batch, anonymizedValue, deletionTime);
    
    // 5. Anonymize session activities
    await _anonymizeSessionActivities(userId, batch, anonymizedValue, deletionTime);
    
    // 6. Anonymize job orders
    await _anonymizeJobOrders(userId, batch, anonymizedValue, deletionTime);
    
    // 7. Anonymize reports
    await _anonymizeReports(userId, batch, anonymizedValue, deletionTime);
    
    // 8. Anonymize general activities
    await _anonymizeActivities(userId, batch, anonymizedValue, deletionTime);
  }

  static Future<void> _deleteUserData(String userId, WriteBatch batch) async {
    // This method completely removes data instead of anonymizing
    // Use with caution as it may break referential integrity
    
    // 1. Delete user profile
    final userDoc = _firestore.collection('users').doc(userId);
    batch.delete(userDoc);
    
    // 2. Delete or anonymize related data
    // Note: We still anonymize related data to maintain business records
    await _anonymizeUserData(userId, batch);
  }

  static Future<void> _anonymizeUserProfile(
    String userId,
    WriteBatch batch,
    String anonymizedValue,
    DateTime deletionTime,
  ) async {
    final userDoc = _firestore.collection('users').doc(userId);
    
    batch.update(userDoc, {
      'displayName': anonymizedValue,
      'email': anonymizedValue,
      'photoURL': '',
      'bio': anonymizedValue,
      'location': anonymizedValue,
      'phoneNumber': anonymizedValue,
      'personalInfo': anonymizedValue,
      'isDeleted': true,
      'deletedAt': deletionTime.millisecondsSinceEpoch,
      'lastUpdated': deletionTime.millisecondsSinceEpoch,
    });
  }

  static Future<void> _anonymizeUserClients(
    String userId,
    WriteBatch batch,
    String anonymizedValue,
    DateTime deletionTime,
  ) async {
    final clientsQuery = await _firestore
        .collection('clients')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    for (final doc in clientsQuery.docs) {
      batch.update(doc.reference, {
        'name': anonymizedValue,
        'email': anonymizedValue,
        'phone': anonymizedValue,
        'address': anonymizedValue,
        'personalInfo': anonymizedValue,
        'notes': anonymizedValue,
        'isDeleted': true,
        'deletedAt': deletionTime.millisecondsSinceEpoch,
        'lastUpdated': deletionTime.millisecondsSinceEpoch,
      });
    }
  }

  static Future<void> _anonymizeUserCars(
    String userId,
    WriteBatch batch,
    String anonymizedValue,
    DateTime deletionTime,
  ) async {
    // Get clients created by this user first
    final clientsQuery = await _firestore
        .collection('clients')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    final clientIds = clientsQuery.docs.map((doc) => doc.id).toList();
    
    if (clientIds.isNotEmpty) {
      // Anonymize cars belonging to these clients
      for (final clientId in clientIds) {
        final carsQuery = await _firestore
            .collection('cars')
            .where('clientId', isEqualTo: clientId)
            .get();
        
        for (final doc in carsQuery.docs) {
          batch.update(doc.reference, {
            'plate': anonymizedValue,
            'vin': anonymizedValue,
            'ownerName': anonymizedValue,
            'ownerPhone': anonymizedValue,
            'ownerEmail': anonymizedValue,
            'notes': anonymizedValue,
            'isDeleted': true,
            'deletedAt': deletionTime.millisecondsSinceEpoch,
            'lastUpdated': deletionTime.millisecondsSinceEpoch,
          });
        }
      }
    }
  }

  static Future<void> _anonymizeUserSessions(
    String userId,
    WriteBatch batch,
    String anonymizedValue,
    DateTime deletionTime,
  ) async {
    final sessionsQuery = await _firestore
        .collection('sessions')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    for (final doc in sessionsQuery.docs) {
      batch.update(doc.reference, {
        'clientName': anonymizedValue,
        'notes': anonymizedValue,
        'personalInfo': anonymizedValue,
        'isDeleted': true,
        'deletedAt': deletionTime.millisecondsSinceEpoch,
        'lastUpdated': deletionTime.millisecondsSinceEpoch,
      });
    }
  }

  static Future<void> _anonymizeSessionActivities(
    String userId,
    WriteBatch batch,
    String anonymizedValue,
    DateTime deletionTime,
  ) async {
    final activitiesQuery = await _firestore
        .collection('session_activities')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    for (final doc in activitiesQuery.docs) {
      final data = doc.data();
      final Map<String, dynamic> updates = {
        'isDeleted': true,
        'deletedAt': deletionTime.millisecondsSinceEpoch,
        'lastUpdated': deletionTime.millisecondsSinceEpoch,
      };
      
      // Anonymize based on activity type
      switch (data['type']) {
        case 'client_note':
          updates['notes'] = anonymizedValue;
          updates['clientName'] = anonymizedValue;
          break;
        case 'inspection':
          updates['notes'] = anonymizedValue;
          updates['inspectorName'] = anonymizedValue;
          break;
        case 'test_drive':
          updates['notes'] = anonymizedValue;
          updates['driverName'] = anonymizedValue;
          break;
        case 'report':
          updates['content'] = anonymizedValue;
          updates['summary'] = anonymizedValue;
          break;
        default:
          updates['notes'] = anonymizedValue;
          updates['content'] = anonymizedValue;
      }
      
      batch.update(doc.reference, updates);
    }
  }

  static Future<void> _anonymizeJobOrders(
    String userId,
    WriteBatch batch,
    String anonymizedValue,
    DateTime deletionTime,
  ) async {
    final jobOrdersQuery = await _firestore
        .collection('jobOrders')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    for (final doc in jobOrdersQuery.docs) {
      batch.update(doc.reference, {
        'clientName': anonymizedValue,
        'notes': anonymizedValue,
        'personalInfo': anonymizedValue,
        'isDeleted': true,
        'deletedAt': deletionTime.millisecondsSinceEpoch,
        'lastUpdated': deletionTime.millisecondsSinceEpoch,
      });
    }
  }

  static Future<void> _anonymizeReports(
    String userId,
    WriteBatch batch,
    String anonymizedValue,
    DateTime deletionTime,
  ) async {
    final reportsQuery = await _firestore
        .collection('reports')
        .where('createdBy', isEqualTo: userId)
        .get();
    
    for (final doc in reportsQuery.docs) {
      batch.update(doc.reference, {
        'clientName': anonymizedValue,
        'content': anonymizedValue,
        'summary': anonymizedValue,
        'notes': anonymizedValue,
        'personalInfo': anonymizedValue,
        'isDeleted': true,
        'deletedAt': deletionTime.millisecondsSinceEpoch,
        'lastUpdated': deletionTime.millisecondsSinceEpoch,
      });
    }
  }

  static Future<void> _anonymizeActivities(
    String userId,
    WriteBatch batch,
    String anonymizedValue,
    DateTime deletionTime,
  ) async {
    final activitiesQuery = await _firestore
        .collection('activity')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (final doc in activitiesQuery.docs) {
      batch.update(doc.reference, {
        'userName': anonymizedValue,
        'notes': anonymizedValue,
        'description': anonymizedValue,
        'personalInfo': anonymizedValue,
        'isDeleted': true,
        'deletedAt': deletionTime.millisecondsSinceEpoch,
        'lastUpdated': deletionTime.millisecondsSinceEpoch,
      });
    }
  }

  static Future<Map<String, int>> getUserDataSummary(String userId) async {
    final Map<String, int> summary = {};
    
    try {
      // Count user profile (always 1 or 0)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      summary['profile'] = userDoc.exists ? 1 : 0;
      
      // Count clients
      final clientsQuery = await _firestore
          .collection('clients')
          .where('createdBy', isEqualTo: userId)
          .get();
      summary['clients'] = clientsQuery.docs.length;
      
      // Count cars (through clients)
      int carCount = 0;
      for (final clientDoc in clientsQuery.docs) {
        final carsQuery = await _firestore
            .collection('cars')
            .where('clientId', isEqualTo: clientDoc.id)
            .get();
        carCount += carsQuery.docs.length;
      }
      summary['cars'] = carCount;
      
      // Count sessions
      final sessionsQuery = await _firestore
          .collection('sessions')
          .where('createdBy', isEqualTo: userId)
          .get();
      summary['sessions'] = sessionsQuery.docs.length;
      
      // Count session activities
      final activitiesQuery = await _firestore
          .collection('session_activities')
          .where('createdBy', isEqualTo: userId)
          .get();
      summary['session_activities'] = activitiesQuery.docs.length;
      
      // Count job orders
      final jobOrdersQuery = await _firestore
          .collection('jobOrders')
          .where('createdBy', isEqualTo: userId)
          .get();
      summary['job_orders'] = jobOrdersQuery.docs.length;
      
      // Count reports
      final reportsQuery = await _firestore
          .collection('reports')
          .where('createdBy', isEqualTo: userId)
          .get();
      summary['reports'] = reportsQuery.docs.length;
      
      // Count general activities
      final generalActivitiesQuery = await _firestore
          .collection('activity')
          .where('userId', isEqualTo: userId)
          .get();
      summary['activities'] = generalActivitiesQuery.docs.length;
      
    } catch (e) {
      debugPrint('Error getting user data summary: $e');
    }
    
    return summary;
  }

  static String getDataSummaryText(Map<String, int> summary) {
    final List<String> items = [];
    
    if ((summary['profile'] ?? 0) > 0) {
      items.add('Profile information');
    }
    if ((summary['clients'] ?? 0) > 0) {
      items.add('${summary['clients']} client record(s)');
    }
    if ((summary['cars'] ?? 0) > 0) {
      items.add('${summary['cars']} vehicle record(s)');
    }
    if ((summary['sessions'] ?? 0) > 0) {
      items.add('${summary['sessions']} session(s)');
    }
    if ((summary['session_activities'] ?? 0) > 0) {
      items.add('${summary['session_activities']} activity record(s)');
    }
    if ((summary['job_orders'] ?? 0) > 0) {
      items.add('${summary['job_orders']} job order(s)');
    }
    if ((summary['reports'] ?? 0) > 0) {
      items.add('${summary['reports']} report(s)');
    }
    if ((summary['activities'] ?? 0) > 0) {
      items.add('${summary['activities']} activity log(s)');
    }
    
    if (items.isEmpty) {
      return 'No personal data found';
    }
    
    return items.join(', ');
  }
}