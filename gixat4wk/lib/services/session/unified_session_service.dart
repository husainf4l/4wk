import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/services/session/activity_service.dart';
import '../../models/unified_session_activity.dart';
import '../../controllers/auth_controller.dart';

class UnifiedSessionService {
  final CollectionReference _activitiesCollection = FirebaseFirestore.instance
      .collection('session_activities');
  final CollectionReference _sessionsCollection = FirebaseFirestore.instance
      .collection('sessions');
  final ActivityService _activityService = Get.put(ActivityService());

  // Try to get the AuthController if it's available
  final AuthController? _authController =
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  // Helper method to handle Firestore errors
  void _handleFirestoreError(Object error, String operation) {
    String errorMessage = 'Error during $operation: $error';
    debugPrint(errorMessage);

    if (error is FirebaseException && error.code == 'failed-precondition') {
      Get.snackbar(
        'Database Index Required',
        'A required database index is missing. Please contact the developer.',
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Get current user info
  String? get _currentUserId => _authController?.firebaseUser?.uid;

  // ============================================================================
  // CRUD Operations for Unified Session Activities
  // ============================================================================

  /// Create a new session activity
  Future<String?> createActivity(UnifiedSessionActivity activity) async {
    try {
      final activityData =
          activity
              .copyWith(createdBy: _currentUserId, updatedBy: _currentUserId)
              .toMap();

      final docRef = await _activitiesCollection.add(activityData);

      // Update session status based on the activity stage
      await _updateSessionStatusForStage(activity.sessionId, activity.stage);

      // Create audit trail
      await _activityService.createActivity(
        sessionId: activity.sessionId,
        type: activity.stage.toString().split('.').last,
        title: '${_getStageTitle(activity.stage)} Created',
        description:
            activity.notes.isNotEmpty ? 'Notes: ${activity.notes}' : null,
      );

      return docRef.id;
    } catch (e) {
      _handleFirestoreError(e, 'creating session activity');
      return null;
    }
  }

  /// Update an existing session activity
  Future<bool> updateActivity(
    String activityId,
    UnifiedSessionActivity updatedActivity,
  ) async {
    try {
      final updateData =
          updatedActivity.copyWith(updatedBy: _currentUserId).toMap();

      await _activitiesCollection.doc(activityId).update(updateData);

      // Create audit trail for update
      await _activityService.createActivity(
        sessionId: updatedActivity.sessionId,
        type: '${updatedActivity.stage.toString().split('.').last}_updated',
        title: '${_getStageTitle(updatedActivity.stage)} Updated',
        description:
            updatedActivity.notes.isNotEmpty
                ? 'Notes: ${updatedActivity.notes}'
                : null,
      );

      return true;
    } catch (e) {
      _handleFirestoreError(e, 'updating session activity');
      return false;
    }
  }

  /// Get activities for a specific session and stage
  Future<List<UnifiedSessionActivity>> getActivitiesForSession({
    required String sessionId,
    ActivityStage? stage,
    ActivityStatus? status,
  }) async {
    try {
      Query query = _activitiesCollection.where(
        'sessionId',
        isEqualTo: sessionId,
      );

      if (stage != null) {
        query = query.where(
          'stage',
          isEqualTo: stage.toString().split('.').last,
        );
      }

      if (status != null) {
        query = query.where(
          'status',
          isEqualTo: status.toString().split('.').last,
        );
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return UnifiedSessionActivity.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      _handleFirestoreError(e, 'getting session activities');
      return [];
    }
  }

  /// Get a specific activity by ID
  Future<UnifiedSessionActivity?> getActivity(String activityId) async {
    try {
      final doc = await _activitiesCollection.doc(activityId).get();

      if (doc.exists) {
        return UnifiedSessionActivity.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }

      return null;
    } catch (e) {
      _handleFirestoreError(e, 'getting activity');
      return null;
    }
  }

  /// Delete an activity
  Future<bool> deleteActivity(String activityId) async {
    try {
      await _activitiesCollection.doc(activityId).delete();
      return true;
    } catch (e) {
      _handleFirestoreError(e, 'deleting activity');
      return false;
    }
  }

  // ============================================================================
  // Stage-Specific Helper Methods
  // ============================================================================

  /// Create client notes activity
  Future<String?> createClientNotes({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> requests,
    List<String> images = const [],
  }) async {
    final activity = UnifiedSessionActivity.forClientNotes(
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      notes: notes,
      requests: requests,
      images: images,
    );

    return await createActivity(activity);
  }

  /// Create inspection activity
  Future<String?> createInspection({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> findings,
    List<String> images = const [],
    List<Map<String, dynamic>> requests = const [],
  }) async {
    final activity = UnifiedSessionActivity.forInspection(
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      notes: notes,
      findings: findings,
      images: images,
      requests: requests,
    );

    return await createActivity(activity);
  }

  /// Create test drive activity
  Future<String?> createTestDrive({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> observations,
    List<String> images = const [],
    List<Map<String, dynamic>> requests = const [],
  }) async {
    final activity = UnifiedSessionActivity.forTestDrive(
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      notes: notes,
      observations: observations,
      images: images,
      requests: requests,
    );

    return await createActivity(activity);
  }

  /// Create report activity
  Future<String?> createReport({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required Map<String, dynamic> reportData,
    List<String> images = const [],
    List<Map<String, dynamic>> requests = const [],
  }) async {
    final activity = UnifiedSessionActivity.forReport(
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      notes: notes,
      reportData: reportData,
      images: images,
      requests: requests,
    );

    return await createActivity(activity);
  }

  /// Create job card activity and corresponding job order
  Future<String?> createJobCard({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> jobCardItems,
    List<String> images = const [],
    List<Map<String, dynamic>> requests = const [],
  }) async {
    final activity = UnifiedSessionActivity.forJobCard(
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      notes: notes,
      jobCardItems: jobCardItems,
      images: images,
    );

    // Create the session activity first
    final activityId = await createActivity(activity);

    if (activityId != null) {
      // Now create the job order
      await _createJobOrderFromJobCard(
        sessionId: sessionId,
        clientId: clientId,
        carId: carId,
        garageId: garageId,
        jobCardItems: jobCardItems,
        notes: notes,
      );
    }

    return activityId;
  }

  /// Create quality control activity (final stage)
  Future<String?> createQualityControl({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required String notes,
    required List<Map<String, dynamic>> qcChecks,
    List<String> images = const [],
    Map<String, dynamic>? qcData,
  }) async {
    final activity = UnifiedSessionActivity.forQualityControl(
      sessionId: sessionId,
      clientId: clientId,
      carId: carId,
      garageId: garageId,
      notes: notes,
      qcChecks: qcChecks,
      images: images,
      qcData: qcData,
    );

    // Create the session activity
    final activityId = await createActivity(activity);

    if (activityId != null) {
      // Since this is the final stage, we might want to add additional completion logic here
      // For example: update job order status to completed, send notifications, etc.
      await _finalizeSession(sessionId);
    }

    return activityId;
  }

  /// Finalize session when QC is completed
  Future<void> _finalizeSession(String sessionId) async {
    try {
      // Update any related job orders to completed status
      final jobOrdersQuery =
          await FirebaseFirestore.instance
              .collection('jobOrders')
              .where('sessionId', isEqualTo: sessionId)
              .get();

      for (final jobOrderDoc in jobOrdersQuery.docs) {
        await jobOrderDoc.reference.update({
          'order.status': 'completed',
          'completedAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Add completion timestamp to session
      await _sessionsCollection.doc(sessionId).update({
        'completedAt': FieldValue.serverTimestamp(),
        'isCompleted': true,
      });

      debugPrint('Session $sessionId finalized successfully');
    } catch (e) {
      debugPrint('Error finalizing session $sessionId: $e');
      _handleFirestoreError(e, 'finalizing session');
    }
  }

  /// Create job order from job card data
  Future<void> _createJobOrderFromJobCard({
    required String sessionId,
    required String clientId,
    required String carId,
    required String garageId,
    required List<Map<String, dynamic>> jobCardItems,
    required String notes,
  }) async {
    try {
      // Get session data to extract client and car information
      final sessionDoc = await _sessionsCollection.doc(sessionId).get();
      if (!sessionDoc.exists) {
        debugPrint('Session not found for job order creation');
        return;
      }

      // Get client data
      final clientDoc =
          await FirebaseFirestore.instance
              .collection('clients')
              .doc(clientId)
              .get();

      final clientData =
          clientDoc.exists ? clientDoc.data() as Map<String, dynamic> : {};

      // Get car data
      final carDoc =
          await FirebaseFirestore.instance.collection('cars').doc(carId).get();

      final carData =
          carDoc.exists ? carDoc.data() as Map<String, dynamic> : {};

      // Create job order document
      final jobOrderData = {
        'sessionId': sessionId,
        'clientId': clientId,
        'clientName': clientData['name'] ?? 'Unknown Client',
        'carData': {
          'id': carId,
          'make': carData['make'] ?? 'Unknown',
          'model': carData['model'] ?? 'Unknown',
          'year': carData['year'] ?? '',
          'plate': carData['plateNumber'] ?? 'Unknown',
          'vin': carData['vin'] ?? '',
          'mileage': carData['mileage'] ?? '',
        },
        'order': {
          'id': 'job-${DateTime.now().millisecondsSinceEpoch}',
          'requests':
              jobCardItems
                  .map(
                    (item) => {
                      // Universal request fields (consistent with session activities)
                      'id':
                          item['id'] ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      'request':
                          item['request'] ??
                          item['title'] ??
                          item['name'] ??
                          'Untitled Request',
                      'argancy':
                          item['argancy'] ?? item['priority'] ?? 'medium',
                      // Job order specific fields
                      'jobOrderStatus': 'pending',
                      'jobOrderNotes':
                          item['notes'] ?? item['description'] ?? '',
                      'assignedTo': item['assignedTo'] ?? '',
                      'estimatedHours': item['estimatedHours'] ?? '',
                      'price': item['price'] ?? '0',
                      // Backward compatibility
                      'isDone': false,
                      // Source information
                      'source': item['source'] ?? 'session',
                      'sourceStage': item['sourceStage'] ?? 'jobcard',
                      'timestamp':
                          item['timestamp'] ?? DateTime.now().toIso8601String(),
                    },
                  )
                  .toList(),
          'status': 'open',
          'notes': notes,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
        'garageId': garageId,
        'createdBy': _currentUserId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Save to jobOrders collection
      await FirebaseFirestore.instance
          .collection('jobOrders')
          .add(jobOrderData);

      debugPrint('Job order created successfully for session: $sessionId');
    } catch (e) {
      debugPrint('Error creating job order: $e');
      _handleFirestoreError(e, 'creating job order from job card');
    }
  }

  // ============================================================================
  // Session Status Management
  // ============================================================================

  /// Update session status based on activity stage
  Future<void> _updateSessionStatusForStage(
    String sessionId,
    ActivityStage stage,
  ) async {
    String newStatus;

    switch (stage) {
      case ActivityStage.clientNotes:
        newStatus = 'NOTED';
        break;
      case ActivityStage.inspection:
        newStatus = 'INSPECTED';
        break;
      case ActivityStage.testDrive:
        newStatus = 'TESTED';
        break;
      case ActivityStage.report:
        newStatus = 'REPORTED';
        break;
      case ActivityStage.jobCard:
        newStatus = 'JOB_CREATED';
        break;
      case ActivityStage.qualityControl:
        newStatus = 'COMPLETED'; // Final status - session is complete
        break;
    }

    try {
      await _sessionsCollection.doc(sessionId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleFirestoreError(e, 'updating session status');
    }
  }

  /// Get session progress summary
  Future<Map<String, bool>> getSessionProgress(String sessionId) async {
    try {
      final activities = await getActivitiesForSession(sessionId: sessionId);

      final progress = {
        'clientNotes': false,
        'inspection': false,
        'testDrive': false,
        'report': false,
        'jobCard': false,
        'qualityControl': false,
      };

      for (final activity in activities) {
        switch (activity.stage) {
          case ActivityStage.clientNotes:
            progress['clientNotes'] = true;
            break;
          case ActivityStage.inspection:
            progress['inspection'] = true;
            break;
          case ActivityStage.testDrive:
            progress['testDrive'] = true;
            break;
          case ActivityStage.report:
            progress['report'] = true;
            break;
          case ActivityStage.jobCard:
            progress['jobCard'] = true;
            break;
          case ActivityStage.qualityControl:
            progress['qualityControl'] = true;
            break;
        }
      }

      return progress;
    } catch (e) {
      _handleFirestoreError(e, 'getting session progress');
      return {
        'clientNotes': false,
        'inspection': false,
        'testDrive': false,
        'report': false,
        'jobCard': false,
        'qualityControl': false,
      };
    }
  }

  // ============================================================================
  // Utility Methods
  // ============================================================================

  String _getStageTitle(ActivityStage stage) {
    switch (stage) {
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
      case ActivityStage.qualityControl:
        return 'Quality Control';
    }
  }

  /// Search activities across multiple sessions
  Future<List<UnifiedSessionActivity>> searchActivities({
    String? searchText,
    ActivityStage? stage,
    ActivityStatus? status,
    String? clientId,
    String? carId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _activitiesCollection;

      if (stage != null) {
        query = query.where(
          'stage',
          isEqualTo: stage.toString().split('.').last,
        );
      }

      if (status != null) {
        query = query.where(
          'status',
          isEqualTo: status.toString().split('.').last,
        );
      }

      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }

      if (carId != null) {
        query = query.where('carId', isEqualTo: carId);
      }

      if (fromDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: fromDate);
      }

      if (toDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: toDate);
      }

      query = query.orderBy('createdAt', descending: true).limit(100);

      final snapshot = await query.get();

      List<UnifiedSessionActivity> activities =
          snapshot.docs.map((doc) {
            return UnifiedSessionActivity.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

      // Filter by search text if provided (client-side filtering)
      if (searchText != null && searchText.isNotEmpty) {
        final searchLower = searchText.toLowerCase();
        activities =
            activities.where((activity) {
              return activity.notes.toLowerCase().contains(searchLower) ||
                  activity.requests.any(
                    (req) => req.toString().toLowerCase().contains(searchLower),
                  );
            }).toList();
      }

      return activities;
    } catch (e) {
      _handleFirestoreError(e, 'searching activities');
      return [];
    }
  }

  /// Batch update multiple activities
  Future<bool> batchUpdateActivities(
    List<String> activityIds,
    Map<String, dynamic> updates,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final activityId in activityIds) {
        final docRef = _activitiesCollection.doc(activityId);
        final updateData = {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _currentUserId,
        };
        batch.update(docRef, updateData);
      }

      await batch.commit();
      return true;
    } catch (e) {
      _handleFirestoreError(e, 'batch updating activities');
      return false;
    }
  }
}
