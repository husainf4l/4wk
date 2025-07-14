// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:flutter/foundation.dart';
// import 'dart:async';
// import 'cache_service.dart';

// /// Enhanced DatabaseService with comprehensive caching
// class EnhancedDatabaseService extends GetxService {
//   // Firestore instance
//   late final FirebaseFirestore _firestore;

//   // Cache service
//   late final CacheService _cacheService;

//   // Error Service - will be initialized after this service
//   late final dynamic _errorService;

//   // Service initialization status
//   final RxBool isInitialized = false.obs;

//   // Cache configuration
//   static const Duration _defaultCacheDuration = Duration(hours: 6);
//   static const Duration _shortCacheDuration = Duration(minutes: 30);

//   // Initialize the service
//   Future<EnhancedDatabaseService> init() async {
//     try {
//       // Initialize Firestore with settings for better reliability
//       _firestore = FirebaseFirestore.instance;

//       // Get cache service
//       _cacheService = Get.find<CacheService>();

//       // Configure Firestore persistence based on platform
//       if (kIsWeb) {
//         // Web-specific persistence configuration
//         _firestore.settings = Settings(persistenceEnabled: true);
//       } else {
//         // iOS, Android, and other platforms use settings
//         _firestore.settings = Settings(
//           persistenceEnabled: true,
//           cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
//         );
//       }

//       // Skip connection test for faster startup
//       // The app will handle offline scenarios gracefully

//       isInitialized.value = true;
//       debugPrint('Enhanced DatabaseService initialized successfully');
//       return this;
//     } catch (e) {
//       debugPrint('Error initializing Enhanced DatabaseService: $e');
//       isInitialized.value = false;
//       rethrow;
//     }
//   }

//   /// Set error service (called after initialization)
//   void setErrorService(dynamic errorService) {
//     _errorService = errorService;
//   }

//   /// Get a document with caching
//   Future<DocumentSnapshot> getDocument(
//     String collection,
//     String documentId, {
//     Duration? cacheDuration,
//     bool forceRefresh = false,
//   }) async {
//     _checkInitialized();

//     final cacheKey = '${collection}_$documentId';

//     try {
//       // Check cache first unless force refresh
//       if (!forceRefresh) {
//         final cachedData = await _cacheService.get<Map<String, dynamic>>(
//           cacheKey,
//           category: 'documents',
//         );

//         if (cachedData != null) {
//           debugPrint('Returning cached document: $collection/$documentId');
//           return _createDocumentSnapshotFromCache(documentId, cachedData);
//         }
//       }

//       // Fetch from Firestore
//       final doc = await _firestore.collection(collection).doc(documentId).get();

//       // Cache the result if it exists
//       if (doc.exists && doc.data() != null) {
//         await _cacheService.set(
//           cacheKey,
//           doc.data()!,
//           duration: cacheDuration ?? _defaultCacheDuration,
//           category: 'documents',
//         );
//       }

//       return doc;
//     } catch (e) {
//       _logError('Error getting document $documentId from $collection', e);

//       // Try to return cached data as fallback
//       final cachedData = await _cacheService.get<Map<String, dynamic>>(
//         cacheKey,
//         category: 'documents',
//       );

//       if (cachedData != null) {
//         debugPrint(
//           'Returning stale cached document as fallback: $collection/$documentId',
//         );
//         return _createDocumentSnapshotFromCache(documentId, cachedData);
//       }

//       rethrow;
//     }
//   }

//   /// Get multiple documents with caching
//   Future<QuerySnapshot> getCollection(
//     String collection, {
//     Query Function(Query)? queryBuilder,
//     Duration? cacheDuration,
//     bool forceRefresh = false,
//     int? limit,
//   }) async {
//     _checkInitialized();

//     // Create cache key based on query
//     final cacheKey = _generateQueryCacheKey(collection, queryBuilder, limit);

//     try {
//       // Check cache first unless force refresh
//       if (!forceRefresh) {
//         final cachedData = await _cacheService.get<List<dynamic>>(
//           cacheKey,
//           category: 'collections',
//         );

//         if (cachedData != null) {
//           debugPrint(
//             'Returning cached collection: $collection (${cachedData.length} items)',
//           );
//           return _createQuerySnapshotFromCache(cachedData);
//         }
//       }

//       // Build query
//       Query query = _firestore.collection(collection);
//       if (queryBuilder != null) {
//         query = queryBuilder(query);
//       }
//       if (limit != null) {
//         query = query.limit(limit);
//       }

//       // Fetch from Firestore
//       final snapshot = await query.get();

//       // Cache the results
//       final dataToCache =
//           snapshot.docs
//               .map((doc) => {'id': doc.id, 'data': doc.data()})
//               .toList();

//       await _cacheService.set(
//         cacheKey,
//         dataToCache,
//         duration: cacheDuration ?? _shortCacheDuration,
//         category: 'collections',
//       );

//       return snapshot;
//     } catch (e) {
//       _logError('Error getting collection $collection', e);

//       // Try to return cached data as fallback
//       final cachedData = await _cacheService.get<List<dynamic>>(
//         cacheKey,
//         category: 'collections',
//       );

//       if (cachedData != null) {
//         debugPrint(
//           'Returning stale cached collection as fallback: $collection',
//         );
//         return _createQuerySnapshotFromCache(cachedData);
//       }

//       rethrow;
//     }
//   }

//   /// Set a document with cache invalidation
//   Future<void> setDocument(
//     String collection,
//     String documentId,
//     Map<String, dynamic> data, {
//     bool merge = false,
//   }) async {
//     _checkInitialized();

//     try {
//       // Update Firestore
//       await _firestore
//           .collection(collection)
//           .doc(documentId)
//           .set(data, SetOptions(merge: merge));

//       // Update cache
//       final cacheKey = '${collection}_$documentId';
//       await _cacheService.set(
//         cacheKey,
//         data,
//         duration: _defaultCacheDuration,
//         category: 'documents',
//       );

//       // Invalidate related collection caches
//       await _invalidateCollectionCaches(collection);
//     } catch (e) {
//       _logError('Error setting document $documentId in $collection', e);
//       rethrow;
//     }
//   }

//   /// Update a document with cache invalidation
//   Future<void> updateDocument(
//     String collection,
//     String documentId,
//     Map<String, dynamic> data,
//   ) async {
//     _checkInitialized();

//     try {
//       // Update Firestore
//       await _firestore.collection(collection).doc(documentId).update(data);

//       // Update cache if exists
//       final cacheKey = '${collection}_$documentId';
//       final cachedData = await _cacheService.get<Map<String, dynamic>>(
//         cacheKey,
//         category: 'documents',
//       );

//       if (cachedData != null) {
//         cachedData.addAll(data);
//         await _cacheService.set(
//           cacheKey,
//           cachedData,
//           duration: _defaultCacheDuration,
//           category: 'documents',
//         );
//       }

//       // Invalidate related collection caches
//       await _invalidateCollectionCaches(collection);
//     } catch (e) {
//       _logError('Error updating document $documentId in $collection', e);
//       rethrow;
//     }
//   }

//   /// Delete a document with cache invalidation
//   Future<void> deleteDocument(String collection, String documentId) async {
//     _checkInitialized();

//     try {
//       // Delete from Firestore
//       await _firestore.collection(collection).doc(documentId).delete();

//       // Remove from cache
//       final cacheKey = '${collection}_$documentId';
//       await _cacheService.remove(cacheKey, category: 'documents');

//       // Invalidate related collection caches
//       await _invalidateCollectionCaches(collection);
//     } catch (e) {
//       _logError('Error deleting document $documentId from $collection', e);
//       rethrow;
//     }
//   }

//   /// Add a document with cache invalidation
//   Future<DocumentReference> addDocument(
//     String collection,
//     Map<String, dynamic> data,
//   ) async {
//     _checkInitialized();

//     try {
//       // Add to Firestore
//       final docRef = await _firestore.collection(collection).add(data);

//       // Cache the new document
//       final cacheKey = '${collection}_${docRef.id}';
//       await _cacheService.set(
//         cacheKey,
//         data,
//         duration: _defaultCacheDuration,
//         category: 'documents',
//       );

//       // Invalidate related collection caches
//       await _invalidateCollectionCaches(collection);

//       return docRef;
//     } catch (e) {
//       _logError('Error adding document to $collection', e);
//       rethrow;
//     }
//   }

//   /// Stream with intelligent caching
//   Stream<DocumentSnapshot> getUserByUid(String uid) {
//     _checkInitialized();

//     // For streams, we still use Firestore directly but with local cache
//     return _firestore.collection('users').doc(uid).snapshots();
//   }

//   /// Batch operations with cache invalidation
//   Future<void> performBatch(Function(WriteBatch) operations) async {
//     _checkInitialized();

//     try {
//       final batch = _firestore.batch();
//       operations(batch);
//       await batch.commit();

//       // Note: For batch operations, we might want to clear relevant caches
//       // This is a simple approach - more sophisticated cache invalidation
//       // could track which collections are affected
//       debugPrint('Batch operation completed - consider cache refresh');
//     } catch (e) {
//       _logError('Error performing batch operation', e);
//       rethrow;
//     }
//   }

//   /// Clear cache for specific collection
//   Future<void> clearCollectionCache(String collection) async {
//     // Clear all caches related to this collection
//     await _invalidateCollectionCaches(collection);
//   }

//   /// Get cache statistics
//   Map<String, dynamic> getCacheStats() {
//     return _cacheService.getStats().toMap();
//   }

//   // Private helper methods

//   void _checkInitialized() {
//     if (!isInitialized.value) {
//       throw Exception('Enhanced DatabaseService not initialized');
//     }
//   }

//   void _logError(String message, dynamic error) {
//     debugPrint('$message: $error');

//     if (_errorService != null) {
//       try {
//         _errorService.logError(error, context: 'Enhanced DatabaseService');
//       } catch (e) {
//         debugPrint('Error logging to ErrorService: $e');
//       }
//     }
//   }

//   String _generateQueryCacheKey(
//     String collection,
//     Query Function(Query)? queryBuilder,
//     int? limit,
//   ) {
//     // Simple cache key generation - could be more sophisticated
//     var key = 'query_$collection';
//     if (limit != null) {
//       key += '_limit_$limit';
//     }
//     if (queryBuilder != null) {
//       key += '_custom';
//     }
//     return key;
//   }

//   DocumentSnapshot _createDocumentSnapshotFromCache(
//     String documentId,
//     Map<String, dynamic> data,
//   ) {
//     // This would need custom implementation to create a mock DocumentSnapshot
//     // For now, we'll throw an exception to indicate this needs proper implementation
//     throw UnimplementedError(
//       'Document snapshot creation from cache needs implementation',
//     );
//   }

//   QuerySnapshot _createQuerySnapshotFromCache(List<dynamic> cachedData) {
//     // This would need custom implementation to create a mock QuerySnapshot
//     // For now, we'll throw an exception to indicate this needs proper implementation
//     throw UnimplementedError(
//       'Query snapshot creation from cache needs implementation',
//     );
//   }

//   Future<void> _invalidateCollectionCaches(String collection) async {
//     // Simple cache invalidation - remove all collection caches for this collection
//     // More sophisticated implementation would track specific queries
//     await _cacheService.clear(category: 'collections');
//   }
// }

// /// Extension to convert CacheStats to Map
// extension CacheStatsExtension on CacheStats {
//   Map<String, dynamic> toMap() {
//     return {
//       'memory_items': memoryItems,
//       'hive_user_items': hiveUserItems,
//       'hive_data_items': hiveDataItems,
//       'hive_config_items': hiveConfigItems,
//       'total_items': totalItems,
//       'is_online': isOnline,
//     };
//   }
// }
