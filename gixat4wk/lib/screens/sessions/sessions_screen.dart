import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:gixat4wk/screens/sessions/old/create_session_screen.dart';
import 'package:gixat4wk/screens/sessions/session_details_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../services/database_service.dart';
import '../../models/session.dart';
import '../../utils/session_utils.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final DatabaseService databaseService = Get.find<DatabaseService>();
    final theme = Theme.of(context);
    final TextEditingController searchController = TextEditingController();
    final RxString searchQuery = ''.obs;
    final RxSet<String> selectedStatusFilters = <String>{}.obs;
    final List<String> statusOptions = ['OPEN', 'TESTED', 'INSPECTED', 'NOTED'];

    void showStatusFilterDialog() {
      showCupertinoModalPopup(
        context: context,
        builder:
            (context) => CupertinoActionSheet(
              title: const Text('Filter by Status'),
              message: const Text('Select status types to filter'),
              actions: [
                ...statusOptions.map(
                  (status) => CupertinoActionSheetAction(
                    onPressed: () {
                      if (selectedStatusFilters.contains(status)) {
                        selectedStatusFilters.remove(status);
                      } else {
                        selectedStatusFilters.add(status);
                      }
                      Navigator.of(context).pop();
                    },
                    isDefaultAction: selectedStatusFilters.contains(status),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: SessionUtils.getStatusColor(status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(SessionUtils.formatStatus(status)),
                          ],
                        ),
                        if (selectedStatusFilters.contains(status))
                          const Icon(CupertinoIcons.check_mark, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  selectedStatusFilters.clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Clear Filters'),
              ),
            ),
      );
    }

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
                  'Sessions',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Ensure title is black
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: Colors.black,
                  ), // Black icon
                  onPressed: () => Get.to(() => const CreateSessionScreen()),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoSearchTextField(
                          controller: searchController,
                          onChanged: (value) {
                            searchQuery.value = value.trim().toLowerCase();
                          },
                          placeholder: 'Search by client, car, or plate',
                          placeholderStyle: const TextStyle(
                            color: CupertinoColors.systemGrey2,
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                          ), // Black text
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: CupertinoColors.systemGrey6,
                          prefixInsets: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                          ),
                          suffixInsets: const EdgeInsets.only(right: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(
                        () => GestureDetector(
                          onTap: showStatusFilterDialog,
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.line_horizontal_3_decrease,
                                  color:
                                      selectedStatusFilters.isNotEmpty
                                          ? Colors
                                              .red // Use red for active
                                          : Colors.black, // Black for inactive
                                  size: 16,
                                ),
                                if (selectedStatusFilters.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red, // Red badge
                                    ),
                                    child: Text(
                                      selectedStatusFilters.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Status filter chips
            Obx(
              () =>
                  selectedStatusFilters.isNotEmpty
                      ? SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              selectedStatusFilters
                                  .map(
                                    (status) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGrey6,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: SessionUtils.getStatusColor(
                                              status,
                                            ).withAlpha(52),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color:
                                                    SessionUtils.getStatusColor(
                                                      status,
                                                    ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              SessionUtils.formatStatus(status),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Colors.black, // Black text
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap:
                                                  () => selectedStatusFilters
                                                      .remove(status),
                                              child: const Icon(
                                                CupertinoIcons
                                                    .xmark_circle_fill,
                                                size: 14,
                                                color:
                                                    Colors.black, // Black icon
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
            selectedStatusFilters.isNotEmpty
                ? const SizedBox(height: 8)
                : const SizedBox.shrink(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: databaseService.queryCollection('sessions', [
                  ['garageId', authController.garageId],
                ]),
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
                            Icons.feed_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No active sessions found',
                            style: TextStyle(
                              color: Colors.black, // Black text
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a new session to see it here',
                            style: TextStyle(color: Colors.black), // Black text
                          ),
                        ],
                      ),
                    );
                  }

                  final sessions =
                      snapshot.data!.docs
                          .map(
                            (doc) => Session.fromMap(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                            ),
                          )
                          .where((session) => session.status != 'CLOSED')
                          .toList();

                  return Obx(() {
                    final query = searchQuery.value;
                    final statusFilters = selectedStatusFilters;

                    var filteredSessions = sessions;

                    // Apply text search filter if query is not empty
                    if (query.isNotEmpty) {
                      filteredSessions =
                          filteredSessions.where((session) {
                            final clientName =
                                (session.client['name'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final carMake =
                                (session.car['make'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final carModel =
                                (session.car['model'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final plate =
                                (session.car['plateNumber'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            return clientName.contains(query) ||
                                carMake.contains(query) ||
                                carModel.contains(query) ||
                                plate.contains(query);
                          }).toList();
                    }

                    // Apply status filters if any are selected
                    if (statusFilters.isNotEmpty) {
                      filteredSessions =
                          filteredSessions.where((session) {
                            return statusFilters.contains(
                              session.status.toUpperCase(),
                            );
                          }).toList();
                    }

                    if (filteredSessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sessions match your filters',
                              style: TextStyle(
                                color: Colors.black, // Black text
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                searchController.clear();
                                searchQuery.value = '';
                                selectedStatusFilters.clear();
                              },
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Clear all filters',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        final car = session.car;
                        final client = session.client;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: SessionUtils.getStatusColor(
                                session.status,
                              ),
                              child: Icon(
                                SessionUtils.getStatusIcon(session.status),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              '${car['make']} ${car['model']} (${car['plateNumber']})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.black,
                              ), // Black text
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '${client['name']} ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.black,
                                  ), // Black text
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigate to session details page
                              Get.to(
                                () => SessionDetailsScreen(session: session),
                              );
                            },
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
}
