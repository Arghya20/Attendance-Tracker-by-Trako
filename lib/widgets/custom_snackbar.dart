import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade800;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        backgroundColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange.shade800;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        icon = Icons.info;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}