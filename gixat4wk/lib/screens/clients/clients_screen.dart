import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:gixat4wk/screens/add_client_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../services/database_service.dart';
import '../../models/client.dart';
import 'client_details_screen.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

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
                  'Clients',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    //navigate to add client screen
                    Get.to(() => const AddClientScreen());
                  },
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
                    placeholder: 'Search by name or phone',
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
                stream: databaseService.queryCollection('clients', [
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
                            Icons.person_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No clients found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a new client to see them here',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  final clients =
                      snapshot.data!.docs
                          .map((doc) => Client.fromFirestore(doc))
                          .toList();

                  return Obx(() {
                    final query = searchQuery.value;
                    final filteredClients =
                        clients.where((client) {
                          if (query.isEmpty) return true;
                          final nameMatch = client.name.toLowerCase().contains(
                            query,
                          );
                          final phoneMatch = client.phone
                              .replaceAll(' ', '')
                              .contains(query.replaceAll(' ', ''));
                          return nameMatch || phoneMatch;
                        }).toList();

                    if (filteredClients.isEmpty) {
                      return Center(
                        child: Text(
                          'No clients match your search',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              client.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              'Contact: ${client.phone}',
                              style: theme.textTheme.bodySmall,
                            ),
                            onTap: () {
                              Get.to(
                                () => ClientDetailsScreen(clientId: client.id),
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
