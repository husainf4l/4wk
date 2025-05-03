import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'database_service.dart';

class ErrorService extends GetxService {
  // Database service for Firestore operations
  late final DatabaseService _databaseService;

  // Collection name for error logs
  static const String _errorCollection = 'error_logs';

  // Device info plugin for collecting device information
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Package info for app version details
  PackageInfo? _packageInfo;

  // Initialize the service
  Future<ErrorService> init() async {
    try {
      // Get the database service
      _databaseService = Get.find<DatabaseService>();

      // Get package info for app version details
      _packageInfo = await PackageInfo.fromPlatform();
      return this;
    } catch (e) {
      debugPrint('Error initializing ErrorService: $e');
      return this;
    }
  }

  Future<void> logError(
    dynamic error, {
    required String context,
    String? userId,
    StackTrace? stackTrace,
  }) async {
    try {
      // Debug print for development environment
      if (kDebugMode) {
        debugPrint('ERROR in $context: $error');
        if (stackTrace != null) debugPrint(stackTrace.toString());
      }

      final Map<String, dynamic> errorData = {
        'timestamp': FieldValue.serverTimestamp(),
        'error': error.toString(),
        'context': context,
        'userId': userId ?? 'unknown',
        'stackTrace': stackTrace?.toString(),
        'appInfo': await _getAppInfo(),
        'deviceInfo': await _getDeviceInfo(),
      };

      // Add error to Firestore
      await _databaseService.addDocument(_errorCollection, errorData);
    } catch (e) {
      // If error logging fails, fall back to debug print
      debugPrint('Error logging error to Firestore: $e');
    }
  }

  /// Get application information
  Future<Map<String, dynamic>> _getAppInfo() async {
    if (_packageInfo == null) {
      try {
        _packageInfo = await PackageInfo.fromPlatform();
      } catch (e) {
        return {'error': 'Could not retrieve package info'};
      }
    }

    return {
      'appName': _packageInfo?.appName ?? 'unknown',
      'packageName': _packageInfo?.packageName ?? 'unknown',
      'version': _packageInfo?.version ?? 'unknown',
      'buildNumber': _packageInfo?.buildNumber ?? 'unknown',
    };
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (kIsWeb) {
        // Web platform
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'platform': 'web',
          'browserName': webInfo.browserName.name,
          'userAgent': webInfo.userAgent,
          'language': webInfo.language,
          'vendor': webInfo.vendor,
        };
      } else if (Platform.isAndroid) {
        // Android platform
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        // iOS platform
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
        };
      } else if (Platform.isMacOS) {
        // macOS platform
        final macOsInfo = await _deviceInfo.macOsInfo;
        return {
          'platform': 'macos',
          'model': macOsInfo.model,
          'computerName': macOsInfo.computerName,
          'osRelease': macOsInfo.osRelease,
          'arch': macOsInfo.arch,
        };
      } else {
        // Other platforms
        return {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
    } catch (e) {
      return {
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'errorGettingDeviceInfo': e.toString(),
      };
    }
  }
}
