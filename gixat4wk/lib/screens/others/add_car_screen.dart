import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/auth_controller.dart';
import '../../models/car.dart';
import '../../models/session.dart';
import '../../services/car_service.dart';
import '../../services/car_data_service.dart';
import '../../services/session/activity_service.dart';
import '../sessions/session_details_screen.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final CarService _carService = CarService();
  final AuthController _authController = Get.find<AuthController>();
  final CarDataService _carDataService = CarDataService();
  final ActivityService _activityService = ActivityService();

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
  String _selectedMake = ''; // Track selected make for model autocomplete
  Timer? _debounceTimer;
  List<String> _cachedMakes = [];
  final Map<String, List<String>> _cachedModels = {};

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
    _debounceTimer?.cancel();
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

      // Save make/model to Firestore for future autocomplete
      await _carDataService.addCarMakeAndModel(_make, _model);

      final result = await _carService.addCarAndCreateSession(newCar);

      if (result != null) {
        final carId = result['carId'] ?? '';
        final sessionId = result['sessionId'] ?? '';

        // Create an activity to log that the session was opened
        await _activityService.logActivity(
          sessionId: sessionId,
          title: 'Session Opened',
          type: 'session_opened',
          description:
              'Session opened for ${newCar.make} ${newCar.model} (${newCar.plateNumber})',
        );

        Get.snackbar(
          'Success',
          'Car added and session opened successfully.',
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

  Widget _buildMakeAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }

        // Debounce Firestore calls
        _debounceTimer?.cancel();
        final completer = Completer<List<String>>();

        _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
          try {
            // Use cached makes if available
            if (_cachedMakes.isEmpty) {
              _cachedMakes = await _carDataService.fetchCarMakes();
            }

            final filteredMakes = _cachedMakes.where(
              (make) => make.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
            completer.complete(filteredMakes.toList());
          } catch (e) {
            completer.complete([]);
          }
        });

        return completer.future;
      },
      onSelected: (String selection) {
        _makeController.text = selection;
        _make = selection;
        setState(() {
          _selectedMake = selection;
          // Clear model when make changes
          _modelController.clear();
          _model = '';
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Sync with our controller
        if (_makeController.text != controller.text) {
          controller.text = _makeController.text;
        }

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Make',
            hintText: 'Toyota, Honda, etc.',
            prefixIcon: const Icon(Icons.directions_car),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_modelFocus);
          },
          onChanged: (value) {
            _makeController.text = value;
            _make = value;
            setState(() {
              _selectedMake = value; // Update selected make when typing
              if (value.isEmpty) {
                // Clear model when make is cleared
                _modelController.clear();
                _model = '';
              }
            });
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
        );
      },
    );
  }

  Widget _buildModelAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty ||
            _selectedMake.isEmpty ||
            _selectedMake.length < 2) {
          return const Iterable<String>.empty();
        }

        // Debounce Firestore calls
        _debounceTimer?.cancel();
        final completer = Completer<List<String>>();

        _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
          try {
            // Use cached models if available
            if (!_cachedModels.containsKey(_selectedMake)) {
              _cachedModels[_selectedMake] = await _carDataService
                  .fetchCarModels(_selectedMake);
            }

            final models = _cachedModels[_selectedMake] ?? [];
            final filteredModels = models.where(
              (model) => model.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
            completer.complete(filteredModels.toList());
          } catch (e) {
            completer.complete([]);
          }
        });

        return completer.future;
      },
      onSelected: (String selection) {
        _modelController.text = selection;
        _model = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Sync with our controller
        if (_modelController.text != controller.text) {
          controller.text = _modelController.text;
        }

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Model',
            hintText:
                _selectedMake.isEmpty || _selectedMake.length < 2
                    ? 'Enter make first (at least 2 characters)'
                    : 'Corolla, Civic, etc.',
            prefixIcon: const Icon(Icons.car_rental),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          enabled:
              _selectedMake.isNotEmpty &&
              _selectedMake.length >=
                  2, // Enable when make has at least 2 characters
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_yearFocus);
          },
          onChanged: (value) {
            _modelController.text = value;
            _model = value;
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
        );
      },
    );
  }

  Widget _buildYearField() {
    return TextFormField(
      controller: _yearController,
      decoration: InputDecoration(
        labelText: 'Year',
        hintText: 'Enter year of manufacture',
        prefixIcon: const Icon(Icons.calendar_today),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      focusNode: _yearFocus,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onFieldSubmitted: (_) {
        FocusScope.of(context).requestFocus(_plateNumberFocus);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter year';
        }
        final yearValue = int.tryParse(value);
        if (yearValue == null) {
          return 'Please enter a valid year';
        }
        if (yearValue < 1900 || yearValue > DateTime.now().year + 1) {
          return 'Please enter a valid year between 1900 and ${DateTime.now().year + 1}';
        }
        return null;
      },
      onSaved: (value) {
        _year = int.parse(value!);
      },
    );
  }

  Widget _buildPlateNumberField() {
    return TextFormField(
      controller: _plateNumberController,
      decoration: InputDecoration(
        labelText: 'Plate Number',
        hintText: 'Enter vehicle plate number',
        prefixIcon: const Icon(Icons.credit_card),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
    );
  }

  Widget _buildVinField() {
    return TextFormField(
      controller: _vinController,
      decoration: InputDecoration(
        labelText: 'VIN (Optional)',
        hintText: 'Enter vehicle identification number',
        prefixIcon: const Icon(Icons.vpn_key),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      focusNode: _vinFocus,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.characters,
      onFieldSubmitted: (_) {
        if (!_isLoading) {
          _saveCar();
        }
      },
      onSaved: (value) {
        _vin = value != null ? value.toUpperCase() : '';
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.red[600]!, Colors.red[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCar,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'SAVE CAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
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
                      _buildMakeAutocomplete(),
                      const SizedBox(height: 16),
                      _buildModelAutocomplete(),
                      const SizedBox(height: 16),
                      _buildYearField(),
                      const SizedBox(height: 16),
                      _buildPlateNumberField(),
                      const SizedBox(height: 16),
                      _buildVinField(),
                      const SizedBox(height: 24),
                      _buildSaveButton(),
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
