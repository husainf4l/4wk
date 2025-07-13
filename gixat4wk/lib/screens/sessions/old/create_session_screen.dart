import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:gixat4wk/screens/add_client_screen.dart';
import 'package:gixat4wk/screens/add_car_screen.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/database_service.dart';
import '../../../services/session/session_service.dart'; // Import SessionService
import '../../../models/client.dart';
import '../../../models/car.dart';
import '../../../models/session.dart';
import '../session_details_screen.dart';
import 'dart:async'; // Add import for StreamSubscription

class CreateSessionScreen extends StatefulWidget {
  final Client? preSelectedClient; // Add parameter for pre-selected client
  final Car? preSelectedCar; // Add parameter for pre-selected car

  const CreateSessionScreen({
    super.key,
    this.preSelectedClient,
    this.preSelectedCar,
  });

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  final SessionService _sessionService =
      Get.find<SessionService>(); // Get SessionService instance

  final TextEditingController _searchController = TextEditingController();

  Client? _selectedClient;
  Car? _selectedCar;

  List<Client> _clients = [];
  List<Car> _cars = [];
  bool _isLoading = true;
  String _searchQuery = '';

  StreamSubscription?
  _clientsSubscription; // Add StreamSubscription for clients
  StreamSubscription? _carsSubscription; // Add StreamSubscription for cars

  @override
  void initState() {
    super.initState();
    _loadClients();

    // If a pre-selected client was provided, select it immediately
    if (widget.preSelectedClient != null) {
      _selectedClient = widget.preSelectedClient;
      _loadClientCars(widget.preSelectedClient!.id);
    }

    // If a pre-selected car was provided, select it immediately
    if (widget.preSelectedCar != null) {
      _selectedCar = widget.preSelectedCar;
    }
  }

  @override
  void dispose() {
    // Cancel subscriptions when the widget is disposed
    _clientsSubscription?.cancel();
    _carsSubscription?.cancel();
    super.dispose();
  }

  void _loadClients() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Set up a subscription to the clients stream
      _clientsSubscription = _databaseService
          .queryCollection('clients', [
            ['garageId', _authController.garageId],
          ])
          .listen(
            (snapshot) {
              if (!mounted) return;

              final clientsList =
                  snapshot.docs
                      .map((doc) => Client.fromFirestore(doc))
                      .toList();

              setState(() {
                _clients = clientsList;
                _isLoading = false;
              });
            },
            onError: (e) {
              debugPrint('Error loading clients: $e');
              if (!mounted) return;

              setState(() {
                _isLoading = false;
              });
            },
          );
    } catch (e) {
      debugPrint('Error setting up clients stream: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadClientCars(String clientId) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _cars = [];
      _selectedCar = null;
    });

    try {
      // Cancel existing subscription if any
      _carsSubscription?.cancel();

      // Set up a subscription to the cars stream
      _carsSubscription = _databaseService
          .queryCollection('cars', [
            ['clientId', clientId],
          ])
          .listen(
            (snapshot) {
              if (!mounted) return;

              final carsList =
                  snapshot.docs
                      .map(
                        (doc) => Car.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                      .toList();

              setState(() {
                _cars = carsList;
                _isLoading = false;
              });
            },
            onError: (e) {
              debugPrint('Error loading cars: $e');
              if (!mounted) return;

              setState(() {
                _isLoading = false;
              });
            },
          );
    } catch (e) {
      debugPrint('Error setting up cars stream: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectClient(Client client) {
    setState(() {
      _selectedClient = client;
    });
    _loadClientCars(client.id);
  }

  void _selectCar(Car car) {
    setState(() {
      _selectedCar = car;
    });
  }

  void _createSession() async {
    if (_selectedClient == null || _selectedCar == null) {
      Get.snackbar(
        'Error',
        'Please select both a client and a car',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Use the SessionService to create a session with consistent structure
      final sessionId = await _sessionService.createSession(
        clientId: _selectedClient!.id,
        clientName: _selectedClient!.name,
        clientPhoneNumber: _selectedClient!.phone,
        carId: _selectedCar!.id,
        carMake: _selectedCar!.make,
        carModel: _selectedCar!.model,
        plateNumber: _selectedCar!.plateNumber,
        garageId: _authController.garageId ?? '',
        carYear: _selectedCar!.year,
        carVin: _selectedCar!.vin,
      );

      if (sessionId == null) {
        throw Exception("Failed to create session");
      }

      // Update the car's sessions list
      final updatedCar = _selectedCar!.addSession(sessionId);
      await _databaseService.updateDocument(
        'cars',
        _selectedCar!.id,
        updatedCar.toMap(),
      );

      // Update the client's sessions list
      final updatedSessionsId = List<String>.from(_selectedClient!.sessionsId);
      updatedSessionsId.add(sessionId);
      await _databaseService.updateDocument('clients', _selectedClient!.id, {
        'sessionsId': updatedSessionsId,
      });

      // Create a proper Session object that matches the constructor
      final newSession = Session(
        id: sessionId,
        clientId: _selectedClient!.id,
        garageId: _authController.garageId ?? '',
        car: {
          'id': _selectedCar!.id,
          'make': _selectedCar!.make,
          'model': _selectedCar!.model,
          'year': _selectedCar!.year,
          'plateNumber': _selectedCar!.plateNumber,
          'vin': _selectedCar!.vin,
        },
        client: {
          'id': _selectedClient!.id,
          'name': _selectedClient!.name,
          'phone': _selectedClient!.phone,
        },
        status: 'OPEN',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Navigate to session details screen with the new session
      Get.to(() => SessionDetailsScreen(session: newSession));
      Get.snackbar(
        'Success',
        'New session created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error creating session: $e');
      Get.snackbar(
        'Error',
        'Failed to create session: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<Client> get _filteredClients {
    if (_searchQuery.isEmpty) return _clients;
    return _clients.where((client) {
      return client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.phone.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom header with back button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Session',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rest of the content
              if (_selectedClient == null) ...[
                Text(
                  'Select Client',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Replacing the search bar and separate Add button with a Row containing both
                Row(
                  children: [
                    Expanded(
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        placeholder: 'Search clients by name or phone',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.person_add, size: 24),
                      onPressed: () {
                        Get.to(() => const AddClientScreen());
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: theme.primaryColor.withAlpha(25),
                        foregroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      tooltip: 'Add New Client',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredClients.isEmpty
                          ? Center(
                            child: Text(
                              'No clients found',
                              style: theme.textTheme.titleMedium,
                            ),
                          )
                          : ListView.builder(
                            itemCount: _filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = _filteredClients[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(client.name),
                                  subtitle: Text(client.phone),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () => _selectClient(client),
                                ),
                              );
                            },
                          ),
                ),
              ] else if (_selectedCar == null) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _selectedClient = null;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Select ${_selectedClient!.name}\'s Car',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        // Navigate to add car screen with client information
                        Get.to(
                          () => const AddCarScreen(),
                          arguments: {
                            'clientId': _selectedClient!.id,
                            'clientName': _selectedClient!.name,
                            'clientPhoneNumber': _selectedClient!.phone,
                          },
                        );
                      },
                      tooltip: 'Add New Car',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _cars.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No cars found for this client',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // Navigate to add car screen with client information
                                    Get.to(
                                      () => const AddCarScreen(),
                                      arguments: {
                                        'clientId': _selectedClient!.id,
                                        'clientName': _selectedClient!.name,
                                        'clientPhoneNumber':
                                            _selectedClient!.phone,
                                      },
                                    );
                                  },
                                  child: const Text('Add a Car'),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: _cars.length,
                            itemBuilder: (context, index) {
                              final car = _cars[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    '${car.make} ${car.model} (${car.year})',
                                  ),
                                  subtitle: Text('Plate: ${car.plateNumber}'),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () => _selectCar(car),
                                ),
                              );
                            },
                          ),
                ),
              ] else ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _selectedCar = null;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Confirm Session Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 8),
                            Text('Name: ${_selectedClient!.name}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16),
                            const SizedBox(width: 8),
                            Text('Phone: ${_selectedClient!.phone}'),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          'Vehicle Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.directions_car, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedCar!.make} ${_selectedCar!.model} (${_selectedCar!.year})',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.credit_card, size: 16),
                            const SizedBox(width: 8),
                            Text('Plate: ${_selectedCar!.plateNumber}'),
                          ],
                        ),
                        if (_selectedCar!.vin.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.numbers, size: 16),
                              const SizedBox(width: 8),
                              Text('VIN: ${_selectedCar!.vin}'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Create Session'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
