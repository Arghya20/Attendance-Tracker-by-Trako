import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:attendance_tracker/repositories/class_repository.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

void main() {
  // Initialize sqflite_common_ffi for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  
  group('ClassRepository Pin Operations Integration Tests', () {
    late ClassRepository repository;
    late Database db;
    
    setUp(() async {
      repository = ClassRepository();
      
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

    test('pinClass should successfully pin a class', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Act
      final result = await repository.pinClass(classId);
      
      // Assert
      expect(result, isTrue);
      
      final classData = await db.query(
        AppConstants.classTable,
        where: 'id = ?',
        whereArgs: [classId],
      );
      
      expect(classData.length, equals(1));
      expect(classData[0]['is_pinned'], equals(1));
      expect(classData[0]['pin_order'], equals(1));
    });

    test('unpinClass should successfully unpin a class', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });
      
      // Act
      final result = await repository.unpinClass(classId);
      
      // Assert
      expect(result, isTrue);
      
      final classData = await db.query(
        AppConstants.classTable,
        where: 'id = ?',
        whereArgs: [classId],
      );
      
      expect(classData.length, equals(1));
      expect(classData[0]['is_pinned'], equals(0));
      expect(classData[0]['pin_order'], isNull);
    });

    test('togglePinStatus should pin unpinned class', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Act
      final result = await repository.togglePinStatus(classId);
      
      // Assert
      expect(result, isTrue);
      
      final classData = await db.query(
        AppConstants.classTable,
        where: 'id = ?',
        whereArgs: [classId],
      );
      
      expect(classData.length, equals(1));
      expect(classData[0]['is_pinned'], equals(1));
      expect(classData[0]['pin_order'], equals(1));
    });

    test('togglePinStatus should unpin pinned class', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });
      
      // Act
      final result = await repository.togglePinStatus(classId);
      
      // Assert
      expect(result, isTrue);
      
      final classData = await db.query(
        AppConstants.classTable,
        where: 'id = ?',
        whereArgs: [classId],
      );
      
      expect(classData.length, equals(1));
      expect(classData[0]['is_pinned'], equals(0));
      expect(classData[0]['pin_order'], isNull);
    });

    test('getAllClasses should return classes sorted by pin status', () async {
      // Arrange
      final class1Id = await db.insert(AppConstants.classTable, {
        'name': 'Unpinned Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      final class2Id = await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });
      
      // Act
      final classes = await repository.getAllClasses();
      
      // Assert
      expect(classes.length, equals(2));
      
      // Pinned class should come first
      expect(classes[0].id, equals(class2Id));
      expect(classes[0].name, equals('Pinned Class'));
      expect(classes[0].isPinned, isTrue);
      expect(classes[0].pinOrder, equals(1));
      
      // Unpinned class should come second
      expect(classes[1].id, equals(class1Id));
      expect(classes[1].name, equals('Unpinned Class'));
      expect(classes[1].isPinned, isFalse);
      expect(classes[1].pinOrder, isNull);
    });

    test('multiple pinned classes should be ordered by pin_order', () async {
      // Arrange
      final class1Id = await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class 2',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 2,
      });
      
      final class2Id = await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class 1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });
      
      // Act
      final classes = await repository.getAllClasses();
      
      // Assert
      expect(classes.length, equals(2));
      
      // Class with pin_order 1 should come first
      expect(classes[0].id, equals(class2Id));
      expect(classes[0].pinOrder, equals(1));
      
      // Class with pin_order 2 should come second
      expect(classes[1].id, equals(class1Id));
      expect(classes[1].pinOrder, equals(2));
    });
  });
}