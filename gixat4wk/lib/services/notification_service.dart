import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A service for managing in-app notifications and alerts
class NotificationService {
  /// Show a snackbar notification
  static void showSnackbar({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
    Widget? icon,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: _getBackgroundColor(type),
      colorText: _getTextColor(type),
      icon: icon ?? Icon(_getIcon(type), color: _getIconColor(type)),
      duration: duration,
      snackPosition: position,
      borderRadius: 8,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      mainButton:
          actionLabel != null && onActionPressed != null
              ? TextButton(
                onPressed: onActionPressed,
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: _getIconColor(type),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
    );
  }

  /// Show a dialog notification
  static Future<T?> showDialog<T>({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) async {
    return Get.dialog<T>(
      AlertDialog(
        title: Row(
          children: [
            Icon(_getIcon(type), color: _getIconColor(type), size: 24),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (secondaryButtonText != null)
            TextButton(
              onPressed: onSecondaryPressed ?? () => Get.back(result: null),
              child: Text(
                secondaryButtonText,
                style: const TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
          if (primaryButtonText != null)
            ElevatedButton(
              onPressed: onPrimaryPressed ?? () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getActionColor(type),
              ),
              child: Text(primaryButtonText),
            ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show a confirmation dialog with yes/no options
  static Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'No',
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  destructive ? Colors.red : Get.theme.primaryColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    return result ?? false;
  }

  /// Show a bottom sheet notification
  static Future<T?> showBottomSheet<T>({
    required String title,
    required Widget content,
    bool isDismissible = true,
    bool enableDrag = true,
    ShapeBorder? shape,
  }) {
    return Get.bottomSheet<T>(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Get.theme.canvasColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(title, style: Get.textTheme.titleLarge),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
          ],
        ),
      ),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
    );
  }

  // Helper methods for consistent styling
  static Color _getBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade50;
      case NotificationType.error:
        return Colors.red.shade50;
      case NotificationType.warning:
        return Colors.amber.shade50;
      case NotificationType.info:
        return Colors.blue.shade50;
    }
  }

  static Color _getTextColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade900;
      case NotificationType.error:
        return Colors.red.shade900;
      case NotificationType.warning:
        return Colors.amber.shade900;
      case NotificationType.info:
        return Colors.blue.shade900;
    }
  }

  static IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  static Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade700;
      case NotificationType.error:
        return Colors.red.shade700;
      case NotificationType.warning:
        return Colors.amber.shade700;
      case NotificationType.info:
        return Colors.blue.shade700;
    }
  }

  static Color _getActionColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.amber;
      case NotificationType.info:
        return Colors.blue;
    }
  }
}

/// Enum for notification types
enum NotificationType { info, success, error, warning }
