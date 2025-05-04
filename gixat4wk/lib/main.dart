import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_page.dart';
import 'screens/main_navigation_screen.dart'; // Import the new navigation screen
import 'screens/garage_setup_screen.dart'; // Import the new garage setup screen
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'services/error_service.dart'; // Import the new error service
import 'services/image_handling_service.dart'; // Import ImageHandlingService
import 'services/chat_service.dart'; // Import ChatService

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with the correct options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize and register the DatabaseService first
    final databaseService = await Get.putAsync(() => DatabaseService().init());

    // Initialize the ErrorService after DatabaseService
    final errorService = await Get.putAsync(
      () => ErrorService().init(),
      tag: 'ErrorService',
    );

    // Connect DatabaseService with ErrorService
    databaseService.setErrorService(errorService);

    // Register ImageHandlingService
    Get.put(ImageHandlingService());

    // Register ChatService
    await Get.putAsync(() => ChatService().init());

    // Initialize the AuthController after services are set up
    Get.put(AuthController());

    runApp(const MyApp());
  } catch (e, stackTrace) {
    // If we have an error during initialization, try to log it if possible
    try {
      // Check if ErrorService is already registered
      if (Get.isRegistered<ErrorService>(tag: 'ErrorService')) {
        final errorService = Get.find<ErrorService>(tag: 'ErrorService');
        errorService.logError(
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

    // Show error UI
    runApp(const ErrorApp());
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
      darkTheme: AppTheme.darkTheme(), // Use the dark theme from AppTheme class
      themeMode: ThemeMode.system,
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
