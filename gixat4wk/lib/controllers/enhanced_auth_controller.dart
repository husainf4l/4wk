import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/error_service.dart';
import '../services/cache_service.dart';
import '../models/user.dart' as app_models;

class EnhancedAuthController extends GetxController {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get services from GetX
  late final DatabaseService _databaseService = Get.find<DatabaseService>();
  late final ErrorService _errorService = Get.find<ErrorService>(
    tag: 'ErrorService',
  );
  late final CacheService _cacheService = Get.find<CacheService>();

  // Observable Firebase auth user state
  final Rx<firebase_auth.User?> _firebaseUser = Rx<firebase_auth.User?>(null);

  // Observable app user state (our custom User model)
  final Rx<app_models.User?> _appUser = Rx<app_models.User?>(null);

  // Loading state
  final RxBool isLoading = false.obs;

  // Cache keys
  static const String _userCacheKey = 'current_user_data';
  static const String _userProfileCacheKey = 'user_profile_';

  // Getters for user states
  firebase_auth.User? get firebaseUser => _firebaseUser.value;
  app_models.User? get currentUser => _appUser.value;
  String? get garageId => currentUser?.garageId;

  @override
  void onInit() {
    super.onInit();

    // Listen to Firebase auth state changes
    _firebaseUser.bindStream(_auth.authStateChanges());

    // When Firebase user changes, fetch the app user data with caching
    ever(_firebaseUser, _fetchAppUserWithCache);
  }

  /// Fetch app user data with multi-level caching
  void _fetchAppUserWithCache(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        // First try to get from cache
        final cachedUser = await _cacheService.get<Map<String, dynamic>>(
          '$_userProfileCacheKey${firebaseUser.uid}',
          category: 'user',
        );

        if (cachedUser != null) {
          _appUser.value = app_models.User.fromMap(cachedUser);

          // Still fetch fresh data in background for next time
          _fetchFreshUserDataInBackground(firebaseUser);
          return;
        }

        // If no cache, fetch from Firestore
        await _fetchFreshUserData(firebaseUser);
      } catch (e, stackTrace) {
        _errorService.logError(
          e,
          context: 'EnhancedAuthController._fetchAppUserWithCache',
          userId: firebaseUser.uid,
          stackTrace: stackTrace,
        );
        _appUser.value = null;
      }
    } else {
      _appUser.value = null;
      // Clear user cache when user signs out
      await _clearUserCache();
    }
  }

  /// Fetch fresh user data from Firestore
  Future<void> _fetchFreshUserData(firebase_auth.User firebaseUser) async {
    final userDoc = await _databaseService.getDocument(
      'users',
      firebaseUser.uid,
    );

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      _appUser.value = app_models.User.fromFirestore(userDoc);

      // Cache the user data
      await _cacheService.set(
        '$_userProfileCacheKey${firebaseUser.uid}',
        userData,
        duration: const Duration(hours: 6), // Refresh every 6 hours
        category: 'user',
      );
    } else {
      // If no app user data yet, create it
      await _saveUserToFirestore(firebaseUser);

      // Then fetch the newly created data
      final newUserDoc = await _databaseService.getDocument(
        'users',
        firebaseUser.uid,
      );
      _appUser.value = app_models.User.fromFirestore(newUserDoc);

      // Cache the new user data
      await _cacheService.set(
        '$_userProfileCacheKey${firebaseUser.uid}',
        newUserDoc.data() as Map<String, dynamic>,
        duration: const Duration(hours: 6),
        category: 'user',
      );
    }
  }

  /// Fetch fresh user data in background without blocking UI
  void _fetchFreshUserDataInBackground(firebase_auth.User firebaseUser) {
    Future.microtask(() async {
      try {
        await _fetchFreshUserData(firebaseUser);
      } catch (e) {
        // Log error but don't affect UI since we already have cached data
        _errorService.logError(
          e,
          context: 'EnhancedAuthController._fetchFreshUserDataInBackground',
          userId: firebaseUser.uid,
        );
      }
    });
  }

  /// Save user data to Firestore with enhanced logic
  Future<void> _saveUserToFirestore(firebase_auth.User user) async {
    try {
      // First check if the user document already exists
      final userDoc = await _databaseService.getDocument('users', user.uid);

      if (userDoc.exists) {
        // User exists, just update the lastLoginAt field
        await _databaseService.updateDocument('users', user.uid, {
          'lastLoginAt': DateTime.now(),
        });
      } else {
        // User doesn't exist, create a new user document
        final userData = {
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'phoneNumber': user.phoneNumber,
          'createdAt': DateTime.now(),
          'lastLoginAt': DateTime.now(),
          'isEmailVerified': user.emailVerified,
          'provider':
              user.providerData.isNotEmpty
                  ? user.providerData.first.providerId
                  : 'email',
        };

        await _databaseService.setDocument('users', user.uid, userData);
      }
    } catch (e, stackTrace) {
      _errorService.logError(
        e,
        context: 'EnhancedAuthController._saveUserToFirestore',
        userId: user.uid,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update garage ID with caching
  Future<void> updateGarageId(String garageId) async {
    try {
      final user = firebaseUser;
      if (user == null) throw Exception('User not authenticated');

      isLoading.value = true;

      // Update in Firestore
      await _databaseService.updateDocument('users', user.uid, {
        'garageId': garageId,
        'updatedAt': DateTime.now(),
      });

      // Update local state
      if (_appUser.value != null) {
        _appUser.value = _appUser.value!.copyWith(garageId: garageId);
      }

      // Update cache
      final userData = _appUser.value?.toMap();
      if (userData != null) {
        await _cacheService.set(
          '$_userProfileCacheKey${user.uid}',
          userData,
          duration: const Duration(hours: 6),
          category: 'user',
        );
      }

      isLoading.value = false;
    } catch (e, stackTrace) {
      isLoading.value = false;

      _errorService.logError(
        e,
        context: 'EnhancedAuthController.updateGarageId',
        userId: firebaseUser?.uid,
        stackTrace: stackTrace,
      );

      Get.snackbar(
        'Error',
        'Failed to update garage ID: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  /// Sign out with cache cleanup
  Future<void> signOut() async {
    try {
      isLoading.value = true;

      // Clear user cache
      await _clearUserCache();

      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();

      isLoading.value = false;
    } catch (e, stackTrace) {
      isLoading.value = false;

      _errorService.logError(
        e,
        context: 'EnhancedAuthController.signOut',
        stackTrace: stackTrace,
      );

      Get.snackbar(
        'Error',
        'Failed to sign out: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Clear user-related cache
  Future<void> _clearUserCache() async {
    try {
      // Clear specific user caches
      if (firebaseUser != null) {
        await _cacheService.remove(
          '$_userProfileCacheKey${firebaseUser!.uid}',
          category: 'user',
        );
      }

      // Clear general user cache
      await _cacheService.remove(_userCacheKey, category: 'user');
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user cache: $e');
      }
    }
  }

  /// Refresh user data manually
  Future<void> refreshUserData() async {
    final user = firebaseUser;
    if (user != null) {
      await _fetchFreshUserData(user);
    }
  }

  /// Pre-fetch user data for better performance
  Future<void> prefetchUserData() async {
    final user = firebaseUser;
    if (user != null && _appUser.value == null) {
      _fetchAppUserWithCache(user);
    }
  }

  // ... [Include all other authentication methods from the original AuthController]
  // Sign in with email and password, Google, Apple, etc.

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      isLoading.value = false;
    } catch (e, stackTrace) {
      isLoading.value = false;

      _errorService.logError(
        e,
        context: 'EnhancedAuthController.signInWithEmailAndPassword',
        stackTrace: stackTrace,
      );

      String message = 'Failed to sign in';
      if (e is firebase_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            message = 'No user found for that email.';
            break;
          case 'wrong-password':
            message = 'Wrong password provided.';
            break;
          case 'invalid-email':
            message = 'The email address is not valid.';
            break;
          case 'user-disabled':
            message = 'This user account has been disabled.';
            break;
          default:
            message = e.message ?? 'An unknown error occurred.';
        }
      }
      Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User canceled the sign-in flow
      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential for Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);

      isLoading.value = false;
    } catch (e, stackTrace) {
      isLoading.value = false;

      _errorService.logError(
        e,
        context: 'EnhancedAuthController.signInWithGoogle',
        stackTrace: stackTrace,
      );

      Get.snackbar(
        'Error',
        'Failed to sign in with Google: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
