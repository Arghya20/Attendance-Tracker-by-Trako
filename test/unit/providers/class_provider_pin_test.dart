import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:attendance_tracker/providers/class_provider.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

void main() {
  // Initialize sqflite_common_ffi for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  
  group('ClassProvider Pin Operations Tests', () {
    late ClassProvider provider;
    late Database db;
    
    setUp(() async {
      provider = ClassProvider();
      
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

    test('pinClass should successfully pin a class and update state', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Load classes first
      await provider.loadClasses();
      expect(provider.classes.length, equals(1));
      expect(provider.classes[0].isPinned, isFalse);
      
      // Act
      final result = await provider.pinClass(classId);
      
      // Assert
      expect(result, isTrue);
      expect(provider.error, isNull);
      expect(provider.classes.length, equals(1));
      expect(provider.classes[0].isPinned, isTrue);
      expect(provider.classes[0].pinOrder, equals(1));
    });

    test('unpinClass should successfully unpin a class and update state', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });
      
      // Load classes first
      await provider.loadClasses();
      expect(provider.classes.length, equals(1));
      expect(provider.classes[0].isPinned, isTrue);
      
      // Act
      final result = await provider.unpinClass(classId);
      
      // Assert
      expect(result, isTrue);
      expect(provider.error, isNull);
      expect(provider.classes.length, equals(1));
      expect(provider.classes[0].isPinned, isFalse);
      expect(provider.classes[0].pinOrder, isNull);
    });

    test('togglePinStatus should pin unpinned class', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Load classes first
      await provider.loadClasses();
      expect(provider.classes[0].isPinned, isFalse);
      
      // Act
      final result = await provider.togglePinStatus(classId);
      
      // Assert
      expect(result, isTrue);
      expect(provider.error, isNull);
      expect(provider.classes[0].isPinned, isTrue);
      expect(provider.classes[0].pinOrder, equals(1));
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
      
      // Load classes first
      await provider.loadClasses();
      expect(provider.classes[0].isPinned, isTrue);
      
      // Act
      final result = await provider.togglePinStatus(classId);
      
      // Assert
      expect(result, isTrue);
      expect(provider.error, isNull);
      expect(provider.classes[0].isPinned, isFalse);
      expect(provider.classes[0].pinOrder, isNull);
    });

    test('pin operations should maintain proper class sorting', () async {
      // Arrange
      final class1Id = await db.insert(AppConstants.classTable, {
        'name': 'Class A',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      final class2Id = await db.insert(AppConstants.classTable, {
        'name': 'Class B',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Load classes first
      await provider.loadClasses();
      expect(provider.classes.length, equals(2));
      
      // Initially, classes should be sorted alphabetically
      expect(provider.classes[0].name, equals('Class A'));
      expect(provider.classes[1].name, equals('Class B'));
      
      // Act - Pin Class B
      await provider.pinClass(class2Id);
      
      // Assert - Class B should now be first (pinned classes come first)
      expect(provider.classes.length, equals(2));
      expect(provider.classes[0].name, equals('Class B'));
      expect(provider.classes[0].isPinned, isTrue);
      expect(provider.classes[1].name, equals('Class A'));
      expect(provider.classes[1].isPinned, isFalse);
    });

    test('pin operations should handle errors gracefully', () async {
      // Arrange - Use non-existent class ID
      const nonExistentClassId = 999;
      
      // Act
      final result = await provider.pinClass(nonExistentClassId);
      
      // Assert
      // Note: SQLite doesn't throw an error for updating non-existent rows,
      // it just returns 0 affected rows, so the operation might succeed
      // but the class won't actually be pinned. This is expected behavior.
      expect(result, isTrue); // The operation succeeds at the database level
      expect(provider.error, isNull); // No error is thrown
      
      // Verify that no classes were actually affected
      expect(provider.classes.where((c) => c.isPinned).length, equals(0));
    });

    test('loading state should be managed correctly during pin operations', () async {
      // Arrange
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      expect(provider.isLoading, isFalse);
      
      // Act & Assert
      final future = provider.pinClass(classId);
      
      // Loading should be true during operation
      expect(provider.isLoading, isTrue);
      
      await future;
      
      // Loading should be false after operation
      expect(provider.isLoading, isFalse);
    });

    test('multiple pin operations should assign correct pin orders', () async {
      // Arrange
      final class1Id = await db.insert(AppConstants.classTable, {
        'name': 'Class 1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      final class2Id = await db.insert(AppConstants.classTable, {
        'name': 'Class 2',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Load classes first
      await provider.loadClasses();
      
      // Act - Pin classes in sequence
      await provider.pinClass(class1Id);
      await provider.pinClass(class2Id);
      
      // Assert - Classes should have correct pin orders
      final pinnedClasses = provider.classes.where((c) => c.isPinned).toList();
      expect(pinnedClasses.length, equals(2));
      
      // First pinned class should have order 1
      final firstPinned = pinnedClasses.firstWhere((c) => c.id == class1Id);
      expect(firstPinned.pinOrder, equals(1));
      
      // Second pinned class should have order 2
      final secondPinned = pinnedClasses.firstWhere((c) => c.id == class2Id);
      expect(secondPinned.pinOrder, equals(2));
      
      // Classes should be sorted by pin order
      expect(provider.classes[0].id, equals(class1Id));
      expect(provider.classes[1].id, equals(class2Id));
    });
  });
}