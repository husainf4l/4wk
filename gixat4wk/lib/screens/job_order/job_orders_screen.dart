import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:gixat4wk/screens/job_order/job_order_request_history_screen.dart';

class JobOrdersScreen extends StatefulWidget {
  const JobOrdersScreen({super.key});

  @override
  State<JobOrdersScreen> createState() => _JobOrdersScreenState();
}

class _JobOrdersScreenState extends State<JobOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Orders',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage vehicle service requests',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoFormSection.insetGrouped(
              backgroundColor: Colors.transparent,
              margin: EdgeInsets.zero,
              children: [
                CupertinoFormRow(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchQuery.value = value.trim().toLowerCase();
                    },
                    placeholder: 'Search job orders',
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.systemGrey2,
                    ),
                    style: const TextStyle(color: CupertinoColors.label),
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: CupertinoColors.systemGrey6,
                    prefixInsets: const EdgeInsets.only(left: 8, right: 8),
                    suffixInsets: const EdgeInsets.only(right: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('jobOrders')
                        .snapshots(), // Removed orderBy to avoid index issues
                builder: (context, snapshot) {
                  // Debug logging
                  print('JobOrders Stream State: ${snapshot.connectionState}');
                  print('JobOrders Has Data: ${snapshot.hasData}');
                  print(
                    'JobOrders Docs Count: ${snapshot.data?.docs.length ?? 0}',
                  );
                  if (snapshot.hasError) {
                    print('JobOrders Stream Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Check for errors
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading job orders',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No job orders found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a new job order to see it here',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          // Debug info
                          if (snapshot.hasData)
                            Text(
                              'Collection exists but is empty (${snapshot.data!.docs.length} documents)',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  final jobOrders =
                      snapshot.data!.docs.map((doc) {
                          try {
                            final data = doc.data() as Map<String, dynamic>;

                            // Extract car data from the nested structure with validation
                            final carData =
                                data['carData'] as Map<String, dynamic>? ?? {};
                            final carMake =
                                carData['make']?.toString() ?? 'Unknown';
                            final carModel =
                                carData['model']?.toString() ?? 'Unknown';
                            final carPlate =
                                carData['plate']?.toString() ??
                                carData['plateNumber']?.toString() ??
                                'Unknown';

                            // Extract order data with validation
                            final orderData =
                                data['order'] as Map<String, dynamic>? ?? {};

                            // Extract order requests with proper validation
                            List<Map<String, dynamic>> requests = [];
                            if (orderData['requests'] != null) {
                              final requestsList =
                                  orderData['requests'] as List<dynamic>? ?? [];
                              requests =
                                  requestsList
                                      .where(
                                        (item) => item != null && item is Map,
                                      )
                                      .map((item) {
                                        final requestMap =
                                            item as Map<String, dynamic>;
                                        return {
                                          'id':
                                              requestMap['id']?.toString() ??
                                              DateTime.now()
                                                  .millisecondsSinceEpoch
                                                  .toString(),
                                          'title':
                                              requestMap['title']?.toString() ??
                                              requestMap['name']?.toString() ??
                                              'Untitled Request',
                                          'isDone':
                                              requestMap['isDone'] == true,
                                          'notes':
                                              requestMap['notes']?.toString() ??
                                              requestMap['description']
                                                  ?.toString() ??
                                              '',
                                          'priority':
                                              requestMap['priority']
                                                  ?.toString() ??
                                              'medium',
                                        };
                                      })
                                      .toList();
                            }

                            // Create timestamp with validation
                            Timestamp createdAt;
                            if (orderData['createdAt'] != null) {
                              final createdAtValue = orderData['createdAt'];
                              if (createdAtValue is int) {
                                createdAt =
                                    Timestamp.fromMillisecondsSinceEpoch(
                                      createdAtValue,
                                    );
                              } else if (createdAtValue is Timestamp) {
                                createdAt = createdAtValue;
                              } else {
                                createdAt = Timestamp.now();
                              }
                            } else {
                              createdAt = Timestamp.now();
                            }

                            return {
                              'id': doc.id,
                              'orderNumber':
                                  doc.id.substring(0, 6).toUpperCase(),
                              'clientName':
                                  data['clientName']?.toString() ??
                                  'Unknown Client',
                              'status':
                                  orderData['status']?.toString() ?? 'open',
                              'createdAt': createdAt,
                              'carMake': carMake,
                              'carModel': carModel,
                              'carPlate': carPlate,
                              'requests': requests,
                              'totalRequests': requests.length,
                              'completedRequests':
                                  requests
                                      .where((r) => r['isDone'] == true)
                                      .length,
                            };
                          } catch (e) {
                            // Log error and return a safe fallback
                            debugPrint(
                              'Error processing job order ${doc.id}: $e',
                            );
                            return {
                              'id': doc.id,
                              'orderNumber':
                                  doc.id.substring(0, 6).toUpperCase(),
                              'clientName': 'Unknown Client',
                              'status': 'error',
                              'createdAt': Timestamp.now(),
                              'carMake': 'Unknown',
                              'carModel': 'Unknown',
                              'carPlate': 'Unknown',
                              'requests': <Map<String, dynamic>>[],
                              'totalRequests': 0,
                              'completedRequests': 0,
                              'hasError': true,
                            };
                          }
                        }).toList()
                        ..sort((a, b) {
                          // Sort by createdAt timestamp in descending order
                          final aTime = a['createdAt'] as Timestamp;
                          final bTime = b['createdAt'] as Timestamp;
                          return bTime.compareTo(aTime);
                        });

                  return Obx(() {
                    final query = _searchQuery.value;
                    final filteredJobOrders =
                        jobOrders.where((jobOrder) {
                          if (query.isEmpty) return true;

                          final orderNumberMatch = jobOrder['orderNumber']
                              .toString()
                              .toLowerCase()
                              .contains(query);
                          final clientNameMatch = jobOrder['clientName']
                              .toString()
                              .toLowerCase()
                              .contains(query);
                          final vehicleMatch =
                              jobOrder['carMake']
                                  .toString()
                                  .toLowerCase()
                                  .contains(query) ||
                              jobOrder['carModel']
                                  .toString()
                                  .toLowerCase()
                                  .contains(query) ||
                              jobOrder['carPlate']
                                  .toString()
                                  .toLowerCase()
                                  .contains(query);

                          return orderNumberMatch ||
                              clientNameMatch ||
                              vehicleMatch;
                        }).toList();

                    if (filteredJobOrders.isEmpty) {
                      return Center(
                        child: Text(
                          'No job orders match your search',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredJobOrders.length,
                      itemBuilder: (context, index) {
                        final jobOrder = filteredJobOrders[index];
                        final List<Map<String, dynamic>> requests =
                            List<Map<String, dynamic>>.from(
                              jobOrder['requests'] as List? ?? [],
                            );
                        final theme = Theme.of(context);
                        final colorScheme = theme.colorScheme;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  jobOrder['hasError'] == true
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : colorScheme.outline.withValues(
                                        alpha: 0.18,
                                      ),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Error indicator if there's an error
                              if (jobOrder['hasError'] == true)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_outlined,
                                        color: Colors.red[600],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Error loading job order data',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: Colors.red[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Car Info Section with Chat History Icon
                              InkWell(
                                onTap: () {
                                  Get.to(
                                    () => JobOrderRequestHistoryScreen(
                                      jobOrderId: jobOrder['id'] as String,
                                      carMake: jobOrder['carMake'] as String,
                                      carModel: jobOrder['carModel'] as String,
                                      carPlate: jobOrder['carPlate'] as String,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.directions_car,
                                          color: colorScheme.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${jobOrder['carMake']} ${jobOrder['carModel']}',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  jobOrder['carPlate']
                                                      as String,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            colorScheme.primary,
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      jobOrder['status']
                                                          as String,
                                                    ).withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _getStatusDisplayName(
                                                      jobOrder['status']
                                                          as String,
                                                    ),
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: _getStatusColor(
                                                            jobOrder['status']
                                                                as String,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.chat_outlined,
                                                  color: colorScheme.primary,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'History',
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color:
                                                            colorScheme.primary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (requests.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    jobOrder['completedRequests'] ==
                                                            jobOrder['totalRequests']
                                                        ? Colors.green
                                                            .withValues(
                                                              alpha: 0.1,
                                                            )
                                                        : Colors.orange
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${jobOrder['completedRequests']}/${jobOrder['totalRequests']}',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color:
                                                          jobOrder['completedRequests'] ==
                                                                  jobOrder['totalRequests']
                                                              ? Colors
                                                                  .green[700]
                                                              : Colors
                                                                  .orange[700],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.10,
                                ),
                              ),

                              // Progress indicator section
                              if (requests.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Progress',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                          ),
                                          Text(
                                            '${((jobOrder['completedRequests'] as int) / (jobOrder['totalRequests'] as int) * 100).round()}%',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value:
                                            (jobOrder['completedRequests']
                                                as int) /
                                            (jobOrder['totalRequests'] as int),
                                        backgroundColor: colorScheme.outline
                                            .withValues(alpha: 0.2),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              jobOrder['completedRequests'] ==
                                                      jobOrder['totalRequests']
                                                  ? Colors.green
                                                  : colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (requests.isNotEmpty)
                                Divider(
                                  height: 1,
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.10,
                                  ),
                                ),

                              // Tasks Section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (requests.isNotEmpty)
                                      ...requests.map((request) {
                                        final isChecked = RxBool(
                                          request['isDone'] ?? false,
                                        );
                                        return Obx(
                                          () => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 3,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    request['title'],
                                                    style: theme
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              isChecked.value
                                                                  ? colorScheme
                                                                      .outline
                                                                  : colorScheme
                                                                      .onSurface,
                                                          decoration:
                                                              isChecked.value
                                                                  ? TextDecoration
                                                                      .lineThrough
                                                                  : null,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                GestureDetector(
                                                  onTap: () {
                                                    isChecked.value =
                                                        !isChecked.value;
                                                    _updateRequestStatus(
                                                      jobOrderId:
                                                          jobOrder['id']
                                                              as String,
                                                      requestId:
                                                          request['id']
                                                              as String,
                                                      isDone: isChecked.value,
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 22,
                                                    height: 22,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isChecked.value
                                                              ? colorScheme
                                                                  .primary
                                                              : Colors
                                                                  .transparent,
                                                      border: Border.all(
                                                        color:
                                                            isChecked.value
                                                                ? colorScheme
                                                                    .primary
                                                                : colorScheme
                                                                    .outline,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child:
                                                        isChecked.value
                                                            ? Icon(
                                                              Icons.check,
                                                              color:
                                                                  colorScheme
                                                                      .onPrimary,
                                                              size: 16,
                                                            )
                                                            : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    if (requests.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          "No requests for this job order",
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: colorScheme.outline,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to update request status in Firestore
  Future<void> _updateRequestStatus({
    required String jobOrderId,
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
        if (data['order'] != null && data['order']['requests'] != null) {
          final List<dynamic> requests = data['order']['requests'];

          // Find and update the specific request
          for (int i = 0; i < requests.length; i++) {
            if (requests[i]['id'] == requestId) {
              requests[i]['isDone'] = isDone;
              break;
            }
          }

          // Update the entire requests array in Firestore
          await FirebaseFirestore.instance
              .collection('jobOrders')
              .doc(jobOrderId)
              .update({'order.requests': requests});

          // Show success message
          Get.snackbar(
            'Updated',
            'Task status updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.withValues(alpha: 0.7),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating request status: $e');
      Get.snackbar(
        'Error',
        'Failed to update task status',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
        colorText: Colors.white,
      );
    }
  }

  // Helper methods for status handling
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'working':
        return Colors.blue;
      case 'completed':
      case 'done':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'working':
        return 'Working';
      case 'completed':
        return 'Completed';
      case 'done':
        return 'Done';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'error':
        return 'Error';
      default:
        return status.toUpperCase();
    }
  }
}
