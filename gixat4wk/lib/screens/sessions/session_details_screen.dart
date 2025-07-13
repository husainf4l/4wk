import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/screens/main_navigation_screen.dart';
import 'unified_session_activity_screen.dart';
import '../../models/session.dart';
import '../../utils/session_utils.dart';
import '../../services/session/session_service.dart';
import '../../models/unified_session_activity.dart';

class SessionDetailsScreen extends StatefulWidget {
  final Session session;

  const SessionDetailsScreen({super.key, required this.session});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // Extract car details
    final carMake = widget.session.car['make'] ?? '';
    final carModel = widget.session.car['model'] ?? '';
    final plateNumber = widget.session.car['plateNumber'] ?? '';
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
                              widget.session.status,
                            ).withAlpha(38),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            SessionUtils.formatStatus(widget.session.status),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
                      'Client: ${widget.session.client['name'] ?? 'Unknown'}',
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
                            hasData: false,
                            onTap: () {
                              // Navigate to unified session activity screen for client notes
                              Get.to(
                                () => UnifiedSessionActivityScreen(
                                  sessionId: widget.session.id,
                                  clientId: widget.session.clientId,
                                  carId: widget.session.car['id'] ?? '',
                                  garageId: widget.session.garageId,
                                  stage: ActivityStage.clientNotes,
                                  sessionData: {
                                    'car': widget.session.car,
                                    'client': widget.session.client,
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.search,
                            title: 'Inspection',
                            color: primaryColor,
                            hasData: false,
                            onTap: () {},
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
                            hasData: true,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SessionBox(
                            icon: Icons.directions_car,
                            title: 'G Report',
                            color: primaryColor,
                            hasData: widget.session.reportId != null,
                            onTap: () {},
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
                            color: primaryColor,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black, // Black text
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
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
                            return _UnifiedActivityItem(
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

// Unified activity item component for new session_activities collection
class _UnifiedActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Color color;
  final String Function(dynamic) formatTimestamp;

  const _UnifiedActivityItem({
    required this.activity,
    required this.color,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = activity['stage'] ?? '';
    final status = activity['status'] ?? 'draft';
    final notes = activity['notes'] ?? '';
    final images = activity['images'] as List? ?? [];
    final requests = activity['requests'] as List? ?? [];

    // Get stage-specific icon and title
    IconData stageIcon;
    String stageTitle;
    Color stageColor;

    switch (stage) {
      case 'clientNotes':
        stageIcon = Icons.sticky_note_2_outlined;
        stageTitle = 'Client Notes';
        stageColor = Colors.blue;
        break;
      case 'inspection':
        stageIcon = Icons.search;
        stageTitle = 'Inspection';
        stageColor = Colors.orange;
        break;
      case 'testDrive':
        stageIcon = Icons.directions_car;
        stageTitle = 'Test Drive';
        stageColor = Colors.green;
        break;
      case 'report':
        stageIcon = Icons.assignment;
        stageTitle = 'Report';
        stageColor = Colors.purple;
        break;
      default:
        stageIcon = Icons.circle;
        stageTitle = 'Activity';
        stageColor = color;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stageColor.withAlpha(51), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stageColor.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(stageIcon, size: 20, color: stageColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stageTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatTimestamp(activity['createdAt']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        status == 'completed'
                            ? Colors.green.withAlpha(26)
                            : Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          status == 'completed' ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (images.isNotEmpty || requests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (images.isNotEmpty) ...[
                    Icon(Icons.image, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${images.length} image${images.length != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (images.isNotEmpty && requests.isNotEmpty) ...[
                    const SizedBox(width: 16),
                  ],
                  if (requests.isNotEmpty) ...[
                    Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${requests.length} request${requests.length != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
