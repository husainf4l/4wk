import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gixat4wk/screens/sessions/create_session_screen.dart';
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
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Status',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...statusOptions.map((status) {
                      return CheckboxListTile(
                        title: Text(SessionUtils.formatStatus(status)),
                        value: selectedStatusFilters.contains(status),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              selectedStatusFilters.add(status);
                            } else {
                              selectedStatusFilters.remove(status);
                            }
                          });
                        },
                        secondary: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: SessionUtils.getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setModalState(() {
                                selectedStatusFilters.clear();
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sessions',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Get.to(() => const CreateSessionScreen()),
            tooltip: 'Create Session',
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      searchQuery.value = value.trim().toLowerCase();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by client, car, or plate...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => Badge(
                    isLabelVisible: selectedStatusFilters.isNotEmpty,
                    label: Text(selectedStatusFilters.length.toString()),
                    child: IconButton(
                      onPressed: showStatusFilterDialog,
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Filter by Status',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Active Filter Chips
            Obx(
              () =>
                  selectedStatusFilters.isNotEmpty
                      ? SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              selectedStatusFilters
                                  .map(
                                    (status) => Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor:
                                              SessionUtils.getStatusColor(
                                                status,
                                              ),
                                          radius: 6,
                                        ),
                                        label: Text(
                                          SessionUtils.formatStatus(status),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onDeleted:
                                            () => selectedStatusFilters.remove(
                                              status,
                                            ),
                                        backgroundColor:
                                            SessionUtils.getStatusColor(
                                              status,
                                            ).withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color: SessionUtils.getStatusColor(
                                              status,
                                            ).withValues(alpha: 0.2),
                                          ),
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

            // Session List
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
                            Icons.car_repair,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Sessions',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a new session to see it here.',
                            style: TextStyle(color: Colors.grey[600]),
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

                    // Apply text search filter
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

                    // Apply status filters
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
                            const Text(
                              'No sessions match your filters',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                searchController.clear();
                                searchQuery.value = '';
                                selectedStatusFilters.clear();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Clear All Filters'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        return _SessionCard(session: session);
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

class _SessionCard extends StatelessWidget {
  final Session session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final car = session.car;
    final client = session.client;
    final statusColor = SessionUtils.getStatusColor(session.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.to(() => SessionDetailsScreen(session: session)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${car['make']} ${car['model']}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: statusColor, radius: 4),
                        const SizedBox(width: 6),
                        Text(
                          SessionUtils.formatStatus(session.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Plate: ${car['plateNumber'] ?? 'N/A'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const Divider(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Client: ${client['name'] ?? 'Unknown'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
