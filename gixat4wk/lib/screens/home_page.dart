import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../services/database_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final DatabaseService databaseService = Get.find<DatabaseService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gixat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authController.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: databaseService.getUserByUid(
                  authController.currentUser?.uid ?? '',
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  String displayName = 'User';
                  String email = authController.currentUser?.email ?? '';
                  String photoUrl = '';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      displayName = userData['displayName'] ?? 'User';
                      if (displayName.isEmpty) displayName = 'User';
                      photoUrl = userData['photoURL'] ?? '';
                    }
                  }

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: theme.colorScheme.primary
                                    .withAlpha(51),
                                backgroundImage:
                                    photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                child:
                                    photoUrl.isEmpty
                                        ? Icon(
                                          Icons.person,
                                          size: 30,
                                          color: theme.colorScheme.primary,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome Back!',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      displayName,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: theme.textTheme.bodyLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Quick Actions', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildFeatureCard(
                    context,
                    'Profile',
                    Icons.person_outline,
                    () {
                      _addSampleActivity(databaseService, authController);
                    },
                  ),
                  _buildFeatureCard(context, 'Settings', Icons.settings, () {}),
                  _buildFeatureCard(
                    context,
                    'Messages',
                    Icons.message_outlined,
                    () {},
                  ),
                  _buildFeatureCard(
                    context,
                    'Analytics',
                    Icons.bar_chart,
                    () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Recent Activity', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final currentUser = authController.currentUser;
                  if (currentUser != null) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: databaseService.queryCollection('activities', [
                        ['userId', currentUser.uid],
                      ]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No activities yet.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextButton(
                                  onPressed:
                                      () => _addSampleActivity(
                                        databaseService,
                                        authController,
                                      ),
                                  child: const Text('Add Sample Activity'),
                                ),
                              ],
                            ),
                          );
                        }

                        // Sort activities by timestamp (newest first)
                        final activities = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity =
                                activities[index].data()
                                    as Map<String, dynamic>;
                            final activityType =
                                activity['type'] as String? ?? 'Unknown';

                            IconData activityIcon;
                            switch (activityType) {
                              case 'profile_update':
                                activityIcon = Icons.person;
                                break;
                              case 'login':
                                activityIcon = Icons.login;
                                break;
                              default:
                                activityIcon = Icons.notifications;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary
                                      .withAlpha(51),
                                  child: Icon(
                                    activityIcon,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  activity['title'] as String? ?? 'Activity',
                                ),
                                subtitle: Text(
                                  activity['description'] as String? ?? '',
                                ),
                                trailing: Text(
                                  _getTimeAgo(activity['timestamp']),
                                ),
                                onTap: () {},
                              ),
                            );
                          },
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text('Please log in to view activities'),
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSampleActivity(databaseService, authController),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime activityTime;
    if (timestamp is Timestamp) {
      activityTime = timestamp.toDate();
    } else if (timestamp is String) {
      activityTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'Unknown';
    }

    final duration = DateTime.now().difference(activityTime);

    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inDays < 1) {
      return '${duration.inHours}h ago';
    } else if (duration.inDays < 30) {
      return '${duration.inDays}d ago';
    } else {
      return '${(duration.inDays / 30).floor()}mo ago';
    }
  }

  // Function to add a sample activity
  void _addSampleActivity(
    DatabaseService databaseService,
    AuthController authController,
  ) async {
    final currentUser = authController.currentUser;
    if (currentUser != null) {
      final activityTypes = ['profile_update', 'login', 'notification'];
      final activityType = activityTypes[DateTime.now().second % 3];

      String title, description;
      switch (activityType) {
        case 'profile_update':
          title = 'Profile Updated';
          description = 'You updated your profile information';
          break;
        case 'login':
          title = 'New Login';
          description = 'You logged in to your account';
          break;
        default:
          title = 'New Notification';
          description = 'You have a new system notification';
      }

      final activityData = {
        'userId': currentUser.uid,
        'type': activityType,
        'title': title,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      };

      try {
        await databaseService.addDocument('activities', activityData);
        Get.snackbar(
          'Success',
          'Activity added successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to add activity: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
