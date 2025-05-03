import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/client.dart';
import '../../models/car.dart';
import '../../models/session.dart';
import '../../services/client_service.dart';
import '../../services/car_service.dart';
import '../../services/session_service.dart';
import '../../screens/sessions/session_details_screen.dart';
import '../../utils/session_utils.dart';

class ClientDetailsScreen extends StatelessWidget {
  final String clientId;
  final ClientService _clientService = ClientService();
  final CarService _carService = CarService();
  final SessionService _sessionService = SessionService();

  ClientDetailsScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Client?>(
          future: _clientService.getClientById(clientId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Client not found'));
            }

            final client = snapshot.data!;

            return Column(
              children: [
                // Custom header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Get.back(),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Client Details',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          debugPrint('Edit button pressed');
                        },
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client Information Card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        client.name.isNotEmpty
                                            ? client.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            client.name,
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                client.phone,
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                if (client.address.city != null ||
                                    client.address.country != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${client.address.city ?? ""}, ${client.address.country ?? ""}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Client Cars Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cars',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Car'),
                              onPressed: () {
                                // Navigate to add car screen with client pre-selected
                                Get.toNamed(
                                  '/add-car',
                                  arguments: {
                                    'clientId': client.id,
                                    'clientName': client.name,
                                    'clientPhone': client.phone,
                                    'garageId': client.garageId,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<Car>>(
                          future: _carService.getClientCars(clientId),
                          builder: (context, carSnapshot) {
                            if (carSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final cars = carSnapshot.data ?? [];

                            if (cars.isEmpty) {
                              return Card(
                                elevation: 2,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.directions_car_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No cars added yet',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cars.length,
                              itemBuilder: (context, index) {
                                final car = cars[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Icon(
                                        Icons.directions_car,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      '${car.make} ${car.model} (${car.year})',
                                    ),
                                    subtitle: Text('Plate: ${car.plateNumber}'),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      debugPrint('Edit button pressed');
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Client Sessions Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Service Sessions',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('New Session'),
                              onPressed: () {
                                // Navigate to new session screen with client pre-selected
                                Get.toNamed(
                                  '/new-session',
                                  arguments: {
                                    'clientId': client.id,
                                    'clientName': client.name,
                                    'clientPhone': client.phone,
                                    'garageId': client.garageId,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<DocumentSnapshot>>(
                          future: _sessionService.getClientSessions(clientId),
                          builder: (context, sessionSnapshot) {
                            if (sessionSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (sessionSnapshot.hasError) {
                              // Check for index-related errors
                              final error = sessionSnapshot.error;
                              if (error is FirebaseException &&
                                  error.code == 'failed-precondition') {
                                // Check if it's an index error and extract the URL
                                if (error.message != null &&
                                    error.message!.contains('index')) {
                                  debugPrint('======== INDEX ERROR ========');
                                  debugPrint(error.message);
                                  debugPrint('============================');

                                  return Card(
                                    elevation: 2,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.red[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Database index error. Please contact support.',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              }

                              return Card(
                                elevation: 2,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error loading sessions. Please try again.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final sessions = sessionSnapshot.data ?? [];

                            if (sessions.isEmpty) {
                              return Card(
                                elevation: 2,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.build_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No service sessions yet',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sessions.length,
                              itemBuilder: (context, index) {
                                final sessionDoc = sessions[index];
                                final sessionData =
                                    sessionDoc.data() as Map<String, dynamic>;
                                final session = Session.fromMap(
                                  sessionData,
                                  sessionDoc.id,
                                );

                                final carData = session.car;
                                final String carMake = carData['make'] ?? '';
                                final String carModel = carData['model'] ?? '';
                                final String plateNumber =
                                    carData['plateNumber'] ?? '';

                                // Format date
                                String formattedDate = 'Unknown date';
                                if (session.createdAt != null) {
                                  formattedDate =
                                      '${session.createdAt!.day}/${session.createdAt!.month}/${session.createdAt!.year}';
                                }

                                // Status color
                                Color statusColor = SessionUtils.getStatusColor(
                                  session.status,
                                );

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[100],
                                      child: const Icon(
                                        Icons.build,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    title: Text('$carMake $carModel'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Plate: $plateNumber'),
                                        const SizedBox(height: 4),
                                        Text('Date: $formattedDate'),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(51),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusColor),
                                      ),
                                      child: Text(
                                        SessionUtils.formatStatus(
                                          session.status,
                                        ),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      // Navigate to session details screen
                                      Get.to(
                                        () => SessionDetailsScreen(
                                          session: session,
                                        ),
                                        transition: Transition.rightToLeft,
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
