import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../services/database_service.dart';
import '../../widgets/account_deletion_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final DatabaseService databaseService = Get.find<DatabaseService>();
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Text(
              'Profile',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // User profile card
            Obx(() {
              final currentUser = authController.currentUser;
              return StreamBuilder<DocumentSnapshot>(
                stream: databaseService.getUserByUid(currentUser?.uid ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  String displayName = 'User';
                  String email = currentUser?.email ?? '';
                  String photoUrl = '';
                  String bio = 'No bio available';
                  String location = 'Not specified';
                  String memberSince = 'Unknown';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      displayName = userData['displayName'] ?? 'User';
                      if (displayName.isEmpty) displayName = 'User';
                      photoUrl = userData['photoURL'] ?? '';
                      bio = userData['bio'] ?? 'No bio available';
                      location = userData['location'] ?? 'Not specified';

                      if (userData['createdAt'] != null) {
                        try {
                          final createdAt =
                              (userData['createdAt'] as Timestamp).toDate();
                          memberSince = '${createdAt.month}/${createdAt.year}';
                        } catch (e) {
                          memberSince = 'Unknown';
                        }
                      }
                    }
                  }

                  return Column(
                    children: [
                      _buildProfileHeader(
                        context,
                        displayName,
                        email,
                        photoUrl,
                        theme,
                      ),
                      const SizedBox(height: 24),
                      _buildBioSection(theme, bio),
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        theme,
                        Icons.location_on_outlined,
                        'Location',
                        location,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        theme,
                        Icons.calendar_today_outlined,
                        'Member since',
                        memberSince,
                      ),
                    ],
                  );
                },
              );
            }),

            const SizedBox(height: 32),

            // Account options
            Text(
              'Account',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(theme, 'Edit Profile', Icons.edit_outlined, () {
              Get.snackbar(
                'Edit Profile',
                'Edit profile feature coming soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            }),
            const SizedBox(height: 12),
            _buildSettingsCard(
              theme,
              'Notification Settings',
              Icons.notifications_outlined,
              () {
                Get.snackbar(
                  'Notifications',
                  'Notification settings feature coming soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              theme,
              'Privacy & Security',
              Icons.security_outlined,
              () {
                Get.snackbar(
                  'Privacy',
                  'Privacy settings feature coming soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(theme, 'Help Center', Icons.help_outline, () {
              Get.snackbar(
                'Help',
                'Help center feature coming soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            }),
            const SizedBox(height: 12),
            _buildSettingsCard(theme, 'Log Out', Icons.logout, () {
              authController.signOut();
            }, isDestructive: true),

            const SizedBox(height: 24),

            // Data & Privacy Section
            Text(
              'Data & Privacy',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              theme,
              'Export My Data',
              Icons.download_outlined,
              () {
                Get.snackbar(
                  'Export Data',
                  'Data export feature coming soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              theme,
              'Delete My Account',
              Icons.delete_forever_outlined,
              () {
                final currentUser = authController.currentUser;
                if (currentUser != null) {
                  Get.dialog(
                    AccountDeletionDialog(
                      userId: currentUser.uid,
                      userEmail: currentUser.email,
                    ),
                  );
                }
              },
              isDestructive: true,
            ),

            // Footer spacer
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Gixat App v1.0.0',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String email,
    String photoUrl,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Profile photo
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.primary.withAlpha(51),
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child:
                  photoUrl.isEmpty
                      ? Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.primary,
                      )
                      : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.camera_alt,
                  color: theme.colorScheme.onSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // User name and email
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      ],
    );
  }

  Widget _buildBioSection(ThemeData theme, String bio) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(bio, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red : theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red : null,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
