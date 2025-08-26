import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeFilePicker {
  static const MethodChannel _channel = MethodChannel('native_file_picker');

  /// Pick a JSON file from the device storage
  static Future<String?> pickJsonFile() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final String? filePath = await _channel.invokeMethod('pickJsonFile');
        return filePath;
      } else {
        // For other platforms, return null to fall back to text input
        return null;
      }
    } on PlatformException catch (e) {
      debugPrint('Error picking file: ${e.message}');
      return null;
    }
  }

  /// Save content directly to Downloads folder
  static Future<String?> saveToDownloads(String fileName, String content) async {
    try {
      if (Platform.isAndroid) {
        final String? filePath = await _channel.invokeMethod('saveToDownloads', {
          'fileName': fileName,
          'content': content,
        });
        return filePath;
      } else {
        // For other platforms, return null to fall back to sharing
        return null;
      }
    } on PlatformException catch (e) {
      debugPrint('Error saving to downloads: ${e.message}');
      return null;
    }
  }

  /// Read content from a file path
  static Future<String?> readFileContent(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('Error reading file: $e');
      return null;
    }
  }
}