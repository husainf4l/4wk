import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class DatabaseService extends GetxService {
  // Firestore instance
  late final FirebaseFirestore _firestore;

  // Error Service - will be initialized after this service
  // We don't inject it in the constructor to avoid circular dependencies
  late final dynamic _errorService;

  // Service initialization status
  final RxBool isInitialized = false.obs;

  // Initialize the service
  Future<DatabaseService> init() async {
    try {
      // Initialize Firestore with settings for better reliability
      _firestore = FirebaseFirestore.instance;

      // Configure Firestore persistence based on platform
      // All platforms now use Settings for configuration
      if (kIsWeb) {
        // Web-specific persistence configuration
        _firestore.settings = Settings(
          persistenceEnabled: true,
          // Cache size and other settings can be configured here if needed
        );
      } else {
        // iOS, Android, and other platforms use settings
        _firestore.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      // Verify connection by performing a simple operation
      await _firestore
          .collection('_connection_test')
          .doc('test')
          .set({
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Firestore connection timed out');
            },
          );

      isInitialized.value = true;
      debugPrint('Firestore initialized successfully');
      return this;
    } catch (e) {
      debugPrint('Error initializing Firestore: $e');
      // Still return this service even if there was an error, just mark as not initialized
      return this;
    }
  }

  // Set error service after it's initialized
  void setErrorService(dynamic errorService) {
    _errorService = errorService;
  }

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');

  // Add a new document to a collection
  Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    _checkInitialized();
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      _logError('Error adding document to $collection', e);
      rethrow;
    }
  }

  // Set a document (create or overwrite)
  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    _checkInitialized();
    try {
      return await _firestore.collection(collection).doc(documentId).set(data);
    } catch (e) {
      _logError('Error setting document $documentId in $collection', e);
      rethrow;
    }
  }

  // Update a document
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    _checkInitialized();
    try {
      return await _firestore
          .collection(collection)
          .doc(documentId)
          .update(data);
    } catch (e) {
      _logError('Error updating document $documentId in $collection', e);
      rethrow;
    }
  }

  // Delete a document
  Future<void> deleteDocument(String collection, String documentId) async {
    _checkInitialized();
    try {
      return await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      _logError('Error deleting document $documentId from $collection', e);
      rethrow;
    }
  }

  // Get a single document
  Future<DocumentSnapshot> getDocument(
    String collection,
    String documentId,
  ) async {
    _checkInitialized();
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      _logError('Error getting document $documentId from $collection', e);
      rethrow;
    }
  }

  // Get all documents from a collection
  Stream<QuerySnapshot> getCollection(String collection) {
    _checkInitialized();
    try {
      return _firestore.collection(collection).snapshots();
    } catch (e) {
      _logError('Error getting collection $collection', e);
      rethrow;
    }
  }

  // Get documents with query
  Stream<QuerySnapshot> queryCollection(
    String collection,
    List<List<dynamic>> queryParams,
  ) {
    _checkInitialized();
    try {
      Query query = _firestore.collection(collection);

      for (var param in queryParams) {
        query = query.where(param[0], isEqualTo: param[1]);
      }

      return query.snapshots();
    } catch (e) {
      _logError('Error querying collection $collection', e);
      rethrow;
    }
  }

  // Get user data by UID
  Stream<DocumentSnapshot> getUserByUid(String uid) {
    _checkInitialized();
    try {
      return usersCollection.doc(uid).snapshots();
    } catch (e) {
      _logError('Error getting user by UID $uid', e);
      rethrow;
    }
  }

  // Create or update user data
  Future<void> saveUserData(String uid, Map<String, dynamic> userData) async {
    _checkInitialized();
    try {
      return await usersCollection
          .doc(uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      _logError('Error saving user data for UID $uid', e);
      rethrow;
    }
  }

  // Helper to check if service is initialized
  void _checkInitialized() {
    if (!isInitialized.value) {
      debugPrint('Warning: DatabaseService not properly initialized');
    }
  }

  // Helper to log errors using ErrorService if available
  void _logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (isInitialized.value && Get.isRegistered<dynamic>(tag: 'ErrorService')) {
      try {
        _errorService.logError(
          error,
          context: 'DatabaseService.$message',
          stackTrace: stackTrace ?? StackTrace.current,
        );
      } catch (e) {
        // Fallback to print if ErrorService fails
        debugPrint('$message: $error');
        if (stackTrace != null) debugPrint(stackTrace.toString());
      }
    } else {
      // Fallback to print if ErrorService not available
      debugPrint('$message: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }
}
