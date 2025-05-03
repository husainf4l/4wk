import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'error_service.dart';

/// A generic service for handling Firestore document operations.
/// This service provides a standard interface for creating, reading, updating and deleting
/// documents across different collections.
class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ErrorService _errorService = Get.find<ErrorService>(
    tag: 'ErrorService',
  );

  /// Create a new document in the specified collection
  Future<String?> createDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      // Add timestamp if not present
      if (!data.containsKey('timestamp')) {
        data['timestamp'] = FieldValue.serverTimestamp();
      }

      if (documentId != null) {
        // Use provided document ID
        await _firestore.collection(collectionPath).doc(documentId).set(data);
        return documentId;
      } else {
        // Let Firestore generate a document ID
        final docRef = await _firestore.collection(collectionPath).add(data);
        return docRef.id;
      }
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'DocumentService.createDocument',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get a document by its ID
  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String documentId,
  }) async {
    try {
      final docSnapshot =
          await _firestore.collection(collectionPath).doc(documentId).get();

      if (docSnapshot.exists) {
        // Return data with document ID included
        return {'id': docSnapshot.id, ...docSnapshot.data()!};
      }
      return null;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'DocumentService.getDocument',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> queryDocuments({
    required String collectionPath,
    required List<QueryFilter> filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collectionPath);

      // Apply filters
      for (final filter in filters) {
        query = filter.applyFilter(query);
      }

      // Apply ordering if specified
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit if specified
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      // Map documents to a list of maps with ID included
      return querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'DocumentService.queryDocuments',
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Update an existing document
  Future<bool> updateDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      // Add update timestamp if not present
      if (!data.containsKey('updatedAt')) {
        data['updatedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(collectionPath)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));

      return true;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'DocumentService.updateDocument',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument({
    required String collectionPath,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).delete();
      return true;
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'DocumentService.deleteDocument',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Listen to a document for real-time updates
  Stream<Map<String, dynamic>?> documentStream({
    required String collectionPath,
    required String documentId,
  }) {
    try {
      return _firestore
          .collection(collectionPath)
          .doc(documentId)
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists) {
              return {'id': snapshot.id, ...snapshot.data()!};
            }
            return null;
          })
          .handleError((e, stackTrace) {
            _errorService.logError(
              e,
              context: 'DocumentService.documentStream',
              stackTrace: stackTrace,
            );
            return null;
          });
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'DocumentService.documentStream',
        stackTrace: stackTrace,
      );
      // Return an empty stream
      return Stream.value(null);
    }
  }

  /// Listen to a collection query for real-time updates
  Stream<List<Map<String, dynamic>>> queryStream({
    required String collectionPath,
    required List<QueryFilter> filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      Query query = _firestore.collection(collectionPath);

      // Apply filters
      for (final filter in filters) {
        query = filter.applyFilter(query);
      }

      // Apply ordering if specified
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit if specified
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
              context: 'DocumentService.queryStream',
              stackTrace: stackTrace,
            );
            return <Map<String, dynamic>>[];
          });
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'DocumentService.queryStream',
        stackTrace: stackTrace,
      );
      // Return an empty stream
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }
}

/// Class for defining query filters to be applied to Firestore queries
class QueryFilter {
  final String field;
  final dynamic value;
  final FilterOperator operator;

  QueryFilter({
    required this.field,
    required this.value,
    required this.operator,
  });

  Query applyFilter(Query query) {
    switch (operator) {
      case FilterOperator.isEqualTo:
        return query.where(field, isEqualTo: value);
      case FilterOperator.isNotEqualTo:
        return query.where(field, isNotEqualTo: value);
      case FilterOperator.isLessThan:
        return query.where(field, isLessThan: value);
      case FilterOperator.isLessThanOrEqualTo:
        return query.where(field, isLessThanOrEqualTo: value);
      case FilterOperator.isGreaterThan:
        return query.where(field, isGreaterThan: value);
      case FilterOperator.isGreaterThanOrEqualTo:
        return query.where(field, isGreaterThanOrEqualTo: value);
      case FilterOperator.arrayContains:
        return query.where(field, arrayContains: value);
      case FilterOperator.arrayContainsAny:
        return query.where(field, arrayContainsAny: value);
      case FilterOperator.whereIn:
        return query.where(field, whereIn: value);
      case FilterOperator.whereNotIn:
        return query.where(field, whereNotIn: value);
    }
  }
}

/// Enum for Firestore query operators
enum FilterOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}
