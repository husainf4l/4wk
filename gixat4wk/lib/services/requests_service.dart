import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'error_service.dart';

class RequestsService {
  // Get error service from GetX
  final ErrorService _errorService = Get.find<ErrorService>();

  // Get default service requests based on service type
  List<String> getDefaultRequests(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'client_notes':
        return [];
      case 'inspection':
        return [
          'Check brake system',
          'Check suspension',
          'Check engine fluids',
          'Inspect tires',
          'Test lights and signals',
        ];
      case 'test_drive':
        return [
          'Check acceleration',
          'Test braking response',
          'Evaluate steering',
          'Check for unusual noises',
          'Monitor engine performance',
        ];
      default:
        return [];
    }
  }

  // Save requests to Firestore
  Future<void> saveRequests({
    required String documentId,
    required List<String> requests,
    required String collectionName,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId)
          .update({'requests': requests});
    } catch (e) {
      _errorService.logError(
        e,
        context: 'RequestsService.saveRequests',
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  // Get requests from Firestore
  Future<List<String>> getRequests({
    required String documentId,
    required String collectionName,
  }) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(documentId)
              .get();

      if (docSnapshot.exists && docSnapshot.data()!.containsKey('requests')) {
        return List<String>.from(docSnapshot.data()!['requests']);
      }
      return [];
    } catch (e) {
      _errorService.logError(
        e,
        context: 'RequestsService.getRequests',
        stackTrace: StackTrace.current,
      );
      return [];
    }
  }

  // Add a new request to the existing list
  Future<void> addRequest({
    required String documentId,
    required String request,
    required String collectionName,
  }) async {
    try {
      // Get current requests
      final currentRequests = await getRequests(
        documentId: documentId,
        collectionName: collectionName,
      );

      // Add new request if it doesn't exist already
      if (!currentRequests.contains(request)) {
        currentRequests.add(request);

        // Save updated requests
        await saveRequests(
          documentId: documentId,
          requests: currentRequests,
          collectionName: collectionName,
        );
      }
    } catch (e) {
      _errorService.logError(
        e,
        context: 'RequestsService.addRequest',
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  // Remove a request from the list
  Future<void> removeRequest({
    required String documentId,
    required String request,
    required String collectionName,
  }) async {
    try {
      // Get current requests
      final currentRequests = await getRequests(
        documentId: documentId,
        collectionName: collectionName,
      );

      // Remove the request
      currentRequests.remove(request);

      // Save updated requests
      await saveRequests(
        documentId: documentId,
        requests: currentRequests,
        collectionName: collectionName,
      );
    } catch (e) {
      _errorService.logError(
        e,
        context: 'RequestsService.removeRequest',
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}
