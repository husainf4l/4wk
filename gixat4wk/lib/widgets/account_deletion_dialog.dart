import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/data_deletion_service.dart';

class AccountDeletionDialog extends StatefulWidget {
  final String userId;
  final String? userEmail;

  const AccountDeletionDialog({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  bool _isLoading = false;
  bool _confirmationChecked = false;
  Map<String, int> _dataSummary = {};

  @override
  void initState() {
    super.initState();
    _loadDataSummary();
  }

  Future<void> _loadDataSummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await DataDeletionService.getUserDataSummary(widget.userId);
      setState(() => _dataSummary = summary);
    } catch (e) {
      debugPrint('Error loading data summary: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (!_confirmationChecked) return;

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
                  Text('Deleting your account...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Perform data deletion
      final success = await DataDeletionService.deleteAllUserData(
        userId: widget.userId,
        anonymizeInsteadOfDelete: true,
      );

      // Close loading dialog
      Get.back();

      if (success) {
        // Show success message
        Get.snackbar(
          'Account Deleted',
          'Your account and all personal data have been successfully deleted.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Close deletion dialog
        Get.back();
        
        // Navigate to login or exit app
        // The auth controller will handle the navigation automatically
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete account. Please try again or contact support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'An error occurred while deleting your account. Please try again.',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Delete Account'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete your account?',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Warning message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'This action cannot be undone',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleting your account will permanently remove all your personal information from our servers. This includes:',
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Data summary
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_dataSummary.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data to be deleted:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DataDeletionService.getDataSummaryText(_dataSummary),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Privacy note
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
                        Icons.privacy_tip_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy Compliance',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personal information will be anonymized in business records to maintain system integrity while ensuring your privacy is protected.',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
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
                      'I understand that this action cannot be undone and I want to permanently delete my account.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
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
          onPressed: _isLoading || !_confirmationChecked ? null : _deleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              : const Text('Delete Account'),
        ),
      ],
    );
  }
}