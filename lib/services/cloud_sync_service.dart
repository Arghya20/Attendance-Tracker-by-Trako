import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/user_model.dart';

/// Service for syncing local SQLite data with Firebase Firestore
/// Data is synced based on user's login method (phone or email)
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription? _syncSubscription;
  UserModel? _currentUser;
  Timer? _debounceTimer;
  
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Get the user's cloud storage path based on their login method
  String _getUserStoragePath(UserModel user) {
    // Use phone number if available, otherwise use email, fallback to uid
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      // Sanitize phone number for Firestore path
      return 'users_by_phone/${_sanitizeForFirestore(user.phoneNumber!)}';
    } else if (user.email != null && user.email!.isNotEmpty) {
      return 'users_by_email/${_sanitizeForFirestore(user.email!)}';
    } else {
      return 'users_by_uid/${user.uid}';
    }
  }

  /// Sanitize string for use in Firestore document path
  String _sanitizeForFirestore(String input) {
    // Remove special characters that aren't allowed in Firestore paths
    return input.replaceAll(RegExp(r'[\/\.\$\#\[\]]'), '_');
  }

  /// Upload local data to cloud
  Future<void> uploadToCloud(UserModel user) async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping...');
      return;
    }

    try {
      _isSyncing = true;
      debugPrint('Starting cloud upload for user: ${user.uid}');

      final userPath = _getUserStoragePath(user);
      final userDoc = _firestore.doc(userPath);

      // Get all local data
      final db = await _databaseService.database;
      final classes = await db.query(AppConstants.classTable);
      final students = await db.query(AppConstants.studentTable);
      final sessions = await db.query(AppConstants.attendanceSessionTable);
      final records = await db.query(AppConstants.attendanceRecordTable);

      // Create backup structure
      final backupData = {
        'user_id': user.uid,
        'phone_number': user.phoneNumber,
        'email': user.email,
        'last_sync': FieldValue.serverTimestamp(),
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

      // Upload to Firestore
      await userDoc.set(backupData, SetOptions(merge: true));
      
      _lastSyncTime = DateTime.now();
      debugPrint('Cloud upload completed successfully');
    } catch (e) {
      debugPrint('Error uploading to cloud: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Download data from cloud and restore to local database
  Future<bool> downloadFromCloud(UserModel user) async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping...');
      return false;
    }

    try {
      _isSyncing = true;
      debugPrint('Starting cloud download for user: ${user.uid}');

      final userPath = _getUserStoragePath(user);
      final userDoc = await _firestore.doc(userPath).get();

      if (!userDoc.exists) {
        debugPrint('No cloud data found for user');
        return false;
      }

      final cloudData = userDoc.data() as Map<String, dynamic>;
      
      // Validate data structure
      if (!cloudData.containsKey('data')) {
        debugPrint('Invalid cloud data structure');
        return false;
      }

      final data = cloudData['data'] as Map<String, dynamic>;
      
      // Restore data to local database
      await _restoreToLocalDatabase(data);
      
      _lastSyncTime = DateTime.now();
      debugPrint('Cloud download completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error downloading from cloud: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Restore data to local SQLite database
  Future<void> _restoreToLocalDatabase(Map<String, dynamic> data) async {
    try {
      final db = await _databaseService.database;
      
      // Start transaction for data integrity
      await db.transaction((txn) async {
        // Clear existing data (in reverse order due to foreign keys)
        await txn.delete(AppConstants.attendanceRecordTable);
        await txn.delete(AppConstants.attendanceSessionTable);
        await txn.delete(AppConstants.studentTable);
        await txn.delete(AppConstants.classTable);
        
        // Restore classes
        final classes = data['classes'] as List<dynamic>?;
        if (classes != null) {
          for (final classData in classes) {
            await txn.insert(
              AppConstants.classTable,
              Map<String, dynamic>.from(classData),
            );
          }
        }
        
        // Restore students
        final students = data['students'] as List<dynamic>?;
        if (students != null) {
          for (final studentData in students) {
            await txn.insert(
              AppConstants.studentTable,
              Map<String, dynamic>.from(studentData),
            );
          }
        }
        
        // Restore attendance sessions
        final sessions = data['attendance_sessions'] as List<dynamic>?;
        if (sessions != null) {
          for (final sessionData in sessions) {
            await txn.insert(
              AppConstants.attendanceSessionTable,
              Map<String, dynamic>.from(sessionData),
            );
          }
        }
        
        // Restore attendance records
        final records = data['attendance_records'] as List<dynamic>?;
        if (records != null) {
          for (final recordData in records) {
            await txn.insert(
              AppConstants.attendanceRecordTable,
              Map<String, dynamic>.from(recordData),
            );
          }
        }
      });
      
      debugPrint('Data restored to local database successfully');
    } catch (e) {
      debugPrint('Error restoring to local database: $e');
      rethrow;
    }
  }

  /// Check if cloud data exists for user
  Future<bool> hasCloudData(UserModel user) async {
    try {
      final userPath = _getUserStoragePath(user);
      final userDoc = await _firestore.doc(userPath).get();
      return userDoc.exists;
    } catch (e) {
      debugPrint('Error checking cloud data: $e');
      return false;
    }
  }

  /// Get cloud data metadata without downloading full data
  Future<Map<String, dynamic>?> getCloudDataMetadata(UserModel user) async {
    try {
      final userPath = _getUserStoragePath(user);
      final userDoc = await _firestore.doc(userPath).get();
      
      if (!userDoc.exists) return null;
      
      final data = userDoc.data() as Map<String, dynamic>;
      return {
        'last_sync': data['last_sync'],
        'metadata': data['metadata'],
        'app_version': data['app_version'],
      };
    } catch (e) {
      debugPrint('Error getting cloud metadata: $e');
      return null;
    }
  }

  /// Sync local data with cloud (upload)
  Future<void> syncToCloud(UserModel user) async {
    await uploadToCloud(user);
  }

  /// Auto-sync: Check if local data is empty and restore from cloud if available
  Future<bool> autoRestoreOnLogin(UserModel user) async {
    try {
      debugPrint('Checking for auto-restore on login...');
      
      // Check if local database is empty
      final stats = await _databaseService.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.classTable}'
      );
      final localClassCount = stats.first['count'] as int;
      
      if (localClassCount > 0) {
        debugPrint('Local data exists ($localClassCount classes), skipping auto-restore');
        // Don't sync here - data will be synced by periodic sync or after changes
        // Syncing here could overwrite cloud data with wrong user's data
        return false;
      }
      
      // Local database is empty, check if cloud data exists
      final hasCloud = await hasCloudData(user);
      if (!hasCloud) {
        debugPrint('No cloud data available for restore');
        return false;
      }
      
      // Restore from cloud
      debugPrint('Local database is empty, restoring from cloud...');
      await downloadFromCloud(user);
      return true;
    } catch (e) {
      debugPrint('Error in auto-restore: $e');
      return false;
    }
  }

  /// Set current user for automatic sync
  void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  /// Trigger sync after data change (with debouncing)
  /// This prevents multiple rapid syncs when user makes several changes quickly
  void syncAfterDataChange() {
    if (_currentUser == null) {
      debugPrint('No user set, skipping sync');
      return;
    }

    // Cancel previous timer if exists
    _debounceTimer?.cancel();
    
    // Set new timer - sync after 2 seconds of no changes
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      try {
        debugPrint('Syncing after data change...');
        await syncToCloud(_currentUser!);
      } catch (e) {
        debugPrint('Error syncing after data change: $e');
      }
    });
  }

  /// Enable automatic periodic sync (backup - syncs every 5 minutes as fallback)
  void enableAutoSync(UserModel user, {Duration interval = const Duration(minutes: 5)}) {
    _currentUser = user;
    _syncSubscription?.cancel();
    
    _syncSubscription = Stream.periodic(interval).listen((_) async {
      try {
        await syncToCloud(user);
      } catch (e) {
        debugPrint('Auto-sync error: $e');
      }
    });
    
    debugPrint('Periodic sync enabled with interval: ${interval.inMinutes} minutes (as backup)');
  }

  /// Disable automatic sync
  void disableAutoSync() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _currentUser = null;
    debugPrint('Auto-sync disabled');
  }

  /// Delete cloud data for user
  Future<void> deleteCloudData(UserModel user) async {
    try {
      final userPath = _getUserStoragePath(user);
      await _firestore.doc(userPath).delete();
      debugPrint('Cloud data deleted for user');
    } catch (e) {
      debugPrint('Error deleting cloud data: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    disableAutoSync();
  }
}
