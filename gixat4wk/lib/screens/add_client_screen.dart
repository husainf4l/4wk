import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../controllers/auth_controller.dart';
import '../screens/add_car_screen.dart';
import '../widgets/client_form_fields.dart';
import '../config/me_countries.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();
  final AuthController _authController = Get.find<AuthController>();

  // ME countries and codes (moved to config)
  final List<Map<String, String>> _meCountries = meCountries;

  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _countryFocus = FocusNode();

  String _name = '';
  String _phone = '';
  String? _city = 'Abu Dhabi';
  String? _country = 'United Arab Emirates';
  bool _isLoading = false;
  String _selectedCountry = 'United Arab Emirates';

  String get _selectedCountryCode {
    final found = _meCountries.firstWhere(
      (c) => c['name'] == _selectedCountry,
      orElse: () => {'code': ''},
    );
    return found['code'] ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _cityFocus.dispose();
    _countryFocus.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
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
        id: '',
        name: _name,
        phone: _phone,
        address: Address(city: _city, country: _country),
        garageId: garageId,
      );
      final clientId = await _clientService.addClient(newClient);
      if (clientId != null) {
        Get.snackbar(
          'Success',
          'Client added successfully. Now add their car.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        Get.to(
          () => const AddCarScreen(),
          arguments: {
            'clientId': clientId,
            'clientName': _name,
            'clientPhoneNumber': _phone,
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
      setState(() => _isLoading = false);
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
                  child: ClientFormFields(
                    nameFocus: _nameFocus,
                    phoneFocus: _phoneFocus,
                    cityFocus: _cityFocus,
                    countryFocus: _countryFocus,
                    phoneController: _phoneController,
                    isLoading: _isLoading,
                    onSavedName: (val) => _name = val!,
                    onSavedPhone: (val) => _phone = val!,
                    onSavedCity: (val) => _city = val,
                    onSavedCountry: (val) => _country = val,
                    onSubmit: _saveClient,
                    countryList: _meCountries.map((c) => c['name']!).toList(),
                    selectedCountry: _selectedCountry,
                    onCountryChanged: (val) {
                      setState(() {
                        _selectedCountry = val;
                        _country = val;
                        if (val == 'United Arab Emirates' &&
                            (_city == null || _city!.isEmpty)) {
                          _city = 'Abu Dhabi';
                        }
                      });
                    },
                    countryCode: _selectedCountryCode,
                    initialCity: _city,
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
