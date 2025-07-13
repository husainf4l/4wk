import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/car.dart';
import '../../models/session.dart';
import '../../services/car_service.dart';
import '../../services/session/session_service.dart';
import '../../utils/session_utils.dart';
import '../sessions/session_details_screen.dart';
import '../sessions/old/create_session_screen.dart';
import 'edit_car_screen.dart'; // Import for EditCarScreen

class CarDetailsScreen extends StatefulWidget {
  final Car car;

  const CarDetailsScreen({super.key, required this.car});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  final CarService _carService = CarService();
  final SessionService _sessionService = SessionService();

  // Track car data for refreshes
  late Car _car;

  @override
  void initState() {
    super.initState();
    _car = widget.car;
  }

  // Launch WhatsApp with the provided phone number

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
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
                        'Vehicle Details',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.penToSquare),
                    onPressed: () async {
                      // Navigate to edit car screen
                      final result = await Get.to(
                        () => EditCarScreen(car: _car),
                        transition: Transition.rightToLeft,
                      );

                      // If returned with updated car, update the state
                      if (result != null && result is Car) {
                        setState(() {
                          _car = result;
                        });
                      }
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
                    // Car Information Card
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
                                Icon(
                                  Icons.directions_car,
                                  size: 36,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_car.make} ${_car.model}',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Year: ${_car.year}',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            // Vehicle specifications
                            Text(
                              'Vehicle Details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              theme,
                              'License Plate',
                              _car.plateNumber,
                              Icons.credit_card,
                            ),
                            if (_car.vin.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                theme,
                                'VIN',
                                _car.vin,
                                Icons.tag,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Service History Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service History',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            // Register SessionService with GetX
                            Get.put(_sessionService);

                            // Use car service to get the client details
                            _carService.getClientById(_car.clientId).then((
                              client,
                            ) {
                              if (client != null) {
                                // Navigate to create session screen with the client and car
                                Get.to(
                                  () => CreateSessionScreen(
                                    preSelectedClient: client,
                                    preSelectedCar: _car,
                                  ),
                                );
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'Could not find client information',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            });
                          },
                          tooltip: 'Create New Session',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Service Sessions List
                    _buildServiceSessionsList(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    // Special case for phone number (Contact row)
    if (icon == Icons.phone) {
      return Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
          const Spacer(),

          // WhatsApp button
        ],
      );
    }

    // Standard row for other details
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  // Service sessions list builder
  Widget _buildServiceSessionsList(ThemeData theme) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getCarSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading service history',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return Card(
            elevation: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No service history for this vehicle',
                    style: TextStyle(color: Colors.grey[600]),
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
            final sessionData = sessionDoc.data() as Map<String, dynamic>;
            final session = Session.fromMap(sessionData, sessionDoc.id);

            // Format date
            String formattedDate = 'Unknown date';
            if (session.createdAt != null) {
              formattedDate =
                  '${session.createdAt!.day}/${session.createdAt!.month}/${session.createdAt!.year}';
            }

            // Status color
            Color statusColor = SessionUtils.getStatusColor(session.status);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.build, color: Colors.blue),
                ),
                title: Text('Service on $formattedDate'),
                subtitle: Text(
                  session.clientNoteId != null
                      ? 'Client notes available'
                      : 'No notes',
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
                    SessionUtils.formatStatus(session.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  // Navigate to session details
                  Get.to(
                    () => SessionDetailsScreen(session: session),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to get sessions for this car
  Future<List<DocumentSnapshot>> _getCarSessions() async {
    try {
      return await FirebaseFirestore.instance
          .collection('sessions')
          .where('carId', isEqualTo: _car.id)
          .orderBy('createdAt', descending: true)
          .get()
          .then((snapshot) => snapshot.docs);
    } catch (e) {
      debugPrint('Error getting car sessions: $e');
      return [];
    }
  }
}
