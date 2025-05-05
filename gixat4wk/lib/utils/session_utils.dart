import 'package:flutter/material.dart';

class SessionUtils {
  /// Get color for session status
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.green;
      case 'NOTED':
        return Colors.orange;
      case 'INSPECTED':
        return Colors.purple;
      case 'TESTED':
        return Colors.blue;
      case 'JOB_ORDER':
        return Colors.teal;
      case 'REPORTED':
        return Colors.indigo;
      case 'CLOSED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Format status string for display
  static String formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'Open';
      case 'NOTED':
        return 'Noted';
      case 'INSPECTED':
        return 'Inspected';
      case 'TESTED':
        return 'Tested';
      case 'JOB_ORDER':
        return 'Job Created';
      case 'REPORTED':
        return 'Reported';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }

  /// Get appropriate icon for session status
  static IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Icons.check_circle;
      case 'NOTED':
        return Icons.note;
      case 'INSPECTED':
        return Icons.visibility;
      case 'TESTED':
        return Icons.directions_car;
      case 'PRICING':
        return Icons.attach_money;
      case 'JOB_ORDER':
        return Icons.summarize;
      case 'COMPLETED':
        return Icons.task_alt;
      case 'CLOSED':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
