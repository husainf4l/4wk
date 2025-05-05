import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:io' show Platform;
import '../services/database_service.dart';
import '../services/error_service.dart';
import '../models/user.dart'
    as app_models; // Import our custom User model with an alias

class AuthController extends GetxController {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get database service from GetX
  late final DatabaseService _databaseService = Get.find<DatabaseService>();
  // Get error service from GetX
  late final ErrorService _errorService = Get.find<ErrorService>();

  // Observable Firebase auth user state
  final Rx<firebase_auth.User?> _firebaseUser = Rx<firebase_auth.User?>(null);

  // Observable app user state (our custom User model)
  final Rx<app_models.User?> _appUser = Rx<app_models.User?>(null);

  // Loading state
  final RxBool isLoading = false.obs;

  // Getters for user states
  firebase_auth.User? get firebaseUser => _firebaseUser.value;
  app_models.User? get currentUser => _appUser.value;
  String? get garageId => currentUser?.garageId;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase auth state changes
    _firebaseUser.bindStream(_auth.authStateChanges());

    // When Firebase user changes, fetch the app user data
    ever(_firebaseUser, _fetchAppUser);
  }

  // Fetch app user data when Firebase user changes
  void _fetchAppUser(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        final userDoc = await _databaseService.getDocument(
          'users',
          firebaseUser.uid,
        );
        if (userDoc.exists) {
          _appUser.value = app_models.User.fromFirestore(userDoc);
        } else {
          // If no app user data yet, create it
          await _saveUserToFirestore(firebaseUser);
          // Then fetch it
          final newUserDoc = await _databaseService.getDocument(
            'users',
            firebaseUser.uid,
          );
          _appUser.value = app_models.User.fromFirestore(newUserDoc);
        }
      } catch (e) {
        _errorService.logError(
          e,
          context: 'AuthController._fetchAppUser',
          userId: firebaseUser.uid,
        );
        _appUser.value = null;
      }
    } else {
      _appUser.value = null;
    }
  }

  // Save user data to Firestore
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
          'isActive': true,
        };

        // Save to Firestore using the DatabaseService with the user's UID as the document ID
        await _databaseService.setDocument('users', user.uid, userData);
      }
    } catch (e) {
      _errorService.logError(
        e,
        context: 'AuthController._saveUserToFirestore',
        userId: user.uid,
      );
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      isLoading.value = false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = '';

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        default:
          message = e.message ?? 'An unknown error occurred.';
      }

      Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Sign up with email and password
  Future<void> signUp(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      isLoading.value = false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = '';

      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        default:
          message = e.message ?? 'An unknown error occurred.';
      }

      Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Sign in with Google
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
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to sign in with Google: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Generate a random nonce string
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // Returns the sha256 hash of [input] in hex notation.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign in with Apple
  Future<void> signInWithApple() async {
    // Only proceed if the platform is iOS
    if (!Platform.isIOS) {
      Get.snackbar(
        'Not Available',
        'Sign in with Apple is only available on iOS devices',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Generate nonce for Apple Sign In
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        // Add webAuthenticationOptions with specific redirect URI for iOS
        webAuthenticationOptions:
            Platform.isIOS
                ? WebAuthenticationOptions(
                  clientId: 'com.roxate.gixatapp',
                  redirectUri: Uri.parse(
                    'https://gixat-app.firebaseapp.com/__/auth/handler',
                  ),
                )
                : null,
      );

      // Create an OAuthCredential from the Apple credential
      final oauthCredential = firebase_auth.OAuthProvider(
        "apple.com",
      ).credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // For Apple Sign In, we might need to update the display name as it might be null
      if (userCredential.user != null) {
        if (appleCredential.givenName != null &&
            appleCredential.familyName != null) {
          String displayName =
              '${appleCredential.givenName} ${appleCredential.familyName}';
          // Update the user profile with the display name
          await userCredential.user!.updateDisplayName(displayName);
        }
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      _errorService.logError(
        e,
        context: 'AuthController.signInWithApple',
        userId: _firebaseUser.value?.uid,
      );
      Get.snackbar(
        'Error',
        'Failed to sign in with Apple: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Update user's garage ID
  Future<bool> updateGarageId(String garageId) async {
    try {
      if (_firebaseUser.value == null) return false;

      await _databaseService.updateDocument('users', _firebaseUser.value!.uid, {
        'garageId': garageId,
      });

      // Refresh app user data
      final userDoc = await _databaseService.getDocument(
        'users',
        _firebaseUser.value!.uid,
      );
      _appUser.value = app_models.User.fromFirestore(userDoc);

      return true;
    } catch (e) {
      _errorService.logError(
        e,
        context: 'AuthController.updateGarageId',
        userId: _firebaseUser.value?.uid,
      );
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Check the provider data to determine how the user signed in
      final user = _auth.currentUser;
      final providerData = user?.providerData;

      // Sign out from Google only if the user signed in with Google
      if (providerData != null &&
          providerData.any((element) => element.providerId == 'google.com')) {
        await _googleSignIn.signOut();
      }

      // Always sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      _errorService.logError(
        e,
        context: 'AuthController.signOut',
        userId: _firebaseUser.value?.uid,
      );

      Get.snackbar(
        'Error signing out',
        'Could not sign out properly. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
