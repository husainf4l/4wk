import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/screens/main_navigation_screen.dart';
import '../../models/session.dart';
import '../../utils/session_utils.dart';
import 'client_notes_details_screen.dart';
import 'inspection_details_screen.dart';
import 'test_drive_details_screen.dart';
import 'report_details_screen.dart';
import 'job_order_screen.dart';

class SessionDetailsScreen extends StatelessWidget {
  final Session session;

  const SessionDetailsScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // Extract car details
    final carMake = session.car['make'] ?? '';
    final carModel = session.car['model'] ?? '';
    final plateNumber = session.car['plateNumber'] ?? '';
    final carTitle =
        '$carMake $carModel ${plateNumber.isNotEmpty ? '• $plateNumber' : ''}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Elegant header with car details
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Session status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: SessionUtils.getStatusColor(
                              session.status,
                            ).withAlpha(38),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            SessionUtils.formatStatus(session.status),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: SessionUtils.getStatusColor(
                                session.status,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.off(() => MainNavigationScreen()),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black, // Black icon for close
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Car details display
                    Text(
                      carTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Black text
                        letterSpacing: 0.4,
                      ),
                    ),
                    // Client name
                    Text(
                      'Client: ${session.client['name'] ?? 'Unknown'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[800], // Darker gray for subtitle
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Activities',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black, // Black text
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.sticky_note_2_outlined,
                            title: 'Client Notes',
                            color: primaryColor,
                            hasData: session.clientNoteId != null,
                            onTap: () {
                              // Navigate to the client notes details screen
                              final carMake = session.car['make'] ?? '';
                              final carModel = session.car['model'] ?? '';
                              final plateNumber =
                                  session.car['plateNumber'] ?? '';
                              final carDetails =
                                  '$carMake $carModel ${plateNumber.isNotEmpty ? '• $plateNumber' : ''}';

                              // Navigate directly with or without existing clientNoteId
                              Get.to(
                                () => ClientNotesDetailsScreen(
                                  session: session,
                                  clientNotesId: session.clientNoteId,
                                  clientName:
                                      session.client['name'] ?? 'Unknown',
                                  carDetails: carDetails,
                                ),
                                transition: Transition.rightToLeft,
                              )?.then((result) {
                                if (result != null &&
                                    result['refresh'] == true) {
                                  // Refresh session data
                                  FirebaseFirestore.instance
                                      .collection('sessions')
                                      .doc(session.id)
                                      .get()
                                      .then((snapshot) {
                                        if (snapshot.exists &&
                                            snapshot.data() != null) {
                                          // Refresh UI by returning to previous screen with updated data
                                          Get.back(result: {'refresh': true});
                                        }
                                      });
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.search,
                            title: 'Inspection',
                            color: primaryColor,
                            hasData: session.inspectionId != null,
                            onTap: () {
                              // Navigate to the inspection details screen
                              final carMake = session.car['make'] ?? '';
                              final carModel = session.car['model'] ?? '';
                              final plateNumber =
                                  session.car['plateNumber'] ?? '';
                              final carDetails =
                                  '$carMake $carModel ${plateNumber.isNotEmpty ? '• $plateNumber' : ''}';

                              // Navigate directly with or without existing inspectionId
                              Get.to(
                                () => InspectionDetailsScreen(
                                  session: session,
                                  inspectionId: session.inspectionId,
                                  clientName:
                                      session.client['name'] ?? 'Unknown',
                                  carDetails: carDetails,
                                ),
                                transition: Transition.rightToLeft,
                              )?.then((result) {
                                if (result != null &&
                                    result['refresh'] == true) {
                                  // Refresh session data
                                  FirebaseFirestore.instance
                                      .collection('sessions')
                                      .doc(session.id)
                                      .get()
                                      .then((snapshot) {
                                        if (snapshot.exists &&
                                            snapshot.data() != null) {
                                          // Refresh UI by returning to previous screen with updated data
                                          Get.back(result: {'refresh': true});
                                        }
                                      });
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.directions_car,
                            title: 'Test Drive',
                            color: primaryColor,
                            hasData: session.testDriveId != null,
                            onTap: () {
                              // Navigate to the test drive details screen
                              final carMake = session.car['make'] ?? '';
                              final carModel = session.car['model'] ?? '';
                              final plateNumber =
                                  session.car['plateNumber'] ?? '';
                              final carDetails =
                                  '$carMake $carModel ${plateNumber.isNotEmpty ? '• $plateNumber' : ''}';

                              // Navigate directly with or without existing testDriveId
                              Get.to(
                                () => TestDriveDetailsScreen(
                                  session: session,
                                  testDriveId: session.testDriveId,
                                  clientName:
                                      session.client['name'] ?? 'Unknown',
                                  carDetails: carDetails,
                                ),
                                transition: Transition.rightToLeft,
                              )?.then((result) {
                                if (result != null &&
                                    result['refresh'] == true) {
                                  // Refresh session data
                                  FirebaseFirestore.instance
                                      .collection('sessions')
                                      .doc(session.id)
                                      .get()
                                      .then((snapshot) {
                                        if (snapshot.exists &&
                                            snapshot.data() != null) {
                                          // Refresh UI by returning to previous screen with updated data
                                          Get.back(result: {'refresh': true});
                                        }
                                      });
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.directions_car,
                            title: 'G Report',
                            color: primaryColor,
                            hasData: session.reportId != null,
                            onTap: () {
                              // Navigate directly with only session ID - G Report page will fetch all needed data
                              Get.to(
                                () => ReportDetailsScreen(
                                  sessionId: session.id,
                                  reportId: session.reportId,
                                ),
                                transition: Transition.rightToLeft,
                              )?.then((result) {
                                if (result != null &&
                                    result['refresh'] == true) {
                                  // Refresh session data
                                  FirebaseFirestore.instance
                                      .collection('sessions')
                                      .doc(session.id)
                                      .get()
                                      .then((snapshot) {
                                        if (snapshot.exists &&
                                            snapshot.data() != null) {
                                          // Refresh UI by returning to previous screen with updated data
                                          Get.back(result: {'refresh': true});
                                        }
                                      });
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Add Job Order button in a new row
                    Row(
                      children: [
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.assignment,
                            title: 'Job Order',
                            color: primaryColor,
                            // Job Order requires reportId to be present
                            hasData: session.reportId != null,
                            onTap: () {
                              if (session.reportId == null) {
                                // Show a message that report is needed for job order
                                Get.snackbar(
                                  'Report Required',
                                  'Please complete the G Report first to create a Job Order.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red.withOpacity(0.7),
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              // Navigate to the job order screen with reportId
                              Get.to(
                                () =>
                                    JobOrderScreen(reportId: session.reportId!),
                                transition: Transition.rightToLeft,
                              )?.then((result) {
                                if (result != null &&
                                    result['refresh'] == true) {
                                  // Refresh session data
                                  FirebaseFirestore.instance
                                      .collection('sessions')
                                      .doc(session.id)
                                      .get()
                                      .then((snapshot) {
                                        if (snapshot.exists &&
                                            snapshot.data() != null) {
                                          // Refresh UI by returning to previous screen with updated data
                                          Get.back(result: {'refresh': true});
                                        }
                                      });
                                }
                              });
                            },
                          ),
                        ),
                        // Adding an empty container for the second column to maintain layout consistency
                        const SizedBox(width: 16),
                        Expanded(child: Container()),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Activity history section
                    Text(
                      'Activity History',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black, // Black text
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Activity feed
                    StreamBuilder(
                      stream:
                          FirebaseFirestore.instance
                              .collection('activity')
                              .where('sessionId', isEqualTo: session.id)
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                      builder: (
                        context,
                        AsyncSnapshot<QuerySnapshot> snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          final errorMessage =
                              snapshot.error
                                  .toString(); // Extract error details
                          debugPrint(
                            'Error loading activities: $errorMessage',
                          ); // Log the error
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Error loading activities',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.red[400],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    errorMessage, // Display the error message
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No activity recorded yet',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final activities = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: activities.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final activity =
                                activities[index].data()
                                    as Map<String, dynamic>;
                            return _ActivityItem(
                              activity: activity,
                              color: primaryColor,
                              formatTimestamp: _formatTimestamp,
                            );
                          },
                        );
                      },
                    ),
                    // Add some bottom padding for better scrolling experience
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format timestamps in a more elegant way
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activityDate = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
      );

      final time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      if (activityDate == today) {
        return 'Today at $time';
      } else if (activityDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday at $time';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $time';
      }
    }

    return '';
  }
}

// Refined session box with consistent styling
class _SessionBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final bool hasData; // New parameter to indicate if activity has data

  const _SessionBox({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
    this.hasData = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white, // White background for light theme
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(51), width: 1),
        ),
        child: Stack(
          children: [
            // Very subtle gradient overlay for depth
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withAlpha(8), Colors.transparent],
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: hasData ? Colors.green : color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black, // Black text
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Add small indicator dot if has data
            if (hasData)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Activity item component
class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Color color;
  final String Function(dynamic) formatTimestamp;

  const _ActivityItem({
    required this.activity,
    required this.color,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, // White background for light theme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title'] ?? 'Activity',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.black, // Black text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatTimestamp(activity['timestamp']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700], // Darker gray for timestamp
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
