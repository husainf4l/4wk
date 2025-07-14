import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class GarageSetupScreen extends StatefulWidget {
  const GarageSetupScreen({super.key});

  @override
  State<GarageSetupScreen> createState() => _GarageSetupScreenState();
}

class _GarageSetupScreenState extends State<GarageSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _garageIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _garageIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              const Icon(Icons.garage_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Welcome to 4wk!',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please enter your garage Invitation Code to continue.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _garageIdController,
                decoration: InputDecoration(
                  labelText: 'Garage invitation Code',
                  hintText: 'Enter your garage Invitation Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a garage invitation Code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                // Update garage ID in the database
                                final success = await authController
                                    .updateGarageId(
                                      _garageIdController.text.trim(),
                                    );

                                if (success) {
                                  // If successful, the AuthWrapper will automatically
                                  // redirect to the main app due to Obx reactivity
                                } else {
                                  _showErrorSnackbar(
                                    'Failed to update garage ID',
                                  );
                                }
                              } catch (e) {
                                _showErrorSnackbar('Error: ${e.toString()}');
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          // Sign out if user cancels
                          authController.signOut();
                        },
                child: const Text('Cancel and Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}
