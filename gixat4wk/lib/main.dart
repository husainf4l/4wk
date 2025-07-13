import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/enhanced_auth_controller.dart';
import 'screens/login_page.dart';
import 'screens/main_navigation_screen.dart'; // Import the new navigation screen
import 'screens/garage_setup_screen.dart'; // Import the new garage setup screen
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'services/enhanced_database_service.dart';
import 'services/enhanced_car_data_service.dart';
import 'services/error_service.dart'; // Import the new error service
import 'services/image_handling_service.dart'; // Import ImageHandlingService
import 'services/chat_service.dart'; // Import ChatService
import 'services/cache_service.dart'; // Import the new cache service
// import 'services/aws_s3_service.dart'; // Import AWS S3 Service (disabled due to security)

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Show splash screen early
    runApp(const SplashApp());

    // Load environment variables in background
    final envFuture = _loadEnvironmentVariables();

    // Initialize Firebase
    final firebaseFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Wait for critical services
    await Future.wait([envFuture, firebaseFuture]);

    // Initialize services in parallel for better performance
    await _initializeServices();

    // Switch to main app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Enhanced error handling with cache service if available
    await _handleInitializationError(e, stackTrace);
    runApp(const ErrorApp());
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

/// Initialize all services in parallel for optimal performance
Future<void> _initializeServices() async {
  try {
    // Initialize cache service first (other services may depend on it)
    final cacheService = await Get.putAsync(
      () => CacheService().onInit().then((_) => CacheService()),
    );

    // Initialize core services in parallel
    final coreServicesFuture = Future.wait([
      Get.putAsync(() => DatabaseService().init()),
      Get.putAsync(() => ErrorService().init(), tag: 'ErrorService'),
    ]);

    // Wait for core services
    final coreServices = await coreServicesFuture;
    final databaseService = coreServices[0] as DatabaseService;
    final errorService = coreServices[1] as ErrorService;

    // Connect DatabaseService with ErrorService
    databaseService.setErrorService(errorService);

    // Initialize remaining services in parallel
    final remainingServicesFuture = Future.wait([
      _initializeImageHandlingService(),
      Get.putAsync(() => ChatService().init()),
    ]);

    await remainingServicesFuture;

    // Initialize AuthController after all services are ready
    Get.put(AuthController());

    // Preload critical data in background
    _preloadCriticalData(cacheService);

    debugPrint('All services initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Error initializing services: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Initialize ImageHandlingService with proper error handling
Future<ImageHandlingService> _initializeImageHandlingService() async {
  try {
    final service = ImageHandlingService();
    Get.put(service);
    return service;
  } catch (e) {
    debugPrint('Error initializing ImageHandlingService: $e');
    // Return a fallback service or rethrow based on criticality
    rethrow;
  }
}

/// Preload critical data in background
void _preloadCriticalData(CacheService cacheService) {
  // Run in background without blocking the UI
  Future.microtask(() async {
    try {
      await cacheService.preloadCriticalData();

      // Preload other critical data
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        // Trigger user data fetch if needed
        if (authController.firebaseUser != null &&
            authController.currentUser == null) {
          // This will trigger the user data fetch
          debugPrint('Triggering user data preload');
        }
      }
    } catch (e) {
      debugPrint('Error preloading critical data: $e');
    }
  });
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
      theme: AppTheme.lightTheme(), // Use the light theme from AppTheme class
      home: const AuthWrapper(),
    );
  }
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4wk App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading 4wk App...', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
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
    final ErrorService errorService = Get.find<ErrorService>(
      tag: 'ErrorService',
    );

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
        // Log any errors during navigation
        errorService.logError(
          e,
          context: 'AuthWrapper.build',
          stackTrace: stackTrace,
        );

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
