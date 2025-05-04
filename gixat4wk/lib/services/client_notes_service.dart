import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'error_service.dart';

class ClientNotesService {
  final CollectionReference _jobCardCollection = FirebaseFirestore.instance
      .collection('jobCard');
  final CollectionReference _activityCollection = FirebaseFirestore.instance
      .collection('activity');

  // Get auth controller if available
  final AuthController? _authController =
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  // Get error service for error logging
  final ErrorService _errorService = Get.find<ErrorService>(
    tag: 'ErrorService',
  );

  Future<String?> saveClientNote({
    required String sessionId,
    required String carId,
    required String clientId,
    required String notes,
    required List<Map<String, dynamic>> requests,
    required List<String> images,
  }) async {
    try {
      // Filter out any invalid image URLs (ensure they're all valid URLs)
      final List<String> validImages =
          images
              .where((url) => url.isNotEmpty && url.startsWith('http'))
              .toList();

      // Create Firestore document
      final clientNoteData = {
        'sessionId': sessionId,
        'carId': carId,
        'clientId': clientId,
        'notes': notes,
        'requests': requests,
        'images': validImages,
        'type': 'clientNotes',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add document to Firestore
      final DocumentReference docRef = await _jobCardCollection.add(
        clientNoteData,
      );

      // Create activity record for tracking
      await _createActivityRecord(
        sessionId: sessionId,
        title: 'Client note updated',
        type: 'note',
      );

      return docRef.id;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientNotesService.saveClientNote',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // Get client notes for a specific session
  Future<Map<String, dynamic>?> getClientNotesForSession(
    String sessionId,
  ) async {
    try {
      final snapshot =
          await _jobCardCollection
              .where('sessionId', isEqualTo: sessionId)
              .where('type', isEqualTo: 'clientNotes')
              .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }
      return null;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientNotesService.getClientNotesForSession',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // Update an existing client note
  Future<bool> updateClientNote({
    required String clientNoteId,
    required String notes,
    required List<Map<String, dynamic>> requests,
    List<String>? images,
  }) async {
    try {
      final updateData = {
        'notes': notes,
        'requests': requests,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (images != null && images.isNotEmpty) {
        // Create a fresh copy of the images list with only valid URLs
        final List<String> validImages = [];
        for (String url in images) {
          if (url.trim().isNotEmpty) {
            validImages.add(url);
          }
        }

        if (validImages.isNotEmpty) {
          updateData['images'] = validImages;
        }
      }

      await _jobCardCollection.doc(clientNoteId).update(updateData);

      // Get the session ID for activity logging
      final noteDoc = await _jobCardCollection.doc(clientNoteId).get();
      if (noteDoc.exists) {
        final noteData = noteDoc.data() as Map<String, dynamic>;
        final sessionId = noteData['sessionId'] as String?;

        if (sessionId != null) {
          // Create activity record for the note update
          await _activityCollection.add({
            'sessionId': sessionId,
            'clientNoteId': clientNoteId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'note_update',
            'title': 'Client Notes Updated',
            'description':
                notes.isNotEmpty
                    ? 'Notes: $notes'
                    : 'Client requests were updated',
            'userId': _authController?.firebaseUser?.uid,
            'userName': _authController?.currentUser?.displayName,
          });
        }
      }

      return true;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'ClientNotesService.updateClientNote',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  // Create an activity record for tracking user actions
  Future<void> _createActivityRecord({
    required String sessionId,
    required String title,
    required String type,
    String? description,
  }) async {
    try {
      await _activityCollection.add({
        'sessionId': sessionId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        'title': title,
        'description': description ?? '',
        'userId': _authController?.firebaseUser?.uid,
        'userName': _authController?.currentUser?.displayName,
      });
    } catch (e, stackTrace) {
      // Log error but don't propagate since this is a non-critical operation
      _errorService.logError(
        e,
        context: 'ClientNotesService._createActivityRecord',
        userId: _authController?.firebaseUser?.uid,
        stackTrace: stackTrace,
      );
    }
  }
}
