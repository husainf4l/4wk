import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import 'car_details_screen.dart';

class EditCarScreen extends StatefulWidget {
  final Car car;

  const EditCarScreen({super.key, required this.car});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final CarService _carService = CarService();

  // Add controllers for text fields
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _plateNumberController;
  late TextEditingController _vinController;

  // Add focus nodes for each field
  final FocusNode _makeFocus = FocusNode();
  final FocusNode _modelFocus = FocusNode();
  final FocusNode _yearFocus = FocusNode();
  final FocusNode _plateNumberFocus = FocusNode();
  final FocusNode _vinFocus = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current car data
    _makeController = TextEditingController(text: widget.car.make);
    _modelController = TextEditingController(text: widget.car.model);
    _yearController = TextEditingController(text: widget.car.year.toString());
    _plateNumberController = TextEditingController(
      text: widget.car.plateNumber,
    );
    _vinController = TextEditingController(text: widget.car.vin);
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

  Future<void> _updateCar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse values from controllers
      final int year =
          int.tryParse(_yearController.text) ?? DateTime.now().year;

      // Create updated car using copyWith
      final updatedCar = widget.car.copyWith(
        make: _makeController.text,
        model: _modelController.text,
        year: year,
        plateNumber: _plateNumberController.text,
        vin: _vinController.text,
      );

      // Update the car in Firestore
      final success = await _carService.updateCar(
        updatedCar.id,
        updatedCar.toMap(),
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Vehicle details updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Navigate directly back to car details screen
        Get.off(
          () => CarDetailsScreen(car: updatedCar),
          transition: Transition.rightToLeft,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update vehicle details',
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Vehicle',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Information Section
                        Text(
                          'Vehicle Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Make field
                        TextFormField(
                          controller: _makeController,
                          focusNode: _makeFocus,
                          decoration: const InputDecoration(
                            labelText: 'Make',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_car),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the make';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_modelFocus);
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Model field
                        TextFormField(
                          controller: _modelController,
                          focusNode: _modelFocus,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.car_repair),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the model';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_yearFocus);
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Year field
                        TextFormField(
                          controller: _yearController,
                          focusNode: _yearFocus,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the year';
                            }

                            final year = int.tryParse(value);
                            if (year == null) {
                              return 'Please enter a valid year';
                            }

                            final currentYear = DateTime.now().year;
                            if (year < 1900 || year > currentYear + 1) {
                              return 'Please enter a year between 1900 and ${currentYear + 1}';
                            }

                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_plateNumberFocus);
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Plate Number field
                        TextFormField(
                          controller: _plateNumberController,
                          focusNode: _plateNumberFocus,
                          decoration: const InputDecoration(
                            labelText: 'License Plate',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the license plate number';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_vinFocus);
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // VIN field (optional)
                        TextFormField(
                          controller: _vinController,
                          focusNode: _vinFocus,
                          decoration: const InputDecoration(
                            labelText: 'VIN (Optional)',
                            helperText: 'Vehicle Identification Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.pin),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: _updateCar,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Update Vehicle'),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
