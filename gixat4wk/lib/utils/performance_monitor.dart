// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'dart:async';
// import 'dart:io';

// /// Performance monitoring utility for tracking app performance
// class PerformanceMonitor extends GetxService {
//   static final PerformanceMonitor _instance = PerformanceMonitor._internal();
//   factory PerformanceMonitor() => _instance;
//   PerformanceMonitor._internal();

//   final Map<String, DateTime> _startTimes = {};
//   final Map<String, Duration> _durations = {};
//   final RxMap<String, dynamic> metrics = <String, dynamic>{}.obs;

//   Timer? _memoryMonitorTimer;

//   @override
//   void onInit() {
//     super.onInit();
//     _startMemoryMonitoring();
//     _trackAppLifecycle();
//   }

//   /// Start timing an operation
//   void startTimer(String operation) {
//     _startTimes[operation] = DateTime.now();
//     debugPrint('⏱ Started timing: $operation');
//   }

//   /// End timing an operation and record the duration
//   Duration endTimer(String operation) {
//     final startTime = _startTimes[operation];
//     if (startTime == null) {
//       debugPrint('⚠️ No start time found for operation: $operation');
//       return Duration.zero;
//     }

//     final duration = DateTime.now().difference(startTime);
//     _durations[operation] = duration;
//     _startTimes.remove(operation);

//     metrics[operation] = duration.inMilliseconds;

//     debugPrint('✅ Completed $operation in ${duration.inMilliseconds}ms');
//     return duration;
//   }

//   /// Track memory usage
//   void _startMemoryMonitoring() {
//     if (kDebugMode) {
//       _memoryMonitorTimer = Timer.periodic(
//         const Duration(seconds: 30),
//         (timer) => _recordMemoryUsage(),
//       );
//     }
//   }

//   /// Record current memory usage
//   void _recordMemoryUsage() {
//     if (kDebugMode && !kIsWeb) {
//       try {
//         // This is a simplified approach - in production you'd use more sophisticated monitoring
//         final info = ProcessInfo.currentRss;
//         metrics['memory_usage_mb'] = (info / 1024 / 1024).round();
//         debugPrint('📊 Memory Usage: ${metrics['memory_usage_mb']} MB');
//       } catch (e) {
//         debugPrint('Error recording memory usage: $e');
//       }
//     }
//   }

//   /// Track app lifecycle events
//   void _trackAppLifecycle() {
//     // Track app startup time
//     metrics['app_startup_time'] = DateTime.now().millisecondsSinceEpoch;
//   }

//   /// Record network request performance
//   void recordNetworkRequest(
//     String endpoint,
//     Duration duration,
//     bool fromCache,
//   ) {
//     final key = 'network_${endpoint.replaceAll('/', '_')}';
//     metrics[key] = {
//       'duration_ms': duration.inMilliseconds,
//       'from_cache': fromCache,
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//     };

//     debugPrint(
//       '🌐 Network request to $endpoint: ${duration.inMilliseconds}ms (cache: $fromCache)',
//     );
//   }

//   /// Record cache hit/miss statistics
//   void recordCachePerformance(String operation, bool hit, Duration duration) {
//     final key = 'cache_$operation';
//     final existing =
//         metrics[key] as Map<String, dynamic>? ??
//         {'hits': 0, 'misses': 0, 'total_duration_ms': 0};

//     if (hit) {
//       existing['hits'] = (existing['hits'] as int) + 1;
//     } else {
//       existing['misses'] = (existing['misses'] as int) + 1;
//     }

//     existing['total_duration_ms'] =
//         (existing['total_duration_ms'] as int) + duration.inMilliseconds;
//     existing['hit_rate'] =
//         (existing['hits'] / (existing['hits'] + existing['misses']) * 100)
//             .round();

//     metrics[key] = existing;

//     debugPrint(
//       '💾 Cache $operation: ${hit ? 'HIT' : 'MISS'} (${duration.inMilliseconds}ms)',
//     );
//   }

//   /// Record UI frame performance
//   void recordFramePerformance(Duration frameTime) {
//     if (frameTime.inMilliseconds > 16) {
//       // Dropped frame threshold
//       metrics['dropped_frames'] = (metrics['dropped_frames'] as int? ?? 0) + 1;
//       debugPrint('🎨 Dropped frame detected: ${frameTime.inMilliseconds}ms');
//     }

//     // Update average frame time
//     final currentAvg = metrics['avg_frame_time_ms'] as double? ?? 16.0;
//     final newAvg = (currentAvg + frameTime.inMilliseconds) / 2;
//     metrics['avg_frame_time_ms'] = newAvg.round();
//   }

//   /// Get performance summary
//   Map<String, dynamic> getPerformanceSummary() {
//     final summary = <String, dynamic>{
//       'metrics': Map.from(metrics),
//       'durations': _durations.map(
//         (key, value) => MapEntry(key, value.inMilliseconds),
//       ),
//       'timestamp': DateTime.now().toIso8601String(),
//     };

//     return summary;
//   }

//   /// Export performance data for analysis
//   String exportPerformanceData() {
//     return '''
// # Performance Report - ${DateTime.now()}

// ## Service Initialization Times
// ${_durations.entries.map((e) => '- ${e.key}: ${e.value.inMilliseconds}ms').join('\n')}

// ## Current Metrics
// ${metrics.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

// ## Summary
// - Total services: ${_durations.length}
// - Memory usage: ${metrics['memory_usage_mb'] ?? 'N/A'} MB
// - Cache hit rate: ${_calculateOverallCacheHitRate()}%
// - Dropped frames: ${metrics['dropped_frames'] ?? 0}
// ''';
//   }

//   /// Calculate overall cache hit rate
//   double _calculateOverallCacheHitRate() {
//     int totalHits = 0;
//     int totalRequests = 0;

//     for (final entry in metrics.entries) {
//       if (entry.key.startsWith('cache_') && entry.value is Map) {
//         final cacheData = entry.value as Map<String, dynamic>;
//         totalHits += (cacheData['hits'] as int? ?? 0);
//         totalRequests +=
//             (cacheData['hits'] as int? ?? 0) +
//             (cacheData['misses'] as int? ?? 0);
//       }
//     }

//     return totalRequests > 0 ? (totalHits / totalRequests * 100) : 0.0;
//   }

//   /// Reset all metrics
//   void resetMetrics() {
//     _startTimes.clear();
//     _durations.clear();
//     metrics.clear();
//     debugPrint('🔄 Performance metrics reset');
//   }

//   @override
//   void onClose() {
//     _memoryMonitorTimer?.cancel();
//     super.onClose();
//   }
// }

// /// Extension for easy performance monitoring
// extension PerformanceExtension<T> on Future<T> {
//   Future<T> trackPerformance(String operation) async {
//     final monitor = PerformanceMonitor();
//     monitor.startTimer(operation);

//     try {
//       final result = await this;
//       monitor.endTimer(operation);
//       return result;
//     } catch (e) {
//       monitor.endTimer(operation);
//       rethrow;
//     }
//   }
// }
