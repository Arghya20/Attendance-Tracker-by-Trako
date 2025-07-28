import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';

/// A utility class for handling errors
class ErrorHandler {
  /// Log an error to the console
  static void logError(String tag, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('[$tag] Error: $error');
    if (stackTrace != null) {
      debugPrint('[$tag] StackTrace: $stackTrace');
    }
  }
  
  /// Show an error message to the user
  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
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
  
  /// Handle an error with logging and user feedback
  static void handleError(
    BuildContext context,
    String tag,
    dynamic error, {
    String? userMessage,
    VoidCallback? onRetry,
    StackTrace? stackTrace,
  }) {
    // Log the error
    logError(tag, error, stackTrace);
    
    // Show user feedback
    showError(
      context,
      userMessage ?? 'An error occurred: $error',
      onRetry: onRetry,
    );
  }
  
  /// Handle a future with error handling
  static Future<T?> handleFuture<T>(
    BuildContext context,
    Future<T> future,
    String tag, {
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
    VoidCallback? onRetry,
    bool showLoading = true,
    bool showSuccess = true,
  }) async {
    try {
      if (showLoading && loadingMessage != null) {
        CustomSnackBar.show(
          context: context,
          message: loadingMessage,
          type: SnackBarType.info,
        );
      }
      
      final result = await future;
      
      if (showSuccess && successMessage != null) {
        CustomSnackBar.show(
          context: context,
          message: successMessage,
          type: SnackBarType.success,
        );
      }
      
      return result;
    } catch (e, stackTrace) {
      handleError(
        context,
        tag,
        e,
        userMessage: errorMessage ?? 'An error occurred: $e',
        onRetry: onRetry,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}