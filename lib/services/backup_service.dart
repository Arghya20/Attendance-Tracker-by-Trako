import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/services/native_file_picker.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Creates a complete backup of all app data
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final db = await _databaseService.database;
      
      // Get all data from each table
      final classes = await db.query(AppConstants.classTable);
      final students = await db.query(AppConstants.studentTable);
      final sessions = await db.query(AppConstants.attendanceSessionTable);
      final records = await db.query(AppConstants.attendanceRecordTable);
      
      // Create backup structure
      final backup = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'app_version': AppConstants.databaseVersion,
        'data': {
          'classes': classes,
          'students': students,
          'attendance_sessions': sessions,
          'attendance_records': records,
        },
        'metadata': {
          'total_classes': classes.length,
          'total_students': students.length,
          'total_sessions': sessions.length,
          'total_records': records.length,
        }
      };
      
      return backup;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  /// Exports backup to a JSON file and saves directly to Downloads
  Future<Map<String, dynamic>> exportBackup() async {
    try {
      // Request storage permission
      await _requestStoragePermission();
      
      // Create backup data
      final backupData = await createBackup();
      
      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'attendance_backup_$timestamp.json';
      
      String? savedPath;
      
      // Try to save directly to Downloads folder (Android)
      if (Platform.isAndroid) {
        try {
          savedPath = await NativeFilePicker.saveToDownloads(fileName, jsonString);
        } catch (e) {
          debugPrint('Could not save to Downloads: $e');
        }
      }
      
      // Create temp file for sharing as fallback
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonString);
      
      return {
        'tempPath': tempFile.path,
        'savedPath': savedPath,
        'fileName': fileName,
        'fileSize': jsonString.length,
      };
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      rethrow;
    }
  }

  /// Share the backup file
  Future<void> shareBackup(String filePath, String fileName) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Attendance Tracker Backup - ${DateTime.now().toString().split('.')[0]}',
        subject: 'Attendance Tracker Backup',
      );
    } catch (e) {
      debugPrint('Error sharing backup: $e');
      rethrow;
    }
  }

  /// Validates backup file structure
  bool _validateBackupStructure(Map<String, dynamic> backup) {
    try {
      // Check required fields
      if (!backup.containsKey('version') || 
          !backup.containsKey('data') || 
          !backup.containsKey('created_at')) {
        return false;
      }
      
      final data = backup['data'] as Map<String, dynamic>?;
      if (data == null) return false;
      
      // Check required tables
      final requiredTables = [
        'classes',
        'students', 
        'attendance_sessions',
        'attendance_records'
      ];
      
      for (final table in requiredTables) {
        if (!data.containsKey(table)) return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error validating backup structure: $e');
      return false;
    }
  }

  /// Imports backup from a file path
  Future<Map<String, dynamic>> importBackupFromPath(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate backup structure
      if (!_validateBackupStructure(backup)) {
        throw Exception('Invalid backup file format');
      }
      
      return backup;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      rethrow;
    }
  }

  /// Restores data from backup
  Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      final db = await _databaseService.database;
      
      // Start transaction for data integrity
      await db.transaction((txn) async {
        // Clear existing data (in reverse order due to foreign keys)
        await txn.delete(AppConstants.attendanceRecordTable);
        await txn.delete(AppConstants.attendanceSessionTable);
        await txn.delete(AppConstants.studentTable);
        await txn.delete(AppConstants.classTable);
        
        final data = backup['data'] as Map<String, dynamic>;
        
        // Restore classes first
        final classes = data['classes'] as List<dynamic>;
        for (final classData in classes) {
          await txn.insert(
            AppConstants.classTable,
            Map<String, dynamic>.from(classData),
          );
        }
        
        // Restore students
        final students = data['students'] as List<dynamic>;
        for (final studentData in students) {
          await txn.insert(
            AppConstants.studentTable,
            Map<String, dynamic>.from(studentData),
          );
        }
        
        // Restore attendance sessions
        final sessions = data['attendance_sessions'] as List<dynamic>;
        for (final sessionData in sessions) {
          await txn.insert(
            AppConstants.attendanceSessionTable,
            Map<String, dynamic>.from(sessionData),
          );
        }
        
        // Restore attendance records
        final records = data['attendance_records'] as List<dynamic>;
        for (final recordData in records) {
          await txn.insert(
            AppConstants.attendanceRecordTable,
            Map<String, dynamic>.from(recordData),
          );
        }
      });
      
      debugPrint('Backup restored successfully');
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  /// Gets backup file info from path
  Future<Map<String, dynamic>?> getBackupInfoFromPath(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (!_validateBackupStructure(backup)) {
        throw Exception('Invalid backup file format');
      }
      
      return {
        'version': backup['version'],
        'created_at': backup['created_at'],
        'metadata': backup['metadata'],
        'file_path': file.path,
        'file_size': await file.length(),
      };
    } catch (e) {
      debugPrint('Error getting backup info: $e');
      rethrow;
    }
  }

  /// Requests storage permission for Android
  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  /// Gets current database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await _databaseService.database;
      
      final classCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.classTable}')
      ) ?? 0;
      
      final studentCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.studentTable}')
      ) ?? 0;
      
      final sessionCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.attendanceSessionTable}')
      ) ?? 0;
      
      final recordCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.attendanceRecordTable}')
      ) ?? 0;
      
      return {
        'classes': classCount,
        'students': studentCount,
        'sessions': sessionCount,
        'records': recordCount,
      };
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      return {
        'classes': 0,
        'students': 0,
        'sessions': 0,
        'records': 0,
      };
    }
  }
}