import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/client.dart';
import '../../services/client_service.dart';
import '../../controllers/auth_controller.dart';
import 'add_car_screen.dart';
import '../../widgets/client_form_fields.dart';
import '../../config/me_countries.dart';

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
  String? _city;
  String? _country = 'United Arab Emirates';
  bool _isLoading = false;
  String _selectedCountry = 'United Arab Emirates';
  List<String> _citiesForSelectedCountry = [];

  String get _selectedCountryCode {
    final found = _meCountries.firstWhere(
      (c) => c['name'] == _selectedCountry,
      orElse: () => {'code': ''},
    );
    return found['code'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _updateCitiesForCountry(_selectedCountry);
    _city =
        _citiesForSelectedCountry.isNotEmpty
            ? _citiesForSelectedCountry.first
            : null;
  }

  void _updateCitiesForCountry(String country) {
    setState(() {
      _citiesForSelectedCountry = meCountryCities[country] ?? [];
      if (_citiesForSelectedCountry.isNotEmpty) {
        _city = _citiesForSelectedCountry.first;
      } else {
        _city = null;
      }
    });
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

      // Format phone number with country code for WhatsApp
      String formattedPhone = _phone;
      final countryCode = _selectedCountryCode.replaceAll(
        '+',
        '',
      ); // Remove + sign
      if (countryCode.isNotEmpty && !_phone.startsWith(countryCode)) {
        formattedPhone = countryCode + _phone;
      }

      final newClient = Client(
        id: '',
        name: _name,
        phone: formattedPhone,
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
            'clientPhoneNumber': formattedPhone,
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
    final accentColor = const Color(0xFFE82127); // Tesla-like Red

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Create New Client',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientFormFields(
                  nameFocus: _nameFocus,
                  phoneFocus: _phoneFocus,
                  cityFocus: _cityFocus,
                  countryFocus: _countryFocus,
                  phoneController: _phoneController,
                  onSavedName: (val) => _name = val!,
                  onSavedPhone: (val) => _phone = val!,
                  onSavedCity: (val) => _city = val,
                  onSavedCountry: (val) => _country = val,
                  countryList: _meCountries.map((c) => c['name']!).toList(),
                  selectedCountry: _selectedCountry,
                  onCountryChanged: (val) {
                    setState(() {
                      _selectedCountry = val;
                      _country = val;
                      _updateCitiesForCountry(val);
                    });
                  },
                  countryCode: _selectedCountryCode,
                  initialCity: _city,
                  cityList: _citiesForSelectedCountry,
                  onCityChanged: (val) {
                    setState(() {
                      _city = val;
                    });
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveClient,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                            : const Text(
                              'Save and Add Car',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
