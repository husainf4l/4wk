import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobOrderRequestHistoryScreen extends StatelessWidget {
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
              '$carMake $carModel',
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
                .doc(jobOrderId)
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

          // Validate and extract requests with better error handling
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
                        'id':
                            requestMap['id']?.toString() ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        'title':
                            requestMap['title']?.toString() ??
                            requestMap['name']?.toString() ??
                            'Untitled Request',
                        'isDone': requestMap['isDone'] == true,
                        'notes':
                            requestMap['notes']?.toString() ??
                            requestMap['description']?.toString() ??
                            '',
                        'priority':
                            requestMap['priority']?.toString() ?? 'medium',
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
                                  '$carMake $carModel',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Plate: $carPlate',
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
                              jobOrderId.substring(0, 8).toUpperCase(),
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
                      final title = request['title'] ?? 'Untitled Request';
                      final notes = request['notes'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.15),
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
                                    title,
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
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  notes,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.refresh, color: Colors.white),
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
              .doc(jobOrderId)
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
              found = true;
              break;
            }
          }

          if (found) {
            // Update the entire requests array in Firestore
            await FirebaseFirestore.instance
                .collection('jobOrders')
                .doc(jobOrderId)
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
}
