import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/screens/main_navigation_screen.dart';
import 'unified_session_activity_screen.dart';
import 'report_screen.dart';
import '../../models/session.dart';
import '../../utils/session_utils.dart';
import '../../models/unified_session_activity.dart';

class SessionDetailsScreen extends StatefulWidget {
  final Session session;

  const SessionDetailsScreen({super.key, required this.session});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  // Track which stages have data
  Map<String, bool> stageHasData = {
    'clientNotes': false,
    'inspection': false,
    'testDrive': false,
    'report': false,
  };

  @override
  void initState() {
    super.initState();
    _checkStageData();
  }

  Future<void> _checkStageData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('session_activities')
              .where('sessionId', isEqualTo: widget.session.id)
              .get();

      final Map<String, bool> updatedStageData = {
        'clientNotes': false,
        'inspection': false,
        'testDrive': false,
        'report': false,
      };

      for (var doc in snapshot.docs) {
        final activity = doc.data();
        final stage = activity['stage'] as String?;

        if (stage != null && updatedStageData.containsKey(stage)) {
          // Check if activity has meaningful data
          final notes = activity['notes'] as String? ?? '';
          final images = activity['images'] as List? ?? [];
          final requests = activity['requests'] as List? ?? [];
          final findings = activity['findings'] as List? ?? [];
          final observations = activity['observations'] as List? ?? [];
          final reportData = activity['reportData'] as Map? ?? {};

          // Consider stage as having data if any of these conditions are true
          if (notes.trim().isNotEmpty ||
              images.isNotEmpty ||
              requests.isNotEmpty ||
              findings.isNotEmpty ||
              observations.isNotEmpty ||
              reportData.isNotEmpty) {
            updatedStageData[stage] = true;
          }
        }
      }

      if (mounted) {
        setState(() {
          stageHasData = updatedStageData;
        });
      }
    } catch (e) {
      debugPrint('Error checking stage data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFFE82127); // Tesla-like Red
    final carMake = widget.session.car['make'] ?? '';
    final carModel = widget.session.car['model'] ?? '';
    final plateNumber = widget.session.car['plateNumber'] ?? '';
    final carTitle =
        '$carMake $carModel ${plateNumber.isNotEmpty ? '• $plateNumber' : ''}';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Elegant header with car details
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
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
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: SessionUtils.getStatusColor(
                              widget.session.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            SessionUtils.formatStatus(widget.session.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: SessionUtils.getStatusColor(
                                widget.session.status,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.off(() => MainNavigationScreen()),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.black54,
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Client name
                    Text(
                      'Client: ${widget.session.client['name'] ?? 'Unknown'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Activities',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.sticky_note_2_outlined,
                            title: 'Client Notes',
                            color: accentColor,
                            hasData: stageHasData['clientNotes'] ?? false,
                            onTap: () async {
                              // Navigate to unified session activity screen for client notes
                              final result = await Get.to(
                                () => UnifiedSessionActivityScreen(
                                  sessionId: widget.session.id,
                                  clientId: widget.session.clientId,
                                  carId: widget.session.car['id'] ?? '',
                                  garageId: widget.session.garageId,
                                  stage: ActivityStage.clientNotes,
                                  sessionData: {
                                    'car': widget.session.car,
                                    'client': widget.session.client,
                                    'status': widget.session.status,
                                  },
                                ),
                              );
                              // Refresh stage data when returning from activity screen
                              if (result == true) {
                                _checkStageData();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.search,
                            title: 'Inspection',
                            color: accentColor,
                            hasData: stageHasData['inspection'] ?? false,
                            onTap: () async {
                              // Navigate to unified session activity screen for inspection
                              final result = await Get.to(
                                () => UnifiedSessionActivityScreen(
                                  sessionId: widget.session.id,
                                  clientId: widget.session.clientId,
                                  carId: widget.session.car['id'] ?? '',
                                  garageId: widget.session.garageId,
                                  stage: ActivityStage.inspection,
                                  sessionData: {
                                    'car': widget.session.car,
                                    'client': widget.session.client,
                                    'status': widget.session.status,
                                  },
                                ),
                              );
                              // Refresh stage data when returning from activity screen
                              if (result == true) {
                                _checkStageData();
                              }
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
                            color: accentColor,
                            hasData: stageHasData['testDrive'] ?? false,
                            onTap: () async {
                              // Navigate to unified session activity screen for test drive
                              final result = await Get.to(
                                () => UnifiedSessionActivityScreen(
                                  sessionId: widget.session.id,
                                  clientId: widget.session.clientId,
                                  carId: widget.session.car['id'] ?? '',
                                  garageId: widget.session.garageId,
                                  stage: ActivityStage.testDrive,
                                  sessionData: {
                                    'car': widget.session.car,
                                    'client': widget.session.client,
                                    'status': widget.session.status,
                                  },
                                ),
                              );
                              // Refresh stage data when returning from activity screen
                              if (result == true) {
                                _checkStageData();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.assignment,
                            title: 'G Report',
                            color: accentColor,
                            hasData: stageHasData['report'] ?? false,
                            onTap: () async {
                              // Navigate to dedicated report screen
                              final result = await Get.to(
                                () => ReportScreen(
                                  sessionId: widget.session.id,
                                  clientId: widget.session.clientId,
                                  carId: widget.session.car['id'] ?? '',
                                  garageId: widget.session.garageId,
                                  sessionData: {
                                    'car': widget.session.car,
                                    'client': widget.session.client,
                                    'status': widget.session.status,
                                  },
                                ),
                              );
                              // Refresh stage data when returning from report screen
                              if (result == true) {
                                _checkStageData();
                              }
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
                            icon: Icons.assignment,
                            title: 'Job Order',
                            color: accentColor,
                            // Job Order requires reportId to be present
                            hasData: widget.session.reportId != null,
                            onTap: () {},
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Activity feed - Show both unified activities and legacy activities
                    StreamBuilder(
                      stream:
                          FirebaseFirestore.instance
                              .collection('session_activities')
                              .where('sessionId', isEqualTo: widget.session.id)
                              .orderBy('createdAt', descending: true)
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
                                  accentColor,
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
                            final activityDoc = activities[index];
                            final activity =
                                activityDoc.data() as Map<String, dynamic>;
                            return _UnifiedActivityItem(
                              activity: activity,
                              activityId: activityDoc.id,
                              sessionData: {
                                'car': widget.session.car,
                                'client': widget.session.client,
                                'status': widget.session.status,
                              },
                              color: accentColor,
                              formatTimestamp: _formatTimestamp,
                              onActivityUpdated: () => setState(() {}),
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

    DateTime? dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    }

    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 24, color: color),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (hasData)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Unified activity item component for new session_activities collection
class _UnifiedActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String activityId;
  final Map<String, dynamic> sessionData;
  final Color color;
  final String Function(dynamic) formatTimestamp;
  final VoidCallback? onActivityUpdated;

  const _UnifiedActivityItem({
    required this.activity,
    required this.activityId,
    required this.sessionData,
    required this.color,
    required this.formatTimestamp,
    this.onActivityUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = activity['stage'] ?? '';
    final notes = activity['notes'] ?? '';
    final images = activity['images'] as List? ?? [];
    final requests = activity['requests'] as List? ?? [];
    final findings = activity['findings'] as List? ?? [];
    final observations = activity['observations'] as List? ?? [];

    // Get stage-specific icon and title
    IconData stageIcon;
    String stageTitle;

    switch (stage) {
      case 'clientNotes':
        stageIcon = Icons.sticky_note_2_outlined;
        stageTitle = 'Client Notes';
        break;
      case 'inspection':
        stageIcon = Icons.search;
        stageTitle = 'Inspection';
        break;
      case 'testDrive':
        stageIcon = Icons.directions_car_outlined;
        stageTitle = 'Test Drive';
        break;
      case 'report':
        stageIcon = Icons.assignment_outlined;
        stageTitle = 'Report';
        break;
      default:
        stageIcon = Icons.help_outline;
        stageTitle = 'Activity';
    }

    final hasContent =
        notes.isNotEmpty ||
        images.isNotEmpty ||
        requests.isNotEmpty ||
        findings.isNotEmpty ||
        observations.isNotEmpty;

    return InkWell(
      onTap: () => _navigateToActivity(context, stage),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(stageIcon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stageTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatTimestamp(activity['createdAt']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            if (hasContent) ...[
              const Divider(height: 24),
              if (notes.isNotEmpty) ...[
                Text(
                  notes,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (images.isNotEmpty)
                    _buildInfoChip(
                      Icons.image_outlined,
                      '${images.length} Image${images.length > 1 ? 's' : ''}',
                    ),
                  if (requests.isNotEmpty)
                    _buildInfoChip(
                      Icons.list_alt_outlined,
                      '${requests.length} Request${requests.length > 1 ? 's' : ''}',
                    ),
                  if (findings.isNotEmpty)
                    _buildInfoChip(
                      Icons.error_outline,
                      '${findings.length} Finding${findings.length > 1 ? 's' : ''}',
                    ),
                  if (observations.isNotEmpty)
                    _buildInfoChip(
                      Icons.visibility_outlined,
                      '${observations.length} Observation${observations.length > 1 ? 's' : ''}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
      ],
    );
  }

  void _navigateToActivity(BuildContext context, String stage) async {
    ActivityStage activityStage;
    switch (stage) {
      case 'clientNotes':
        activityStage = ActivityStage.clientNotes;
        break;
      case 'inspection':
        activityStage = ActivityStage.inspection;
        break;
      case 'testDrive':
        activityStage = ActivityStage.testDrive;
        break;
      case 'report':
        activityStage = ActivityStage.report;
        break;
      default:
        return;
    }

    final result = await Get.to(
      () => UnifiedSessionActivityScreen(
        sessionId: activity['sessionId'] ?? '',
        clientId: activity['clientId'] ?? '',
        carId: activity['carId'] ?? '',
        garageId: activity['garageId'] ?? '',
        stage: activityStage,
        activityId: activityId,
        sessionData: sessionData,
      ),
    );

    if (result == true && onActivityUpdated != null) {
      onActivityUpdated!();
    }
  }
}
