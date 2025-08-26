import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:attendance_tracker/services/backup_service.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

void main() {
  group('BackupService Tests', () {
    late BackupService backupService;
    late DatabaseService databaseService;

    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      backupService = BackupService();
      databaseService = DatabaseService();
      
      // Use in-memory database for testing
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: AppConstants.databaseVersion,
        onCreate: (db, version) async {
          // Create test tables (simplified version)
          await db.execute('''
            CREATE TABLE ${AppConstants.classTable} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              is_pinned INTEGER DEFAULT 0,
              pin_order INTEGER DEFAULT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE ${AppConstants.studentTable} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              class_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              roll_number TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE ${AppConstants.attendanceSessionTable} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              class_id INTEGER NOT NULL,
              date TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE ${AppConstants.attendanceRecordTable} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              session_id INTEGER NOT NULL,
              student_id INTEGER NOT NULL,
              is_present INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );
      
      DatabaseService.setDatabaseForTesting(db);
    });

    tearDown(() async {
      final db = await databaseService.database;
      await db.close();
    });

    test('should create backup with correct structure', () async {
      // Add some test data
      final now = DateTime.now().toIso8601String();
      
      // Insert test class
      final classId = await databaseService.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': now,
        'updated_at': now,
      });
      
      // Insert test student
      final studentId = await databaseService.insert(AppConstants.studentTable, {
        'class_id': classId,
        'name': 'Test Student',
        'roll_number': '001',
        'created_at': now,
        'updated_at': now,
      });
      
      // Create backup
      final backup = await backupService.createBackup();
      
      // Verify backup structure
      expect(backup, isA<Map<String, dynamic>>());
      expect(backup.containsKey('version'), isTrue);
      expect(backup.containsKey('created_at'), isTrue);
      expect(backup.containsKey('data'), isTrue);
      expect(backup.containsKey('metadata'), isTrue);
      
      final data = backup['data'] as Map<String, dynamic>;
      expect(data.containsKey('classes'), isTrue);
      expect(data.containsKey('students'), isTrue);
      expect(data.containsKey('attendance_sessions'), isTrue);
      expect(data.containsKey('attendance_records'), isTrue);
      
      // Verify data content
      final classes = data['classes'] as List;
      expect(classes.length, equals(1));
      expect(classes.first['name'], equals('Test Class'));
      
      final students = data['students'] as List;
      expect(students.length, equals(1));
      expect(students.first['name'], equals('Test Student'));
    });

    test('should get correct database stats', () async {
      // Add test data
      final now = DateTime.now().toIso8601String();
      
      await databaseService.insert(AppConstants.classTable, {
        'name': 'Class 1',
        'created_at': now,
        'updated_at': now,
      });
      
      await databaseService.insert(AppConstants.classTable, {
        'name': 'Class 2',
        'created_at': now,
        'updated_at': now,
      });
      
      // Get stats
      final stats = await backupService.getDatabaseStats();
      
      expect(stats['classes'], equals(2));
      expect(stats['students'], equals(0));
      expect(stats['sessions'], equals(0));
      expect(stats['records'], equals(0));
    });

    test('should restore backup correctly', () async {
      // Create test backup data
      final backup = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'app_version': AppConstants.databaseVersion,
        'data': {
          'classes': [
            {
              'id': 1,
              'name': 'Restored Class',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'is_pinned': 0,
              'pin_order': null,
            }
          ],
          'students': [
            {
              'id': 1,
              'class_id': 1,
              'name': 'Restored Student',
              'roll_number': '001',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }
          ],
          'attendance_sessions': [],
          'attendance_records': [],
        },
        'metadata': {
          'total_classes': 1,
          'total_students': 1,
          'total_sessions': 0,
          'total_records': 0,
        }
      };
      
      // Restore backup
      await backupService.restoreFromBackup(backup);
      
      // Verify restoration
      final classes = await databaseService.getAll(AppConstants.classTable);
      expect(classes.length, equals(1));
      expect(classes.first['name'], equals('Restored Class'));
      
      final students = await databaseService.getAll(AppConstants.studentTable);
      expect(students.length, equals(1));
      expect(students.first['name'], equals('Restored Student'));
    });
  });
}