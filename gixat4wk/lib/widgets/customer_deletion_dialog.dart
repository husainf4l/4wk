import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/customer_deletion_service.dart';

class CustomerDeletionDialog extends StatefulWidget {
  final String customerId;
  final String customerName;
  final VoidCallback? onDeleted;

  const CustomerDeletionDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    this.onDeleted,
  });

  @override
  State<CustomerDeletionDialog> createState() => _CustomerDeletionDialogState();
}

class _CustomerDeletionDialogState extends State<CustomerDeletionDialog> {
  bool _isLoading = false;
  bool _confirmationChecked = false;
  Map<String, dynamic>? _customerInfo;
  final TextEditingController _reasonController = TextEditingController();
  CustomerStatus _selectedStatus = CustomerStatus.deleted;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await CustomerDeletionService.getCustomerDeletionInfo(widget.customerId);
      setState(() => _customerInfo = info);
    } catch (e) {
      debugPrint('Error loading customer info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCustomer() async {
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
                  Text('Updating customer status...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Perform soft deletion
      final success = await CustomerDeletionService.softDeleteCustomer(
        customerId: widget.customerId,
        deletedBy: 'current_user', // You should replace this with actual user ID
        reason: _reasonController.text.trim(),
        status: _selectedStatus,
      );

      // Close loading dialog
      Get.back();

      if (success) {
        // Show success message
        final statusName = CustomerDeletionService.getStatusDisplayName(_selectedStatus);
        Get.snackbar(
          'Customer Updated',
          'Customer status changed to $statusName successfully.',
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
          'Failed to update customer status. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'An error occurred while updating customer status.',
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
            Icons.person_remove_outlined,
            color: Colors.orange[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Update Customer Status'),
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
                'Change status for "${widget.customerName}"?',
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
              
              _buildStatusOption(CustomerStatus.deleted, 'Deleted', 
                'Customer will be hidden from active lists', Colors.red),
              _buildStatusOption(CustomerStatus.inactive, 'Inactive', 
                'Customer will be marked as inactive', Colors.orange),
              _buildStatusOption(CustomerStatus.suspended, 'Suspended', 
                'Customer will be temporarily suspended', Colors.purple),
              
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
              
              // Customer info and related data
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_customerInfo != null)
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
                      _buildDataCountItem('Vehicles', _customerInfo!['relatedData']['cars']),
                      _buildDataCountItem('Sessions', _customerInfo!['relatedData']['sessions']),
                      _buildDataCountItem('Job Orders', _customerInfo!['relatedData']['jobOrders']),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Warning message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Important',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is a soft delete - the customer data will be preserved but marked as ${_selectedStatus.name}. You can restore the customer later if needed.',
                      style: TextStyle(color: Colors.orange[800]),
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
                        'I understand the consequences and want to change this customer\'s status.',
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
              : _deleteCustomer,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getStatusColor(_selectedStatus),
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
              : Text('Update Status'),
        ),
      ],
    );
  }

  Widget _buildStatusOption(CustomerStatus status, String title, String description, Color color) {
    return RadioListTile<CustomerStatus>(
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

  Color _getStatusColor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.deleted:
        return Colors.red;
      case CustomerStatus.inactive:
        return Colors.orange;
      case CustomerStatus.suspended:
        return Colors.purple;
      case CustomerStatus.active:
        return Colors.green;
    }
  }
}