import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final VoidCallback onConfirm;
  final Color? confirmColor;
  final IconData? icon;
  
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.cancelText = 'Cancel',
    this.confirmText = 'Confirm',
    required this.onConfirm,
    this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: confirmColor ?? theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
          ],
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}