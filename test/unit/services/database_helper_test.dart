import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:attendance_tracker/services/database_helper.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

void main() {
  // Initialize sqflite_common_ffi for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  
  group('DatabaseHelper Pin Operations Tests', () {
    late DatabaseHelper databaseHelper;
    late Database db;
    
    setUp(() async {
      databaseHelper = DatabaseHelper();
      
      // Open an in-memory database for testing
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: AppConstants.databaseVersion,
          onCreate: (db, version) async {
            // Create test tables with pin columns
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
                updated_at TEXT NOT NULL,
                FOREIGN KEY (class_id) REFERENCES ${AppConstants.classTable} (id) ON DELETE CASCADE
              )
            ''');

            await db.execute('''
              CREATE TABLE ${AppConstants.attendanceSessionTable} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                class_id INTEGER NOT NULL,
                date TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (class_id) REFERENCES ${AppConstants.classTable} (id) ON DELETE CASCADE,
                UNIQUE(class_id, date)
              )
            ''');
            
            // Create indexes for pin functionality
            await db.execute(
              'CREATE INDEX idx_class_pinned ON ${AppConstants.classTable} (is_pinned)'
            );
            await db.execute(
              'CREATE INDEX idx_class_pin_order ON ${AppConstants.classTable} (pin_order)'
            );
          },
        ),
      );
      
      // Replace the database in the service with our test database
      DatabaseService.setDatabaseForTesting(db);
    });
    
    tearDown(() async {
      await db.close();
    });

    test('pinClass should set is_pinned to 1 and assign pin_order', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Act
      await databaseHelper.pinClass(classId, 1);
      
      // Assert
      final result = await db.query(
        AppConstants.classTable,
        where: 'id = ?',
        whereArgs: [classId],
      );
      
      expect(result.length, equals(1));
      expect(result[0]['is_pinned'], equals(1));
      expect(result[0]['pin_order'], equals(1));
    });

    test('unpinClass should set is_pinned to 0 and pin_order to null', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });
      
      // Act
      await databaseHelper.unpinClass(classId);
      
      // Assert
      final result = await db.query(
        AppConstants.classTable,
        where: 'id = ?',
        whereArgs: [classId],
      );
      
      expect(result.length, equals(1));
      expect(result[0]['is_pinned'], equals(0));
      expect(result[0]['pin_order'], isNull);
    });

    test('getNextPinOrder should return 1 for first pin', () async {
      // Act
      final nextOrder = await databaseHelper.getNextPinOrder();
      
      // Assert
      expect(nextOrder, equals(1));
    });

    test('getNextPinOrder should return correct next order when pins exist', () async {
      // Arrange
      await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class 1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });
      
      await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class 2',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 3,
      });
      
      // Act
      final nextOrder = await databaseHelper.getNextPinOrder();
      
      // Assert
      expect(nextOrder, equals(4)); // Should be max(3) + 1
    });

    test('getClassesWithStats should return classes sorted by pin status and order', () async {
      // Arrange
      final class1Id = await db.insert(AppConstants.classTable, {
        'name': 'Unpinned Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      final class2Id = await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class 2',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 2,
      });
      
      final class3Id = await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class 1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });
      
      // Act
      final result = await databaseHelper.getClassesWithStats();
      
      // Assert
      expect(result.length, equals(3));
      
      // First should be pinned class with order 1
      expect(result[0]['id'], equals(class3Id));
      expect(result[0]['name'], equals('Pinned Class 1'));
      expect(result[0]['is_pinned'], equals(1));
      expect(result[0]['pin_order'], equals(1));
      
      // Second should be pinned class with order 2
      expect(result[1]['id'], equals(class2Id));
      expect(result[1]['name'], equals('Pinned Class 2'));
      expect(result[1]['is_pinned'], equals(1));
      expect(result[1]['pin_order'], equals(2));
      
      // Third should be unpinned class
      expect(result[2]['id'], equals(class1Id));
      expect(result[2]['name'], equals('Unpinned Class'));
      expect(result[2]['is_pinned'], equals(0));
    });

    test('getClassesWithStats should include student and session counts', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Add students
      await db.insert(AppConstants.studentTable, {
        'class_id': classId,
        'name': 'Student 1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert(AppConstants.studentTable, {
        'class_id': classId,
        'name': 'Student 2',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Add session
      await db.insert(AppConstants.attendanceSessionTable, {
        'class_id': classId,
        'date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Act
      final result = await databaseHelper.getClassesWithStats();
      
      // Assert
      expect(result.length, equals(1));
      expect(result[0]['student_count'], equals(2));
      expect(result[0]['session_count'], equals(1));
    });
  });
}