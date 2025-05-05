import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:gixat4wk/screens/job_order/job_order_request_history_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../services/database_service.dart';

class JobOrdersScreen extends StatelessWidget {
  const JobOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final DatabaseService databaseService = Get.find<DatabaseService>();
    final TextEditingController searchController = TextEditingController();
    final RxString searchQuery = ''.obs;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job Orders',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                    controller: searchController,
                    onChanged: (value) {
                      searchQuery.value = value.trim().toLowerCase();
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
                        .orderBy('order.createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                        ],
                      ),
                    );
                  }

                  final jobOrders =
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        // Extract car data from the nested structure
                        final carData =
                            data['carData'] as Map<String, dynamic>? ?? {};
                        final carMake = carData['make'] ?? 'Unknown';
                        final carModel = carData['model'] ?? 'Unknown';
                        final carPlate = carData['plate'] ?? 'Unknown';

                        // Extract order requests
                        List<Map<String, dynamic>> requests = [];
                        if (data['order'] != null &&
                            data['order']['requests'] != null) {
                          final requestsList =
                              data['order']['requests'] as List<dynamic>;
                          requests =
                              requestsList
                                  .map(
                                    (item) => {
                                      'id':
                                          item['id'] ??
                                          DateTime.now().millisecondsSinceEpoch
                                              .toString(),
                                      'title':
                                          item['title'] ?? 'Untitled Request',
                                      'isDone': item['isDone'] ?? false,
                                      'notes': item['notes'] ?? '',
                                    },
                                  )
                                  .toList();
                        }

                        return {
                          'id': doc.id,
                          'orderNumber': doc.id.substring(0, 6).toUpperCase(),
                          'clientName': data['clientName'] ?? 'Unknown Client',
                          'status': data['order']?['status'] ?? 'Pending',
                          'createdAt':
                              data['order']?['createdAt'] != null
                                  ? Timestamp.fromMillisecondsSinceEpoch(
                                    data['order']['createdAt'],
                                  )
                                  : Timestamp.now(),
                          'carMake': carMake,
                          'carModel': carModel,
                          'carPlate': carPlate,
                          'requests': requests,
                        };
                      }).toList();

                  return Obx(() {
                    final query = searchQuery.value;
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
                              jobOrder['requests'],
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
                              color: colorScheme.outline.withOpacity(0.18),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Car Info Section with Chat History Icon
                              InkWell(
                                onTap: () {
                                  Get.to(
                                    () => JobOrderRequestHistoryScreen(
                                      jobOrderId: jobOrder['id'],
                                      carMake: jobOrder['carMake'],
                                      carModel: jobOrder['carModel'],
                                      carPlate: jobOrder['carPlate'],
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
                                          color: colorScheme.primary
                                              .withOpacity(0.12),
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
                                            Text(
                                              jobOrder['carPlate'],
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: colorScheme.primary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary
                                              .withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Divider(
                                height: 1,
                                color: colorScheme.outline.withOpacity(0.10),
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
                                                          jobOrder['id'],
                                                      requestId: request['id'],
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
                                      }).toList(),
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

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
            backgroundColor: Colors.green.withOpacity(0.7),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('Error updating request status: $e');
      Get.snackbar(
        'Error',
        'Failed to update task status',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
    }
  }
}
