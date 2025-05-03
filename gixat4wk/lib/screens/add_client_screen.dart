import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../controllers/auth_controller.dart';
// Add import for the AddCarScreen
import '../screens/add_car_screen.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();
  final AuthController _authController = Get.find<AuthController>();

  // Add controllers for text fields
  final TextEditingController _phoneController = TextEditingController();

  // Add focus nodes for each field
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _countryFocus = FocusNode();

  String _name = '';
  String _phone = '';
  String? _city;
  String? _country;
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose of controllers
    _phoneController.dispose();

    // Dispose of focus nodes when the screen is disposed
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _cityFocus.dispose();
    _countryFocus.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the garage ID from the app user model, not the Firebase user
      final garageId = _authController.currentUser?.garageId ?? '';
      if (garageId.isEmpty) {
        Get.snackbar(
          'Error',
          'No garage ID found. Please check your account settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final newClient = Client(
        id: '', // Will be set by Firestore
        name: _name,
        phone: _phone,
        address: Address(city: _city, country: _country),
        garageId: garageId,
      );

      final clientId = await _clientService.addClient(newClient);

      if (clientId != null) {
        // Instead of going back, navigate to Add Car screen with the client ID
        Get.snackbar(
          'Success',
          'Client added successfully. Now add their car.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Use Get.to() with arguments instead of constructor parameters
        Get.to(
          () => const AddCarScreen(),
          arguments: {
            'clientId': clientId,
            'clientName': _name,
            'clientPhoneNumber': _phone, // Added client phone number
          },
          transition: Transition.rightToLeft,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to add client',
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
                  Text(
                    'Add Client',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        focusNode: _nameFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_phoneFocus);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _name = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          hintText: 'Enter phone number',
                        ),
                        focusNode: _phoneFocus,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          if (value.length < 6) {
                            return 'Phone number is too short';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _phone = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'City (Optional)',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                        ),
                        focusNode: _cityFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_countryFocus);
                        },
                        onSaved: (value) {
                          _city = value;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Country (Optional)',
                          prefixIcon: Icon(Icons.flag),
                          border: OutlineInputBorder(),
                        ),
                        focusNode: _countryFocus,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          // Submit the form when done is pressed on the last field
                          if (!_isLoading) {
                            _saveClient();
                          }
                        },
                        onSaved: (value) {
                          _country = value;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveClient,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('SAVE CLIENT'),
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
