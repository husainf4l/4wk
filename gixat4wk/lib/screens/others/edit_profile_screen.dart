import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../services/database_service.dart';
import '../../widgets/account_deletion_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthController authController = Get.find<AuthController>();
  final DatabaseService databaseService = Get.find<DatabaseService>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;

  String? _userId;
  String? _userEmail;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = authController.currentUser;
      if (currentUser != null) {
        _userId = currentUser.uid;
        _userEmail = currentUser.email;

        // Load user profile data from Firestore
        final userStream = databaseService.getUserByUid(currentUser.uid);
        final userSnapshot = await userStream.first;

        if (userSnapshot.exists) {
          final userData = userSnapshot.data() as Map<String, dynamic>?;
          if (userData != null) {
            _nameController.text = userData['displayName'] ?? '';
            _bioController.text = userData['bio'] ?? '';
            _locationController.text = userData['location'] ?? '';
            _phoneController.text = userData['phoneNumber'] ?? '';
            _photoUrl = userData['photoURL'] ?? '';
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      Get.snackbar(
        'Error',
        'Failed to load profile data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }

    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = authController.currentUser;
      if (currentUser != null) {
        // Note: Firebase Auth display name will be updated via Firestore trigger

        // Update user document in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'displayName': _nameController.text.trim(),
              'bio': _bioController.text.trim(),
              'location': _locationController.text.trim(),
              'phoneNumber': _phoneController.text.trim(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });

        setState(() => _hasChanges = false);

        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteAccountDialog() {
    if (_userId != null && _userEmail != null) {
      Get.dialog(
        AccountDeletionDialog(userId: _userId!, userEmail: _userEmail),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Photo Section
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: colorScheme.primary
                                      .withValues(alpha: 0.2),
                                  backgroundImage:
                                      _photoUrl != null && _photoUrl!.isNotEmpty
                                          ? NetworkImage(_photoUrl!)
                                          : null,
                                  child:
                                      _photoUrl == null || _photoUrl!.isEmpty
                                          ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: colorScheme.primary,
                                          )
                                          : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: colorScheme.onPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement photo upload
                                Get.snackbar(
                                  'Coming Soon',
                                  'Photo upload feature will be available soon',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              child: Text(
                                'Change Photo',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Basic Information Section
                      Text(
                        'Basic Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email Field (Read-only)
                      TextFormField(
                        initialValue: _userEmail ?? '',
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        enabled: false,
                      ),

                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 24),

                      // Additional Information Section
                      Text(
                        'Additional Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bio Field
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          prefixIcon: const Icon(Icons.info_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          hintText: 'Tell us about yourself',
                        ),
                        maxLines: 3,
                        maxLength: 200,
                      ),

                      const SizedBox(height: 16),

                      // Location Field
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _hasChanges && !_isLoading ? _saveProfile : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Danger Zone
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Danger Zone',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Once you delete your account, there is no going back. Please be certain.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showDeleteAccountDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[600],
                                  side: BorderSide(color: Colors.red[600]!),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.delete_forever_outlined),
                                label: const Text(
                                  'Delete My Account',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }
}
