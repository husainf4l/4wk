import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gixat4wk/screens/add_car_screen.dart';
import 'package:gixat4wk/screens/sessions/old/create_session_screen.dart';
import '../../models/client.dart';
import '../../models/car.dart';
import '../../models/session.dart';
import '../../services/client_service.dart';
import '../../services/car_service.dart';
import '../../services/session/session_service.dart';
import '../../screens/sessions/session_details_screen.dart';
import '../../utils/session_utils.dart';
import '../../screens/cars/car_details_screen.dart'; // Import for CarDetailsScreen
import 'edit_client_screen.dart'; // Import for EditClientScreen

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final ClientService _clientService = ClientService();
  final CarService _carService = CarService();
  final SessionService _sessionService = SessionService();

  // Trigger to force refresh when data changes
  final _refreshTrigger = ValueNotifier<bool>(false);

  // Launch call with the provided phone number
  Future<void> _launchCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(callUri);
    } catch (e) {
      debugPrint('Could not launch call: $e');
      Get.snackbar(
        'Error',
        'Could not launch call function',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Launch WhatsApp with the provided phone number
  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Format the phone number - remove any non-digit characters
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

    try {
      // Try different approaches for different platforms

      // First approach - standard wa.me URL
      final whatsappUrl = Uri.parse('https://wa.me/$formattedPhone');

      bool launched = false;

      // Try standard approach first
      if (await canLaunchUrl(whatsappUrl)) {
        launched = await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      }

      // If standard approach failed, try direct intent on Android
      if (!launched) {
        // Package URL for WhatsApp (works better on some Android devices)
        Uri whatsappIntentUrl = Uri.parse(
          "whatsapp://send?phone=$formattedPhone",
        );

        if (await canLaunchUrl(whatsappIntentUrl)) {
          launched = await launchUrl(whatsappIntentUrl);
        }
      }

      if (!launched) {
        Get.snackbar(
          'Error',
          'Could not open WhatsApp. Make sure WhatsApp is installed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
      Get.snackbar(
        'Error',
        'Could not open WhatsApp. Make sure WhatsApp is installed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _refreshTrigger,
          builder: (context, refresh, child) {
            return FutureBuilder<Client?>(
              future: _clientService.getClientById(widget.clientId),
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
                            icon: const Icon(FontAwesomeIcons.penToSquare),
                            onPressed: () async {
                              // Navigate to edit client screen
                              final result = await Get.to(
                                () => EditClientScreen(client: client),
                                transition: Transition.rightToLeft,
                              );

                              // Check if we need to refresh
                              if (result != null && result['refresh'] == true) {
                                // Trigger refresh
                                _refreshTrigger.value = !_refreshTrigger.value;
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                client.name,
                                                style: theme
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                        theme
                                                            .textTheme
                                                            .bodyMedium,
                                                  ),
                                                  const Spacer(),
                                                  // WhatsApp icon button
                                                  IconButton(
                                                    icon: Icon(
                                                      FontAwesomeIcons.whatsapp,
                                                      color: Colors.green[700],
                                                      size: 22,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed:
                                                        () => _launchWhatsApp(
                                                          client.phone,
                                                        ),
                                                  ),
                                                  // Call icon button
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.call,
                                                      color: Colors.blue,
                                                      size: 20,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed:
                                                        () => _launchCall(
                                                          client.phone,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    // Navigate to add car screen with client information
                                    Get.to(
                                      () => const AddCarScreen(),
                                      arguments: {
                                        'clientId': client.id,
                                        'clientName': client.name,
                                        'clientPhoneNumber': client.phone,
                                      },
                                    );
                                  },
                                  tooltip: 'Add New Car',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<List<Car>>(
                              future: _carService.getClientCars(
                                widget.clientId,
                              ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                        leading: Icon(
                                          Icons.directions_car,
                                          color: Colors.white,
                                        ),
                                        title: Text(
                                          '${car.make} ${car.model} (${car.year})',
                                        ),
                                        subtitle: Text(
                                          'Plate: ${car.plateNumber}',
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                        ),
                                        onTap: () {
                                          // Navigate to car details screen
                                          Get.to(
                                            () => CarDetailsScreen(car: car),
                                            transition: Transition.rightToLeft,
                                          );
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
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    // Register SessionService with GetX before navigation
                                    Get.put(_sessionService);

                                    // Navigate to create session screen with pre-selected client
                                    Get.to(
                                      () => CreateSessionScreen(
                                        preSelectedClient: client,
                                      ),
                                    );
                                  },
                                  tooltip: 'Add New Session',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<List<DocumentSnapshot>>(
                              future: _sessionService.getClientSessions(
                                widget.clientId,
                              ),
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
                                      debugPrint(
                                        '======== INDEX ERROR ========',
                                      );
                                      debugPrint(error.message);
                                      debugPrint(
                                        '============================',
                                      );

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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                        sessionDoc.data()
                                            as Map<String, dynamic>;
                                    final session = Session.fromMap(
                                      sessionData,
                                      sessionDoc.id,
                                    );

                                    final carData = session.car;
                                    final String carMake =
                                        carData['make'] ?? '';
                                    final String carModel =
                                        carData['model'] ?? '';
                                    final String plateNumber =
                                        carData['plateNumber'] ?? '';

                                    // Format date
                                    String formattedDate = 'Unknown date';
                                    if (session.createdAt != null) {
                                      formattedDate =
                                          '${session.createdAt!.day}/${session.createdAt!.month}/${session.createdAt!.year}';
                                    }

                                    // Status color
                                    Color statusColor =
                                        SessionUtils.getStatusColor(
                                          session.status,
                                        );

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.build,
                                          color: Colors.blue,
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: statusColor,
                                            ),
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
            );
          },
        ),
      ),
    );
  }
}
