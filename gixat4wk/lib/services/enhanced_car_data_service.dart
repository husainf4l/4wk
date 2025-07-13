import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'cache_service.dart';

class EnhancedCarDataService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CacheService _cacheService = Get.find<CacheService>();

  // Cache keys
  static const String _makesCacheKey = 'car_makes_list';
  static const String _modelsCachePrefix = 'car_models_';

  // Cache durations
  static const Duration _makesCacheDuration = Duration(hours: 24);
  static const Duration _modelsCacheDuration = Duration(hours: 12);

  /// Fetch car makes with multi-level caching
  Future<List<String>> fetchCarMakes() async {
    try {
      // First check cache
      final cachedMakes = await _cacheService.get<List<dynamic>>(
        _makesCacheKey,
      );
      if (cachedMakes != null) {
        debugPrint('Returning cached car makes: ${cachedMakes.length} items');
        return cachedMakes.cast<String>();
      }

      debugPrint('Fetching car makes from Firestore...');
      final snapshot = await _firestore.collection('car_makes').get();
      debugPrint('Found ${snapshot.docs.length} car make documents');

      final makes = snapshot.docs.map((doc) => doc.id).toList();
      makes.sort(); // Sort alphabetically for better UX

      // Cache the results
      await _cacheService.set(
        _makesCacheKey,
        makes,
        duration: _makesCacheDuration,
        category: 'car_data',
      );

      debugPrint('Car makes cached: ${makes.length} items');
      return makes;
    } catch (e) {
      debugPrint('Error in fetchCarMakes: $e');

      // Try to return any cached data as fallback
      final fallbackMakes = await _cacheService.get<List<dynamic>>(
        _makesCacheKey,
      );
      return fallbackMakes?.cast<String>() ?? [];
    }
  }

  /// Fetch car models with multi-level caching
  Future<List<String>> fetchCarModels(String make) async {
    try {
      final cacheKey = '$_modelsCachePrefix$make';

      // First check cache
      final cachedModels = await _cacheService.get<List<dynamic>>(cacheKey);
      if (cachedModels != null) {
        debugPrint(
          'Returning cached models for $make: ${cachedModels.length} items',
        );
        return cachedModels.cast<String>();
      }

      debugPrint('Fetching models for make: $make');
      final doc = await _firestore.collection('car_makes').doc(make).get();
      debugPrint('Document exists: ${doc.exists}');

      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('models')) {
        final models = doc.data()!['models'] as List<dynamic>;
        final modelList = models.cast<String>();
        modelList.sort(); // Sort alphabetically for better UX

        // Cache the results
        await _cacheService.set(
          cacheKey,
          modelList,
          duration: _modelsCacheDuration,
          category: 'car_data',
        );

        debugPrint('Models for $make cached: ${modelList.length} items');
        return modelList;
      }

      debugPrint('No models found for $make');
      return [];
    } catch (e) {
      debugPrint('Error in fetchCarModels: $e');

      // Try to return any cached data as fallback
      final cacheKey = '$_modelsCachePrefix$make';
      final fallbackModels = await _cacheService.get<List<dynamic>>(cacheKey);
      return fallbackModels?.cast<String>() ?? [];
    }
  }

  /// Add car make and model with cache invalidation
  Future<void> addCarMakeAndModel(String make, String model) async {
    try {
      debugPrint('Adding make: $make, model: $model to Firestore');
      final docRef = _firestore.collection('car_makes').doc(make);
      final doc = await docRef.get();

      if (doc.exists) {
        final List<dynamic> models = doc.data()!['models'] ?? [];
        if (!models.contains(model)) {
          await docRef.update({
            'models': FieldValue.arrayUnion([model]),
          });
          debugPrint('Added model $model to existing make $make');

          // Invalidate and update cache
          await _invalidateModelCache(make);
          await _updateMakesCacheAfterAdd(make);
        } else {
          debugPrint('Model $model already exists for make $make');
        }
      } else {
        // Create new make document with the model
        await docRef.set({
          'models': [model],
        });
        debugPrint('Created new make $make with model $model');

        // Invalidate and update caches
        await _invalidateMakesCache();
        await _updateMakesCacheAfterAdd(make);
      }
    } catch (e) {
      debugPrint('Error in addCarMakeAndModel: $e');
      rethrow;
    }
  }

  /// Preload popular car data in background
  Future<void> preloadPopularCarData() async {
    try {
      // Preload makes
      final makes = await fetchCarMakes();

      // Preload models for popular makes
      final popularMakes = ['Toyota', 'Honda', 'BMW', 'Mercedes-Benz', 'Audi'];
      for (final make in popularMakes) {
        if (makes.contains(make)) {
          fetchCarModels(make); // Fire and forget
        }
      }

      debugPrint('Preloaded popular car data');
    } catch (e) {
      debugPrint('Error preloading car data: $e');
    }
  }

  /// Search car makes with caching
  Future<List<String>> searchCarMakes(String query) async {
    try {
      final allMakes = await fetchCarMakes();
      final filteredMakes =
          allMakes
              .where((make) => make.toLowerCase().contains(query.toLowerCase()))
              .toList();

      return filteredMakes;
    } catch (e) {
      debugPrint('Error searching car makes: $e');
      return [];
    }
  }

  /// Search car models with caching
  Future<List<String>> searchCarModels(String make, String query) async {
    try {
      final allModels = await fetchCarModels(make);
      final filteredModels =
          allModels
              .where(
                (model) => model.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

      return filteredModels;
    } catch (e) {
      debugPrint('Error searching car models: $e');
      return [];
    }
  }

  /// Clear all car data cache
  Future<void> clearCache() async {
    try {
      await _cacheService.clear(category: 'car_data');
      debugPrint('Car data cache cleared');
    } catch (e) {
      debugPrint('Error clearing car data cache: $e');
    }
  }

  /// Get cache statistics for car data
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final makesExists = await _cacheService.has(_makesCacheKey);
      final stats = _cacheService.getStats();

      return {
        'makes_cached': makesExists,
        'total_cache_items': stats.totalItems,
        'memory_items': stats.memoryItems,
        'is_online': stats.isOnline,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }

  // Private helper methods

  /// Invalidate makes cache
  Future<void> _invalidateMakesCache() async {
    await _cacheService.remove(_makesCacheKey, category: 'car_data');
  }

  /// Invalidate models cache for specific make
  Future<void> _invalidateModelCache(String make) async {
    final cacheKey = '$_modelsCachePrefix$make';
    await _cacheService.remove(cacheKey, category: 'car_data');
  }

  /// Update makes cache after adding a new make
  Future<void> _updateMakesCacheAfterAdd(String newMake) async {
    try {
      final cachedMakes = await _cacheService.get<List<dynamic>>(
        _makesCacheKey,
      );
      if (cachedMakes != null) {
        final makesList = cachedMakes.cast<String>();
        if (!makesList.contains(newMake)) {
          makesList.add(newMake);
          makesList.sort();

          await _cacheService.set(
            _makesCacheKey,
            makesList,
            duration: _makesCacheDuration,
            category: 'car_data',
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating makes cache: $e');
    }
  }

  /// Refresh car data in background
  Future<void> refreshCarDataInBackground() async {
    Future.microtask(() async {
      try {
        // Clear cache and refetch
        await clearCache();
        await fetchCarMakes();
        await preloadPopularCarData();
        debugPrint('Car data refreshed in background');
      } catch (e) {
        debugPrint('Error refreshing car data: $e');
      }
    });
  }
}
