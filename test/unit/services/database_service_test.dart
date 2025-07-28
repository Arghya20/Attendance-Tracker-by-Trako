import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

// Generate a MockDatabase using Mockito
@GenerateMocks([Database])
import 'database_service_test.mocks.dart';

void main() {
  // Initialize sqflite_common_ffi for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  
  group('DatabaseService Tests', () {
    late DatabaseService databaseService;
    late MockDatabase mockDatabase;
    
    setUp(() {
      databaseService = DatabaseService();
      mockDatabase = MockDatabase();
    });
    
    test('getCurrentDateTime returns a valid ISO8601 string', () {
      // Act
      final dateTimeString = databaseService.getCurrentDateTime();
      
      // Assert
      expect(dateTimeString, isA<String>());
      expect(DateTime.tryParse(dateTimeString), isA<DateTime>());
    });
    
    test('getCurrentDateTime should return valid ISO8601 string', () async {
      // Act
      final dateTime = databaseService.getCurrentDateTime();
      
      // Assert
      expect(dateTime, isA<String>());
      expect(DateTime.tryParse(dateTime), isNotNull);
    });
  });
  
  group('DatabaseService Integration Tests', () {
    late DatabaseService databaseService;
    late Database db;
    
    setUp(() async {
      // Use the actual implementation with an in-memory database
      databaseService = DatabaseService();
      
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
      // Note: This is a hack for testing purposes
      // In a real app, you would use dependency injection
      // ignore: invalid_use_of_protected_member
      DatabaseService.setDatabaseForTesting(db);
    });
    
    tearDown(() async {
      await db.close();
    });
    
    test('insert and getById should work correctly', () async {
      // Arrange
      final testData = {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Act
      final id = await databaseService.insert(AppConstants.classTable, testData);
      final result = await databaseService.getById(AppConstants.classTable, id);
      
      // Assert
      expect(id, isA<int>());
      expect(id, greaterThan(0));
      expect(result, isNotNull);
      expect(result!['id'], equals(id));
      expect(result['name'], equals('Test Class'));
      expect(result['is_pinned'], equals(0)); // Default value
      expect(result['pin_order'], isNull); // Default value
    });

    test('insert with pin properties should work correctly', () async {
      // Arrange
      final testData = {
        'name': 'Pinned Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      };
      
      // Act
      final id = await databaseService.insert(AppConstants.classTable, testData);
      final result = await databaseService.getById(AppConstants.classTable, id);
      
      // Assert
      expect(result, isNotNull);
      expect(result!['is_pinned'], equals(1));
      expect(result['pin_order'], equals(1));
    });
    
    test('update should modify existing record', () async {
      // Arrange
      final testData = {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      final id = await databaseService.insert(AppConstants.classTable, testData);
      
      // Act
      final updateData = {
        'name': 'Updated Class',
        'updated_at': DateTime.now().toIso8601String(),
      };
      final updateCount = await databaseService.update(AppConstants.classTable, updateData, id);
      final result = await databaseService.getById(AppConstants.classTable, id);
      
      // Assert
      expect(updateCount, equals(1));
      expect(result!['name'], equals('Updated Class'));
    });

    test('update pin properties should work correctly', () async {
      // Arrange
      final testData = {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      final id = await databaseService.insert(AppConstants.classTable, testData);
      
      // Act
      final updateData = {
        'is_pinned': 1,
        'pin_order': 2,
        'updated_at': DateTime.now().toIso8601String(),
      };
      final updateCount = await databaseService.update(AppConstants.classTable, updateData, id);
      final result = await databaseService.getById(AppConstants.classTable, id);
      
      // Assert
      expect(updateCount, equals(1));
      expect(result!['is_pinned'], equals(1));
      expect(result['pin_order'], equals(2));
    });
    
    test('delete should remove record', () async {
      // Arrange
      final testData = {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      final id = await databaseService.insert(AppConstants.classTable, testData);
      
      // Act
      final deleteCount = await databaseService.delete(AppConstants.classTable, id);
      final result = await databaseService.getById(AppConstants.classTable, id);
      
      // Assert
      expect(deleteCount, equals(1));
      expect(result, isNull);
    });
    
    test('getAll should return all records', () async {
      // Arrange
      await databaseService.insert(AppConstants.classTable, {
        'name': 'Class 1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await databaseService.insert(AppConstants.classTable, {
        'name': 'Class 2',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Act
      final results = await databaseService.getAll(AppConstants.classTable);
      
      // Assert
      expect(results.length, equals(2));
      expect(results[0]['name'], equals('Class 1'));
      expect(results[1]['name'], equals('Class 2'));
    });
    
    test('rawQuery should execute custom SQL', () async {
      // Arrange
      await databaseService.insert(AppConstants.classTable, {
        'name': 'Class 1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await databaseService.insert(AppConstants.classTable, {
        'name': 'Class 2',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Act
      final results = await databaseService.rawQuery(
        'SELECT * FROM ${AppConstants.classTable} WHERE name = ?',
        ['Class 1'],
      );
      
      // Assert
      expect(results.length, equals(1));
      expect(results[0]['name'], equals('Class 1'));
    });
  });

  group('Database Migration Tests', () {
    test('migration from version 1 to 2 should add pin columns', () async {
      // Arrange - Create database with version 1 schema
      final dbPath = ':memory:migration_test';
      final db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Create old schema without pin columns
            await db.execute('''
              CREATE TABLE ${AppConstants.classTable} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      // Insert test data with old schema
      await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await db.close();

      // Act - Reopen database with version 2 to trigger migration
      final migratedDb = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            // This shouldn't be called since database already exists
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              // Add pin functionality columns to classes table
              await db.execute('ALTER TABLE ${AppConstants.classTable} ADD COLUMN is_pinned INTEGER DEFAULT 0');
              await db.execute('ALTER TABLE ${AppConstants.classTable} ADD COLUMN pin_order INTEGER DEFAULT NULL');
              
              // Create indexes for pin functionality
              await db.execute(
                'CREATE INDEX idx_class_pinned ON ${AppConstants.classTable} (is_pinned)'
              );
              await db.execute(
                'CREATE INDEX idx_class_pin_order ON ${AppConstants.classTable} (pin_order)'
              );
            }
          },
        ),
      );

      // Assert - Check that pin columns exist and have default values
      final result = await migratedDb.query(AppConstants.classTable);
      expect(result.length, equals(1));
      expect(result[0]['name'], equals('Test Class'));
      expect(result[0]['is_pinned'], equals(0));
      expect(result[0]['pin_order'], isNull);

      // Test that we can update pin values
      await migratedDb.update(
        AppConstants.classTable,
        {'is_pinned': 1, 'pin_order': 1},
        where: 'id = ?',
        whereArgs: [result[0]['id']],
      );

      final updatedResult = await migratedDb.query(AppConstants.classTable);
      expect(updatedResult[0]['is_pinned'], equals(1));
      expect(updatedResult[0]['pin_order'], equals(1));

      await migratedDb.close();
    });
  });
}