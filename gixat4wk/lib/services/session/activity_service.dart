import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/controllers/auth_controller.dart';
import 'package:gixat4wk/services/error_service.dart';

class ActivityService {
  final CollectionReference _activityCollection = FirebaseFirestore.instance
      .collection('activity');

  // Get auth controller if available
  final AuthController? _authController =
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  // Get error service for error logging
  final ErrorService _errorService = Get.find<ErrorService>(
    tag: 'ErrorService',
  );

  /// Log an activity for tracking user actions
  Future<String?> logActivity({
    required String sessionId,
    required String title,
    required String type,
    String? description,
    String? relatedDocumentId,
    String? relatedDocumentType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final activityData = {
        'sessionId': sessionId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        'title': title,
        'description': description ?? '',
        'userId': _authController?.firebaseUser?.uid,
        'userName': _authController?.currentUser?.displayName,
      };

      // Add optional fields if provided
      if (relatedDocumentId != null) {
        activityData['relatedDocumentId'] = relatedDocumentId;
      }

      if (relatedDocumentType != null) {
        activityData['relatedDocumentType'] = relatedDocumentType;
      }

      // Add any additional data
      if (additionalData != null) {
        activityData.addAll(additionalData);
      }

      // Add to Firestore
      final docRef = await _activityCollection.add(activityData);
      return docRef.id;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ActivityService.logActivity',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Create an activity (method called by SessionService)
  Future<String?> createActivity({
    required String sessionId,
    required String type,
    required String title,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    return logActivity(
      sessionId: sessionId,
      title: title,
      type: type,
      description: description,
      additionalData: additionalData,
    );
  }

  /// Create a status change activity (method called by SessionService)
  Future<String?> createStatusChangeActivity({
    required String sessionId,
    required String oldStatus,
    required String newStatus,
  }) async {
    return createActivity(
      sessionId: sessionId,
      type: 'status_changed',
      title: 'Status Changed',
      description: 'Status changed from $oldStatus to $newStatus',
      additionalData: {'oldStatus': oldStatus, 'newStatus': newStatus},
    );
  }

  /// Create a note activity (method called by SessionService)
  Future<String?> createNoteActivity({
    required String sessionId,
    String? notes,
  }) async {
    return createActivity(
      sessionId: sessionId,
      type: 'note_added',
      title: 'Notes Added',
      description: notes,
    );
  }

  /// Get activities for a specific session
  Future<List<Map<String, dynamic>>> getActivitiesForSession(
    String sessionId, {
    int? limit,
    String? typeFilter,
  }) async {
    try {
      Query query = _activityCollection
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: true);

      if (typeFilter != null) {
        query = query.where('type', isEqualTo: typeFilter);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ActivityService.getActivitiesForSession',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Stream activities for a specific session in real-time
  Stream<List<Map<String, dynamic>>> streamActivitiesForSession(
    String sessionId, {
    int? limit,
    String? typeFilter,
  }) {
    try {
      Query query = _activityCollection
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: true);

      if (typeFilter != null) {
        query = query.where('type', isEqualTo: typeFilter);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
            }).toList();
          })
          .handleError((e, stackTrace) {
            _errorService.logError(
              e,
              context: 'ActivityService.streamActivitiesForSession',
              userId: _authController?.firebaseUser?.uid,
              stackTrace: stackTrace,
            );
            return <Map<String, dynamic>>[];
          });
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ActivityService.streamActivitiesForSession',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );
      return Stream.value([]);
    }
  }

  /// Delete activity records
  Future<bool> deleteActivity(String activityId) async {
    try {
      await _activityCollection.doc(activityId).delete();
      return true;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ActivityService.deleteActivity',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get the latest activity of a specific type for a session
  Future<Map<String, dynamic>?> getLatestActivityByType(
    String sessionId,
    String type,
  ) async {
    try {
      final snapshot =
          await _activityCollection
              .where('sessionId', isEqualTo: sessionId)
              .where('type', isEqualTo: type)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ActivityService.getLatestActivityByType',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
