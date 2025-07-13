import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_page.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/garage_setup_screen.dart';
import 'theme/app_theme.dart';
import 'services/enhanced_database_service.dart';
import 'services/enhanced_car_data_service.dart';
import 'services/error_service.dart';
import 'services/image_handling_service.dart';
import 'services/chat_service.dart';
import 'services/cache_service.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Start the app immediately with a loading screen
  runApp(const FastBootApp());
}

/// Fast boot app that shows immediately
class FastBootApp extends StatelessWidget {
  const FastBootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '4wk App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const BootstrapScreen(),
    );
  }
}

/// Bootstrap screen that handles initialization
class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  final RxString _status = 'Starting app...'.obs;
  final RxDouble _progress = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.car_repair, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              '4WK Garage',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Obx(() => Text(_status.value)),
            const SizedBox(height: 16),
            Obx(() => LinearProgressIndicator(value: _progress.value)),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Step 1: Essential services only
      _updateProgress(0.3, 'Initializing Firebase...');
      await _initializeEssentialServices();

      // Step 2: Navigate to auth wrapper quickly
      _updateProgress(1.0, 'Ready!');
      await Future.delayed(const Duration(milliseconds: 200));

      Get.offAll(() => const AuthWrapper());

      // Step 3: Initialize remaining services in background
      _initializeRemainingServicesInBackground();
    } catch (e, stackTrace) {
      debugPrint('Error during bootstrap: $e');
      await _handleInitializationError(e, stackTrace);
      Get.offAll(() => const ErrorApp());
    }
  }

  void _updateProgress(double progress, String status) {
    _progress.value = progress;
    _status.value = status;
  }

  /// Initialize only essential services for fast startup
  Future<void> _initializeEssentialServices() async {
    try {
      // Only initialize what's absolutely necessary for auth
      final futures = <Future>[];

      // Firebase (essential for auth)
      futures.add(
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      );

      // Cache service (fast to initialize)
      futures.add(
        Future.microtask(() async {
          final service = CacheService();
          await service.onInit();
          Get.put(service, permanent: true);
          return service;
        }),
      );

      // Environment variables (optional, fast)
      futures.add(_loadEnvironmentVariables());

      await Future.wait(futures);

      // Minimal auth controller setup
      Get.put(AuthController(), permanent: true);

      debugPrint('Essential services initialized');
    } catch (e) {
      debugPrint('Error initializing essential services: $e');
      rethrow;
    }
  }

  /// Initialize remaining services in background after UI is shown
  void _initializeRemainingServicesInBackground() {
    Future.microtask(() async {
      try {
        debugPrint('Starting background service initialization...');

        // Initialize non-critical services with timeouts
        final futures = <Future>[];

        // Error service
        futures.add(
          Get.putAsync(
            () => ErrorService().init().timeout(const Duration(seconds: 10)),
            tag: 'ErrorService',
          ),
        );

        // Enhanced database service
        futures.add(
          Get.putAsync(
            () => EnhancedDatabaseService().init().timeout(
              const Duration(seconds: 15),
            ),
          ),
        );

        // Image handling service (lightweight)
        futures.add(
          Future.microtask(() {
            Get.put(ImageHandlingService(), permanent: true);
            return ImageHandlingService();
          }),
        );

        // Car data service
        futures.add(
          Future.microtask(() {
            Get.put(EnhancedCarDataService(), permanent: true);
            return EnhancedCarDataService();
          }),
        );

        await Future.wait(futures);

        // Chat service (can be slower, initialize last)
        try {
          await Get.putAsync(
            () => ChatService().init().timeout(const Duration(seconds: 20)),
          );
        } catch (e) {
          debugPrint('Chat service failed to initialize: $e');
        }

        // Connect services
        _connectServices();

        // Preload critical data
        _preloadCriticalDataInBackground();

        debugPrint('Background services initialized successfully');
      } catch (e, stackTrace) {
        debugPrint('Error initializing background services: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    });
  }

  void _connectServices() {
    try {
      if (Get.isRegistered<EnhancedDatabaseService>() &&
          Get.isRegistered<ErrorService>(tag: 'ErrorService')) {
        final databaseService = Get.find<EnhancedDatabaseService>();
        final errorService = Get.find<ErrorService>(tag: 'ErrorService');
        databaseService.setErrorService(errorService);
      }
    } catch (e) {
      debugPrint('Error connecting services: $e');
    }
  }

  /// Preload critical data in background
  void _preloadCriticalDataInBackground() {
    Future.microtask(() async {
      try {
        if (Get.isRegistered<CacheService>()) {
          final cacheService = Get.find<CacheService>();
          await cacheService.preloadCriticalData();
        }

        if (Get.isRegistered<EnhancedCarDataService>()) {
          final carDataService = Get.find<EnhancedCarDataService>();
          await carDataService.preloadPopularCarData();
        }

        debugPrint('Critical data preloaded');
      } catch (e) {
        debugPrint('Error preloading critical data: $e');
      }
    });
  }
}

/// Load environment variables with error handling
Future<void> _loadEnvironmentVariables() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Environment file is optional, continue without it
    debugPrint('Environment file not found, continuing without it: $e');
  }
}

/// Enhanced error handling during initialization
Future<void> _handleInitializationError(
  dynamic e,
  StackTrace stackTrace,
) async {
  try {
    // Try to log error if ErrorService is available
    if (Get.isRegistered<ErrorService>(tag: 'ErrorService')) {
      final errorService = Get.find<ErrorService>(tag: 'ErrorService');
      await errorService.logError(
        e,
        context: 'main.initialization',
        stackTrace: stackTrace,
      );
    } else {
      // Fall back to debugPrint if ErrorService is not available
      debugPrint('Error initializing app: ${e.toString()}');
      debugPrint('Stack trace: $stackTrace');
    }
  } catch (_) {
    // Last resort if everything fails
    debugPrint('Error initializing app: ${e.toString()}');
    debugPrint('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '4wk App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const AuthWrapper(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Restart app logic would go here
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      try {
        // Check if Firebase user exists
        if (authController.firebaseUser != null) {
          // Check if we have app user data
          if (authController.currentUser != null) {
            // Check if garage ID exists
            if (authController.currentUser?.garageId != null &&
                authController.currentUser!.garageId!.isNotEmpty) {
              // User is authenticated and has a garage ID, show main app
              return const MainNavigationScreen();
            } else {
              // User is authenticated but needs to set up garage ID
              return const GarageSetupScreen();
            }
          } else {
            // Firebase user exists but app user data is still loading
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        } else {
          // User is not authenticated
          return LoginPage();
        }
      } catch (e, stackTrace) {
        // Log any errors during navigation if ErrorService is available
        if (Get.isRegistered<ErrorService>(tag: 'ErrorService')) {
          final errorService = Get.find<ErrorService>(tag: 'ErrorService');
          errorService.logError(
            e,
            context: 'AuthWrapper.build',
            stackTrace: stackTrace,
          );
        }

        // Return a fallback UI
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Something went wrong'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    );
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      }
    });
  }
}
