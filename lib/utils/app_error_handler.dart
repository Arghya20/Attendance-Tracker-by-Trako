import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';

/// A global error handler for the app
class AppErrorHandler {
  /// Initialize the error handler
  static void initialize() {
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error
      FlutterError.presentError(details);
      
      // Report to error reporting service if in release mode
      if (kReleaseMode) {
        // TODO: Report to error reporting service
      }
    };
    
    // Set up Dart error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      // Log the error
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
      
      // Report to error reporting service if in release mode
      if (kReleaseMode) {
        // TODO: Report to error reporting service
      }
      
      // Return true to prevent the error from being propagated
      return true;
    };
  }
  
  /// Show an error dialog
  static void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
  
  /// Show an error snackbar
  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    CustomSnackBar.show(
      context: context,
      message: message,
      type: SnackBarType.error,
      action: onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              onPressed: onRetry,
              textColor: Colors.white,
            )
          : null,
    );
  }
  
  /// Run a function with error handling
  static Future<T?> run<T>(
    BuildContext context,
    Future<T> Function() function, {
    String? errorMessage,
    VoidCallback? onRetry,
  }) async {
    try {
      return await function();
    } catch (e, stackTrace) {
      // Log the error
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Show error message
      if (context.mounted) {
        showErrorSnackbar(
          context,
          errorMessage ?? 'An error occurred: $e',
          onRetry: onRetry,
        );
      }
      
      return null;
    }
  }
}