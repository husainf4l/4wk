import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/car_deletion_service.dart';

class CarRestorationDialog extends StatefulWidget {
  final String carId;
  final String carDisplayName;
  final VoidCallback? onRestored;

  const CarRestorationDialog({
    super.key,
    required this.carId,
    required this.carDisplayName,
    this.onRestored,
  });

  @override
  State<CarRestorationDialog> createState() => _CarRestorationDialogState();
}

class _CarRestorationDialogState extends State<CarRestorationDialog> {
  bool _isLoading = false;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _restoreCar() async {
    if (_reasonController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please provide a reason for restoration',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Show loading dialog
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restoring car...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Perform restoration
      final success = await CarDeletionService.restoreCar(
        carId: widget.carId,
        restoredBy: 'current_user', // You should replace this with actual user ID
        reason: _reasonController.text.trim(),
      );

      // Close loading dialog
      Get.back();

      if (success) {
        // Show success message
        Get.snackbar(
          'Car Restored',
          'Car has been successfully restored to active status.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Close dialog and notify parent
        Get.back();
        widget.onRestored?.call();
      } else {
        Get.snackbar(
          'Error',
          'Failed to restore car. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'An error occurred while restoring car.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.restore_outlined,
            color: Colors.green[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Restore Car'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restore "${widget.carDisplayName}" to active status?',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Info message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Restoration Details',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The car will be restored to active status and will appear in active car listings. Sessions and job orders will need to be reviewed separately.',
                    style: TextStyle(color: Colors.green[800]),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Car Status After Restoration',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Status: Active\n• Available for new sessions\n• Visible in car listings\n• Can be assigned to service appointments',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Reason input
            Text(
              'Reason for restoration:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason for restoration...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _restoreCar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Restore Car'),
        ),
      ],
    );
  }
}