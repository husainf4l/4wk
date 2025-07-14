import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobOrderRequestHistoryScreen extends StatefulWidget {
  final String jobOrderId;
  final String carMake;
  final String carModel;
  final String carPlate;

  const JobOrderRequestHistoryScreen({
    super.key,
    required this.jobOrderId,
    required this.carMake,
    required this.carModel,
    required this.carPlate,
  });

  @override
  State<JobOrderRequestHistoryScreen> createState() => _JobOrderRequestHistoryScreenState();
}

class _JobOrderRequestHistoryScreenState extends State<JobOrderRequestHistoryScreen> {
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void dispose() {
    // Dispose all comment controllers
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Order Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.carMake} ${widget.carModel}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('jobOrders')
                .doc(widget.jobOrderId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading job order',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Job order not found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This job order may have been deleted or moved',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final orderData = data['order'] as Map<String, dynamic>? ?? {};

          // Validate and extract requests with unified structure validation
          List<Map<String, dynamic>> requests = [];
          try {
            if (orderData['requests'] != null) {
              final requestsList =
                  orderData['requests'] as List<dynamic>? ?? [];
              requests =
                  requestsList.where((item) => item != null && item is Map).map(
                    (item) {
                      final requestMap = item as Map<String, dynamic>;
                      return {
                        // Universal request fields
                        'id':
                            requestMap['id']?.toString() ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        'request':
                            requestMap['request']?.toString() ??
                            requestMap['title']?.toString() ??
                            requestMap['name']?.toString() ??
                            'Untitled Request',
                        'argancy':
                            requestMap['argancy']?.toString() ??
                            requestMap['priority']?.toString() ??
                            'medium',
                        // Job order specific fields
                        'jobOrderStatus':
                            requestMap['jobOrderStatus']?.toString() ??
                            (requestMap['isDone'] == true
                                ? 'completed'
                                : 'pending'),
                        'jobOrderNotes':
                            requestMap['jobOrderNotes']?.toString() ??
                            requestMap['notes']?.toString() ??
                            requestMap['description']?.toString() ??
                            '',
                        'assignedTo':
                            requestMap['assignedTo']?.toString() ?? '',
                        'estimatedHours':
                            requestMap['estimatedHours']?.toString() ?? '',
                        'price': requestMap['price']?.toString() ?? '0',
                        // Backward compatibility
                        'isDone':
                            requestMap['isDone'] == true ||
                            requestMap['jobOrderStatus'] == 'completed',
                        // Source information
                        'source': requestMap['source']?.toString() ?? 'session',
                        'sourceStage':
                            requestMap['sourceStage']?.toString() ?? 'unknown',
                        'timestamp':
                            requestMap['timestamp']?.toString() ??
                            DateTime.now().toIso8601String(),
                      };
                    },
                  ).toList();
            }
          } catch (e) {
            debugPrint('Error parsing requests: $e');
            requests = [];
          }

          final clientName = data['clientName']?.toString() ?? 'Unknown Client';

          // Handle createdAt with better validation
          DateTime createdAt;
          try {
            if (orderData['createdAt'] != null) {
              final createdAtValue = orderData['createdAt'];
              if (createdAtValue is int) {
                createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
              } else if (createdAtValue is Timestamp) {
                createdAt = createdAtValue.toDate();
              } else {
                createdAt = DateTime.now();
              }
            } else {
              createdAt = DateTime.now();
            }
          } catch (e) {
            debugPrint('Error parsing createdAt: $e');
            createdAt = DateTime.now();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.carMake} ${widget.carModel}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Plate: ${widget.carPlate}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Client',
                              clientName,
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Created',
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              Icons.calendar_today_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Order ID',
                              widget.jobOrderId.substring(0, 8).toUpperCase(),
                              Icons.tag,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Status',
                              orderData['status'] ?? 'Pending',
                              Icons.info_outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // General Comments Section
                _buildGeneralCommentsSection(context, theme, colorScheme),

                const SizedBox(height: 24),

                // Service Requests Section
                Row(
                  children: [
                    Text(
                      'Service Requests',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${requests.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (requests.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No service requests',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This job order has no service requests yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final isDone = request['isDone'] ?? false;
                      final requestText =
                          request['request'] ?? 'Untitled Request';
                      final jobOrderNotes = request['jobOrderNotes'] ?? '';
                      final urgency = request['argancy'] ?? 'medium';
                      final source = request['source'] ?? 'session';
                      final sourceStage = request['sourceStage'] ?? 'unknown';
                      final jobOrderStatus =
                          request['jobOrderStatus'] ?? 'pending';
                      final assignedTo = request['assignedTo'] ?? '';
                      final estimatedHours = request['estimatedHours'] ?? '';
                      final price = request['price'] ?? '0';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getUrgencyColor(
                              urgency,
                            ).withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color:
                                        isDone
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                    border: Border.all(
                                      color:
                                          isDone
                                              ? colorScheme.primary
                                              : colorScheme.outline,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child:
                                      isDone
                                          ? Icon(
                                            Icons.check,
                                            color: colorScheme.onPrimary,
                                            size: 16,
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    requestText,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDone
                                                  ? colorScheme.outline
                                                  : colorScheme.onSurface,
                                          decoration:
                                              isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Add status toggle button
                                GestureDetector(
                                  onTap: () {
                                    _updateRequestStatus(
                                      requestId: request['id'] as String,
                                      isDone: !isDone,
                                    );
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color:
                                          isDone
                                              ? colorScheme.primary
                                              : Colors.transparent,
                                      border: Border.all(
                                        color:
                                            isDone
                                                ? colorScheme.primary
                                                : colorScheme.outline,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child:
                                        isDone
                                            ? Icon(
                                              Icons.check,
                                              color: colorScheme.onPrimary,
                                              size: 16,
                                            )
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Request metadata row
                            Row(
                              children: [
                                // Urgency badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getUrgencyColor(
                                      urgency,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    urgency.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: _getUrgencyColor(urgency),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Source badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.outline.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_getSourceDisplayName(source)} • ${_getStageDisplayName(sourceStage)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.outline,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      jobOrderStatus,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    jobOrderStatus.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: _getStatusColor(jobOrderStatus),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Additional job order details
                            if (assignedTo.isNotEmpty ||
                                estimatedHours.isNotEmpty ||
                                price != '0') ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (assignedTo.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Assigned to: $assignedTo',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (estimatedHours.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Estimated: ${estimatedHours}h',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (price != '0') ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.attach_money,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Price: AED $price',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // Job order notes if available
                            if (jobOrderNotes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Job Order Notes:',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      jobOrderNotes,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Comments Section
                            const SizedBox(height: 12),
                            _buildCommentsSection(context, request['id'], theme, colorScheme),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            onPressed: () => _showAddGeneralCommentDialog(context),
            backgroundColor: colorScheme.secondary,
            heroTag: "addComment",
            child: const Icon(Icons.add_comment, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              // Trigger a rebuild by showing a brief loading indicator
              Get.snackbar(
                'Refreshed',
                'Job order data refreshed',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
                backgroundColor: colorScheme.primary.withValues(alpha: 0.8),
                colorText: Colors.white,
                icon: const Icon(Icons.refresh, color: Colors.white),
              );
            },
            backgroundColor: colorScheme.primary,
            heroTag: "refresh",
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.outline),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Show dialog to add general job order comment
  void _showAddGeneralCommentDialog(BuildContext context) {
    final TextEditingController generalCommentController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Get.dialog(
      AlertDialog(
        title: Text(
          'Add General Comment',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a general comment about this job order that will be visible to all team members.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: generalCommentController,
              decoration: InputDecoration(
                hintText: 'Enter your comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              generalCommentController.dispose();
              Get.back();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.outline),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (generalCommentController.text.trim().isNotEmpty) {
                await _addComment('general', generalCommentController.text.trim());
                generalCommentController.dispose();
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Add Comment'),
          ),
        ],
      ),
    );
  }

  // Helper method to update request status in Firestore
  Future<void> _updateRequestStatus({
    required String requestId,
    required bool isDone,
  }) async {
    try {
      // First fetch the current document to get all requests
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('jobOrders')
              .doc(widget.jobOrderId)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final orderData = data['order'] as Map<String, dynamic>? ?? {};

        if (orderData['requests'] != null) {
          final List<dynamic> requests = List.from(orderData['requests']);

          // Find and update the specific request
          bool found = false;
          for (int i = 0; i < requests.length; i++) {
            if (requests[i] != null && requests[i]['id'] == requestId) {
              requests[i] = Map<String, dynamic>.from(requests[i]);
              requests[i]['isDone'] = isDone;
              requests[i]['jobOrderStatus'] = isDone ? 'completed' : 'pending';
              found = true;
              break;
            }
          }

          if (found) {
            // Update the entire requests array in Firestore
            await FirebaseFirestore.instance
                .collection('jobOrders')
                .doc(widget.jobOrderId)
                .update({
                  'order.requests': requests,
                  'updatedAt': DateTime.now().millisecondsSinceEpoch,
                });

            // Show success message
            Get.snackbar(
              'Updated',
              'Task status updated successfully',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green.withValues(alpha: 0.8),
              colorText: Colors.white,
              icon: const Icon(Icons.check_circle, color: Colors.white),
            );
          } else {
            debugPrint('Request with ID $requestId not found');
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating request status: $e');
      Get.snackbar(
        'Error',
        'Failed to update task status: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  // Helper method for urgency colors
  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper method for source display names
  String _getSourceDisplayName(String source) {
    switch (source.toLowerCase()) {
      case 'session':
        return 'Session';
      case 'client_request':
        return 'Client';
      case 'inspection_finding':
        return 'Inspection';
      case 'test_drive_observation':
        return 'Test Drive';
      case 'manual':
        return 'Manual';
      default:
        return source;
    }
  }

  // Helper method for stage display names
  String _getStageDisplayName(String stage) {
    switch (stage.toLowerCase()) {
      case 'clientnotes':
        return 'Client Notes';
      case 'inspection':
        return 'Inspection';
      case 'testdrive':
        return 'Test Drive';
      case 'report':
        return 'Report';
      case 'jobcard':
        return 'Job Card';
      default:
        return stage;
    }
  }

  // Helper method for status colors
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return Colors.green;
      case 'in_progress':
      case 'working':
        return Colors.blue;
      case 'pending':
      case 'open':
        return Colors.orange;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Comments Section Widget
  Widget _buildCommentsSection(BuildContext context, String requestId, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Team Comments',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobOrders')
                      .doc(widget.jobOrderId)
                      .collection('comments')
                      .where('requestId', isEqualTo: requestId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$commentCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Comments List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobOrders')
                .doc(widget.jobOrderId)
                .collection('comments')
                .where('requestId', isEqualTo: requestId)
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No comments yet. Be the first to add one!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final comment = doc.data() as Map<String, dynamic>;
                  final timestamp = comment['timestamp'] as Timestamp;
                  final timeAgo = _getTimeAgo(timestamp.toDate());
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                (comment['userName'] as String? ?? 'U')[0].toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment['userName'] ?? 'Unknown User',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    timeAgo,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comment['text'] ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          
          // Add Comment Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _getCommentController(requestId),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: colorScheme.outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => _addComment(requestId, value),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _addComment(requestId, _getCommentController(requestId).text),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.send,
                      color: colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Get or create comment controller for a request
  TextEditingController _getCommentController(String requestId) {
    if (!_commentControllers.containsKey(requestId)) {
      _commentControllers[requestId] = TextEditingController();
    }
    return _commentControllers[requestId]!;
  }

  // Add comment to Firestore
  Future<void> _addComment(String requestId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Authentication Error',
          'Please log in to add comments',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Get user name from auth controller or user profile
      String userName = user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous';

      await FirebaseFirestore.instance
          .collection('jobOrders')
          .doc(widget.jobOrderId)
          .collection('comments')
          .add({
        'requestId': requestId,
        'text': text.trim(),
        'userId': user.uid,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear the text field
      _getCommentController(requestId).clear();

      // Show success message
      Get.snackbar(
        'Comment Added',
        'Your comment has been added successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      debugPrint('Error adding comment: $e');
      Get.snackbar(
        'Error',
        'Failed to add comment: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  // Helper method to format time ago
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
