import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'activity_service.dart';

class SessionService {
  final CollectionReference _sessionsCollection = FirebaseFirestore.instance
      .collection('sessions');
  final ActivityService _activityService = Get.put(ActivityService());

  // Helper method to handle Firestore errors and extract index information
  void _handleFirestoreError(Object error, String operation) {
    String errorMessage = 'Error during $operation: $error';

    // Extract index creation URL from Firebase exception if available
    if (error is FirebaseException && error.code == 'failed-precondition') {
      // This typically means a required index is missing
      debugPrint('Index Error: ${error.message}');

      // Extract the index creation link if present
      if (error.message != null &&
          error.message!.contains('https://console.firebase.google.com')) {
        final indexLinkMatch = RegExp(
          r'(https://console\.firebase\.google\.com/[^\s]+)',
        ).firstMatch(error.message!);
        if (indexLinkMatch != null) {
          final indexLink = indexLinkMatch.group(0);
          debugPrint('=========== MISSING INDEX DETECTED ===========');
          debugPrint('Create the required index by visiting:');
          debugPrint(indexLink);
          debugPrint('==============================================');

          // Show a snackbar to the user with guidance
          Get.snackbar(
            'Database Index Required',
            'A required database index is missing. Please contact the developer.',
            duration: const Duration(seconds: 5),
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } else {
      debugPrint(errorMessage);
    }
  }

  // Create a new session
  Future<String?> createSession({
    required String clientId,
    required String clientName,
    required String clientPhoneNumber,
    required String carId,
    required String carMake,
    required String carModel,
    required String plateNumber,
    required String garageId,
  }) async {
    try {
      final Map<String, dynamic> sessionData = {
        'client': {
          'id': clientId,
          'name': clientName,
          'phoneNumber': clientPhoneNumber,
        },
        'car': {
          'id': carId,
          'make': carMake,
          'model': carModel,
          'plateNumber': plateNumber,
        },
        'garageId': garageId,
        'status': 'OPEN',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _sessionsCollection.add(sessionData);
      final sessionId = docRef.id;

      // Create an activity for session creation
      await _activityService.createActivity(
        sessionId: sessionId,
        type: 'session_created',
        title: 'Session Created',
        description: 'New session for $carMake $carModel created',
      );

      return sessionId;
    } catch (e) {
      _handleFirestoreError(e, 'creating session');
      return null;
    }
  }

  // Update session status
  Future<bool> updateSessionStatus({
    required String sessionId,
    required String newStatus,
  }) async {
    try {
      // Get the current session to check its current status
      final sessionDoc = await _sessionsCollection.doc(sessionId).get();
      if (!sessionDoc.exists) {
        return false;
      }

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final currentStatus = sessionData['status'] ?? 'UNKNOWN';

      // Update the status
      await _sessionsCollection.doc(sessionId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record this as an activity
      await _activityService.createStatusChangeActivity(
        sessionId: sessionId,
        oldStatus: currentStatus,
        newStatus: newStatus,
      );

      return true;
    } catch (e) {
      _handleFirestoreError(e, 'updating session status');
      return false;
    }
  }

  // Get a session by ID
  Future<DocumentSnapshot?> getSession(String id) async {
    try {
      return await _sessionsCollection.doc(id).get();
    } catch (e) {
      _handleFirestoreError(e, 'getting session by ID');
      return null;
    }
  }

  // Get sessions for a client
  Future<List<DocumentSnapshot>> getClientSessions(String clientId) async {
    try {
      final querySnapshot =
          await _sessionsCollection
              .where('client.id', isEqualTo: clientId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs;
    } catch (e) {
      _handleFirestoreError(e, 'querying client sessions');
      return [];
    }
  }

  // Update session with client note ID
  Future<bool> updateSessionWithClientNote({
    required String sessionId,
    required String clientNoteId,
    String? notes,
  }) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'clientNoteId': clientNoteId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record this as an activity
      await _activityService.createNoteActivity(
        sessionId: sessionId,
        notes: notes,
      );

      return true;
    } catch (e) {
      _handleFirestoreError(e, 'updating session with client note');
      return false;
    }
  }

  // Update session with notes, requests, and images
  Future<bool> updateSessionWithDetails({
    required String sessionId,
    required String notes,
    required List<String> requests,
    required List<String> images,
  }) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'details': {'notes': notes, 'requests': requests, 'images': images},
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record this as an activity
      await _activityService.createActivity(
        sessionId: sessionId,
        type: 'details_updated',
        title: 'Session Details Updated',
        description: notes.isNotEmpty ? 'Notes: $notes' : null,
      );

      return true;
    } catch (e) {
      _handleFirestoreError(e, 'updating session details');
      return false;
    }
  }
}
