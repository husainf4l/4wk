import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/car_deletion_service.dart';

class CarDeletionDialog extends StatefulWidget {
  final String carId;
  final String carDisplayName;
  final VoidCallback? onDeleted;

  const CarDeletionDialog({
    super.key,
    required this.carId,
    required this.carDisplayName,
    this.onDeleted,
  });

  @override
  State<CarDeletionDialog> createState() => _CarDeletionDialogState();
}

class _CarDeletionDialogState extends State<CarDeletionDialog> {
  bool _isLoading = false;
  bool _confirmationChecked = false;
  Map<String, dynamic>? _carInfo;
  final TextEditingController _reasonController = TextEditingController();
  CarStatus _selectedStatus = CarStatus.deleted;

  @override
  void initState() {
    super.initState();
    _loadCarInfo();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCarInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await CarDeletionService.getCarDeletionInfo(widget.carId);
      setState(() => _carInfo = info);
    } catch (e) {
      debugPrint('Error loading car info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCarStatus() async {
    if (!_confirmationChecked || _reasonController.text.trim().isEmpty) return;

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
                  Text('Updating car status...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Perform status update
      final success = await CarDeletionService.softDeleteCar(
        carId: widget.carId,
        deletedBy: 'current_user', // You should replace this with actual user ID
        reason: _reasonController.text.trim(),
        status: _selectedStatus,
      );

      // Close loading dialog
      Get.back();

      if (success) {
        // Show success message
        final statusName = CarDeletionService.getStatusDisplayName(_selectedStatus);
        Get.snackbar(
          'Car Updated',
          'Car status changed to $statusName successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Close dialog and notify parent
        Get.back();
        widget.onDeleted?.call();
      } else {
        Get.snackbar(
          'Error',
          'Failed to update car status. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'An error occurred while updating car status.',
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
            Icons.directions_car_outlined,
            color: Colors.orange[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Update Car Status'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change status for "${widget.carDisplayName}"?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Status Selection
              Text(
                'Select new status:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildStatusOption(CarStatus.deleted, 'Deleted', 
                CarDeletionService.getStatusDescription(CarStatus.deleted)),
              _buildStatusOption(CarStatus.inactive, 'Inactive', 
                CarDeletionService.getStatusDescription(CarStatus.inactive)),
              _buildStatusOption(CarStatus.suspended, 'Suspended', 
                CarDeletionService.getStatusDescription(CarStatus.suspended)),
              _buildStatusOption(CarStatus.sold, 'Sold', 
                CarDeletionService.getStatusDescription(CarStatus.sold)),
              _buildStatusOption(CarStatus.totaled, 'Totaled', 
                CarDeletionService.getStatusDescription(CarStatus.totaled)),
              
              const SizedBox(height: 16),
              
              // Reason input
              Text(
                'Reason for status change:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: 'Enter reason for status change...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              // Car info and related data
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_carInfo != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Related data that will be affected:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDataCountItem('Sessions', _carInfo!['relatedData']['sessions']),
                      _buildDataCountItem('Job Orders', _carInfo!['relatedData']['jobOrders']),
                      _buildDataCountItem('Activities', _carInfo!['relatedData']['activities']),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Warning message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CarDeletionService.getStatusColor(_selectedStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CarDeletionService.getStatusColor(_selectedStatus).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: CarDeletionService.getStatusColor(_selectedStatus),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Important',
                          style: TextStyle(
                            color: CarDeletionService.getStatusColor(_selectedStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is a soft delete - the car data will be preserved but marked as ${CarDeletionService.getStatusDisplayName(_selectedStatus)}. You can restore the car later if needed.',
                      style: TextStyle(color: CarDeletionService.getStatusColor(_selectedStatus).withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Confirmation checkbox
              Row(
                children: [
                  Checkbox(
                    value: _confirmationChecked,
                    onChanged: (value) {
                      setState(() => _confirmationChecked = value ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _confirmationChecked = !_confirmationChecked);
                      },
                      child: Text(
                        'I understand the consequences and want to change this car\'s status.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          onPressed: _isLoading || !_confirmationChecked || _reasonController.text.trim().isEmpty
              ? null
              : _updateCarStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: CarDeletionService.getStatusColor(_selectedStatus),
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
              : const Text('Update Status'),
        ),
      ],
    );
  }

  Widget _buildStatusOption(CarStatus status, String title, String description) {
    final color = CarDeletionService.getStatusColor(status);
    
    return RadioListTile<CarStatus>(
      value: status,
      groupValue: _selectedStatus,
      onChanged: (value) {
        setState(() => _selectedStatus = value!);
      },
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: color.withValues(alpha: 0.8),
        ),
      ),
      activeColor: color,
    );
  }

  Widget _buildDataCountItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}