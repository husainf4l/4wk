import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:async';

/// Comprehensive caching service with multiple layers
/// Layer 1: Memory cache (fastest)
/// Layer 2: Hive cache (local storage)
/// Layer 3: SharedPreferences (backup)
class CacheService extends GetxService {
  // Memory cache for immediate access
  static final Map<String, CacheItem> _memoryCache = {};

  // Hive boxes for different data types
  static Box<dynamic>? _userBox;
  static Box<dynamic>? _dataBox;
  static Box<dynamic>? _configBox;

  // SharedPreferences instance
  static SharedPreferences? _prefs;

  // Connectivity stream
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final RxBool isOnline = true.obs;

  // Cache configuration
  static const Duration defaultCacheDuration = Duration(hours: 24);
  static const Duration shortCacheDuration = Duration(minutes: 30);
  static const Duration longCacheDuration = Duration(days: 7);
  static const int maxMemoryCacheSize = 100;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Initialize essential parts first, then background init the rest
    await _initializeEssentialCache();
    _initializeFullCacheInBackground();
  }

  /// Initialize only essential cache components for faster startup
  Future<void> _initializeEssentialCache() async {
    try {
      // Initialize Hive (essential)
      await Hive.initFlutter();

      // Initialize SharedPreferences (essential for critical data)
      _prefs = await SharedPreferences.getInstance();

      // Setup basic connectivity (essential)
      _setupConnectivityListener();

      debugPrint('Essential cache initialized');
    } catch (e) {
      debugPrint('Error initializing essential cache: $e');
    }
  }

  /// Initialize full cache system in background
  void _initializeFullCacheInBackground() {
    Future.microtask(() async {
      try {
        // Open Hive boxes (can be slower)
        _userBox = await Hive.openBox('user_cache');
        _dataBox = await Hive.openBox('data_cache');
        _configBox = await Hive.openBox('config_cache');

        // Clean expired cache entries on startup
        await _cleanExpiredCache();

        debugPrint('Full cache system initialized');
      } catch (e) {
        debugPrint('Error initializing full cache: $e');
      }
    });
  }

  /// Initialize all cache layers (original method - now split)
  Future<void> _initializeCache() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Open Hive boxes
      _userBox = await Hive.openBox('user_cache');
      _dataBox = await Hive.openBox('data_cache');
      _configBox = await Hive.openBox('config_cache');

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Clean expired cache entries on startup
      await _cleanExpiredCache();

      debugPrint('CacheService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CacheService: $e');
    }
  }

  /// Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      isOnline.value = results.any(
        (result) => result != ConnectivityResult.none,
      );
    });
  }

  /// Store data in cache with multiple layers
  Future<void> set<T>(
    String key,
    T value, {
    Duration? duration,
    CacheLevel level = CacheLevel.all,
    String? category,
  }) async {
    final cacheItem = CacheItem(
      data: value,
      timestamp: DateTime.now(),
      duration: duration ?? defaultCacheDuration,
      category: category,
    );

    // Always store in memory for immediate access
    if (level.includesMemory) {
      _setMemoryCache(key, cacheItem);
    }

    // Store in Hive for persistence
    if (level.includesLocal) {
      await _setHiveCache(key, cacheItem, category);
    }

    // Backup in SharedPreferences for critical data
    if (level.includesSharedPrefs) {
      await _setSharedPrefsCache(key, cacheItem);
    }
  }

  /// Get data from cache (checks all layers)
  Future<T?> get<T>(String key, {String? category}) async {
    // First check memory cache
    final memoryCacheItem = _memoryCache[key];
    if (memoryCacheItem != null && !memoryCacheItem.isExpired) {
      return memoryCacheItem.data as T?;
    }

    // Then check Hive cache
    final hiveCacheItem = await _getHiveCache(key, category);
    if (hiveCacheItem != null && !hiveCacheItem.isExpired) {
      // Store back in memory for future quick access
      _setMemoryCache(key, hiveCacheItem);
      return hiveCacheItem.data as T?;
    }

    // Finally check SharedPreferences
    final prefsCacheItem = await _getSharedPrefsCache(key);
    if (prefsCacheItem != null && !prefsCacheItem.isExpired) {
      // Store back in memory and Hive
      _setMemoryCache(key, prefsCacheItem);
      await _setHiveCache(key, prefsCacheItem, category);
      return prefsCacheItem.data as T?;
    }

    return null;
  }

  /// Check if data exists in cache and is not expired
  Future<bool> has(String key, {String? category}) async {
    return await get<dynamic>(key, category: category) != null;
  }

  /// Remove data from all cache layers
  Future<void> remove(String key, {String? category}) async {
    // Remove from memory
    _memoryCache.remove(key);

    // Remove from Hive
    final box = _getHiveBox(category);
    await box?.delete(key);

    // Remove from SharedPreferences
    await _prefs?.remove(key);
  }

  /// Clear all cache or specific category
  Future<void> clear({String? category}) async {
    if (category != null) {
      // Clear specific category
      _memoryCache.removeWhere((key, value) => value.category == category);
      final box = _getHiveBox(category);
      await box?.clear();
    } else {
      // Clear all cache
      _memoryCache.clear();
      await _userBox?.clear();
      await _dataBox?.clear();
      await _configBox?.clear();
      await _prefs?.clear();
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    return CacheStats(
      memoryItems: _memoryCache.length,
      hiveUserItems: _userBox?.length ?? 0,
      hiveDataItems: _dataBox?.length ?? 0,
      hiveConfigItems: _configBox?.length ?? 0,
      isOnline: isOnline.value,
    );
  }

  /// Pre-load critical data in background
  Future<void> preloadCriticalData() async {
    // This method can be called to preload important data
    // Implementation depends on specific app needs
    debugPrint('Preloading critical data...');
  }

  // Private helper methods

  void _setMemoryCache(String key, CacheItem item) {
    // Implement LRU eviction if cache is full
    if (_memoryCache.length >= maxMemoryCacheSize) {
      final oldestKey =
          _memoryCache.entries
              .reduce(
                (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b,
              )
              .key;
      _memoryCache.remove(oldestKey);
    }
    _memoryCache[key] = item;
  }

  Future<void> _setHiveCache(
    String key,
    CacheItem item,
    String? category,
  ) async {
    try {
      final box = _getHiveBox(category);
      await box?.put(key, {
        'data': item.data,
        'timestamp': item.timestamp.millisecondsSinceEpoch,
        'duration': item.duration.inMilliseconds,
        'category': item.category,
      });
    } catch (e) {
      debugPrint('Error setting Hive cache: $e');
    }
  }

  Future<CacheItem?> _getHiveCache(String key, String? category) async {
    try {
      final box = _getHiveBox(category);
      final data = box?.get(key);
      if (data != null && data is Map) {
        return CacheItem(
          data: data['data'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
          duration: Duration(milliseconds: data['duration']),
          category: data['category'],
        );
      }
    } catch (e) {
      debugPrint('Error getting Hive cache: $e');
    }
    return null;
  }

  Future<void> _setSharedPrefsCache(String key, CacheItem item) async {
    try {
      final jsonData = jsonEncode({
        'data': item.data,
        'timestamp': item.timestamp.millisecondsSinceEpoch,
        'duration': item.duration.inMilliseconds,
        'category': item.category,
      });
      await _prefs?.setString(key, jsonData);
    } catch (e) {
      debugPrint('Error setting SharedPrefs cache: $e');
    }
  }

  Future<CacheItem?> _getSharedPrefsCache(String key) async {
    try {
      final jsonData = _prefs?.getString(key);
      if (jsonData != null) {
        final data = jsonDecode(jsonData);
        return CacheItem(
          data: data['data'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
          duration: Duration(milliseconds: data['duration']),
          category: data['category'],
        );
      }
    } catch (e) {
      debugPrint('Error getting SharedPrefs cache: $e');
    }
    return null;
  }

  Box<dynamic>? _getHiveBox(String? category) {
    switch (category) {
      case 'user':
        return _userBox;
      case 'config':
        return _configBox;
      default:
        return _dataBox;
    }
  }

  Future<void> _cleanExpiredCache() async {
    // Clean memory cache
    _memoryCache.removeWhere((key, value) => value.isExpired);

    // Clean Hive boxes
    for (final box in [_userBox, _dataBox, _configBox]) {
      if (box != null) {
        final keysToDelete = <String>[];
        for (final key in box.keys) {
          final data = box.get(key);
          if (data is Map &&
              data.containsKey('timestamp') &&
              data.containsKey('duration')) {
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
              data['timestamp'],
            );
            final duration = Duration(milliseconds: data['duration']);
            if (DateTime.now().difference(timestamp) > duration) {
              keysToDelete.add(key.toString());
            }
          }
        }
        for (final key in keysToDelete) {
          await box.delete(key);
        }
      }
    }
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}

/// Cache item wrapper
class CacheItem {
  final dynamic data;
  final DateTime timestamp;
  final Duration duration;
  final String? category;

  CacheItem({
    required this.data,
    required this.timestamp,
    required this.duration,
    this.category,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > duration;
}

/// Cache level configuration
enum CacheLevel {
  memoryOnly,
  localOnly,
  sharedPrefsOnly,
  memoryAndLocal,
  all;

  bool get includesMemory =>
      this == CacheLevel.memoryOnly ||
      this == CacheLevel.memoryAndLocal ||
      this == CacheLevel.all;

  bool get includesLocal =>
      this == CacheLevel.localOnly ||
      this == CacheLevel.memoryAndLocal ||
      this == CacheLevel.all;

  bool get includesSharedPrefs =>
      this == CacheLevel.sharedPrefsOnly || this == CacheLevel.all;
}

/// Cache statistics
class CacheStats {
  final int memoryItems;
  final int hiveUserItems;
  final int hiveDataItems;
  final int hiveConfigItems;
  final bool isOnline;

  CacheStats({
    required this.memoryItems,
    required this.hiveUserItems,
    required this.hiveDataItems,
    required this.hiveConfigItems,
    required this.isOnline,
  });

  int get totalItems =>
      memoryItems + hiveUserItems + hiveDataItems + hiveConfigItems;
}
