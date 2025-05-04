import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../models/car.dart';
import '../models/session.dart';
import '../services/car_service.dart';
import '../screens/sessions/session_details_screen.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final CarService _carService = CarService();
  final AuthController _authController = Get.find<AuthController>();

  // Add controllers for text fields
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();

  // Add focus nodes for each field
  final FocusNode _makeFocus = FocusNode();
  final FocusNode _modelFocus = FocusNode();
  final FocusNode _yearFocus = FocusNode();
  final FocusNode _plateNumberFocus = FocusNode();
  final FocusNode _vinFocus = FocusNode();

  String _make = '';
  String _model = '';
  int _year = DateTime.now().year;
  String _plateNumber = '';
  String _vin = '';
  bool _isLoading = false;

  // Client data passed from previous screen
  late String _clientId;
  String? _clientName;

  @override
  void initState() {
    super.initState();
    // Get the arguments passed from the Add Client screen
    final Map<String, dynamic> args = Get.arguments ?? {};
    _clientId = args['clientId'] ?? '';
    _clientName = args['clientName'];

    if (_clientId.isEmpty) {
      // Handle the case when no client ID is provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Error',
          'No client information provided',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back(); // Go back if no client ID
      });
    }
  }

  @override
  void dispose() {
    // Dispose of controllers
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateNumberController.dispose();
    _vinController.dispose();

    // Dispose of focus nodes
    _makeFocus.dispose();
    _modelFocus.dispose();
    _yearFocus.dispose();
    _plateNumberFocus.dispose();
    _vinFocus.dispose();

    super.dispose();
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> args =
          Get.arguments ?? {}; // Ensure args is accessible
      final newCar = Car(
        id: '', // Will be set by Firestore
        make: _make,
        model: _model,
        year: _year,
        plateNumber: _plateNumber,
        vin: _vin,
        clientId: _clientId,
        clientName: _clientName ?? 'Unknown', // Added client name
        clientPhoneNumber:
            args['clientPhoneNumber'] ?? 'Unknown', // Added client phone number
        garageId: _authController.currentUser?.garageId ?? '',
      );

      final result = await _carService.addCarAndCreateSession(newCar);

      if (result != null) {
        final carId = result['carId'] ?? '';
        final sessionId = result['sessionId'] ?? '';

        Get.snackbar(
          'Success',
          'Car added successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Create a session object for navigation
        final car = {
          'id': carId,
          'make': _make,
          'model': _model,
          'year': _year,
          'plateNumber': _plateNumber,
          'vin': _vin,
        };

        final client = {
          'id': _clientId,
          'name': _clientName ?? 'Unknown',
          'phoneNumber': args['clientPhoneNumber'] ?? 'Unknown',
        };

        final session = Session(
          id: sessionId,
          clientId: _clientId, // Add client ID
          car: car,
          client: client,
          garageId: _authController.currentUser?.garageId ?? '',
          status: 'OPEN',
          clientNoteId: null,
        );

        // Navigate to session details screen using GetX instead of Navigator
        Get.off(() => SessionDetailsScreen(session: session));
      } else {
        Get.snackbar(
          'Error',
          'Failed to add car',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Car',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_clientName != null && _clientName!.isNotEmpty)
                          Text(
                            'for $_clientName',
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _makeController,
                        decoration: const InputDecoration(
                          labelText: 'Make',
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                          hintText: 'Toyota, Honda, etc.',
                        ),
                        focusNode: _makeFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_modelFocus);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter car make';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _make = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          prefixIcon: Icon(Icons.car_rental),
                          border: OutlineInputBorder(),
                          hintText: 'Corolla, Civic, etc.',
                        ),
                        focusNode: _modelFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_yearFocus);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter car model';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _model = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                          hintText: 'Enter year of manufacture',
                        ),
                        focusNode: _yearFocus,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onFieldSubmitted: (_) {
                          FocusScope.of(
                            context,
                          ).requestFocus(_plateNumberFocus);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter year';
                          }
                          final yearValue = int.tryParse(value);
                          if (yearValue == null) {
                            return 'Please enter a valid year';
                          }
                          if (yearValue < 1900 ||
                              yearValue > DateTime.now().year + 1) {
                            return 'Please enter a valid year between 1900 and ${DateTime.now().year + 1}';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _year = int.parse(value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _plateNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Plate Number',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                          hintText: 'Enter vehicle plate number',
                        ),
                        focusNode: _plateNumberFocus,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.characters,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_vinFocus);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter plate number';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _plateNumber = value!.toUpperCase();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vinController,
                        decoration: const InputDecoration(
                          labelText: 'VIN (Optional)',
                          prefixIcon: Icon(Icons.vpn_key),
                          border: OutlineInputBorder(),
                          hintText: 'Enter vehicle identification number',
                        ),
                        focusNode: _vinFocus,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.characters,
                        onFieldSubmitted: (_) {
                          // Submit the form when done is pressed on the last field
                          if (!_isLoading) {
                            _saveCar();
                          }
                        },
                        onSaved: (value) {
                          _vin = value != null ? value.toUpperCase() : '';
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveCar,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('SAVE CAR'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
