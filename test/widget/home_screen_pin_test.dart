import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:attendance_tracker/screens/home_screen.dart';
import 'package:attendance_tracker/providers/class_provider.dart';
import 'package:attendance_tracker/providers/theme_provider.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/widgets/pin_context_menu.dart';
import 'package:attendance_tracker/widgets/class_list_item.dart';
import 'package:attendance_tracker/models/class_model.dart';

void main() {
  // Initialize sqflite_common_ffi for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  
  group('HomeScreen Pin Operations Tests', () {
    late Database db;
    late ClassProvider classProvider;
    late ThemeProvider themeProvider;
    
    setUp(() async {
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
      
      classProvider = ClassProvider();
      themeProvider = ThemeProvider();
    });
    
    tearDown(() async {
      await db.close();
    });

    Widget createHomeScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('should display pin context menu on long press', (WidgetTester tester) async {
      // Arrange - Add a test class
      await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Wait for classes to load
      await classProvider.loadClasses();
      await tester.pumpAndSettle();

      // Act - Long press on class item
      final classListItem = find.byType(ClassListItem);
      expect(classListItem, findsOneWidget);
      
      await tester.longPress(classListItem);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PinContextMenu), findsOneWidget);
      expect(find.text('Pin to top'), findsOneWidget);
    });

    testWidgets('should pin class when pin action is triggered', (WidgetTester tester) async {
      // Arrange - Add a test class
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Wait for classes to load
      await classProvider.loadClasses();
      await tester.pumpAndSettle();

      // Verify class is initially unpinned
      expect(classProvider.classes[0].isPinned, isFalse);

      // Act - Swipe right to reveal pin action
      final slidable = find.byType(ClassListItem);
      await tester.drag(slidable, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Tap the pin action
      final pinAction = find.text('Pin').first;
      await tester.tap(pinAction);
      await tester.pumpAndSettle();

      // Assert
      expect(classProvider.classes[0].isPinned, isTrue);
      expect(classProvider.classes[0].pinOrder, equals(1));
      
      // Check for success message
      expect(find.text('Test Class pinned to top'), findsOneWidget);
    });

    testWidgets('should unpin class when unpin action is triggered', (WidgetTester tester) async {
      // Arrange - Add a pinned test class
      final classId = await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Wait for classes to load
      await classProvider.loadClasses();
      await tester.pumpAndSettle();

      // Verify class is initially pinned
      expect(classProvider.classes[0].isPinned, isTrue);

      // Act - Swipe right to reveal unpin action
      final slidable = find.byType(ClassListItem);
      await tester.drag(slidable, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Tap the unpin action
      final unpinAction = find.text('Unpin').first;
      await tester.tap(unpinAction);
      await tester.pumpAndSettle();

      // Assert
      expect(classProvider.classes[0].isPinned, isFalse);
      expect(classProvider.classes[0].pinOrder, isNull);
      
      // Check for success message
      expect(find.text('Pinned Class unpinned'), findsOneWidget);
    });

    testWidgets('should show pin context menu with correct options for unpinned class', (WidgetTester tester) async {
      // Arrange - Add an unpinned test class
      await db.insert(AppConstants.classTable, {
        'name': 'Unpinned Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Wait for classes to load
      await classProvider.loadClasses();
      await tester.pumpAndSettle();

      // Act - Long press to show context menu
      await tester.longPress(find.byType(ClassListItem));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PinContextMenu), findsOneWidget);
      expect(find.text('Pin to top'), findsOneWidget);
      expect(find.text('Unpin from top'), findsNothing);
      expect(find.text('Edit class'), findsOneWidget);
      expect(find.text('Delete class'), findsOneWidget);
    });

    testWidgets('should show pin context menu with correct options for pinned class', (WidgetTester tester) async {
      // Arrange - Add a pinned test class
      await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Wait for classes to load
      await classProvider.loadClasses();
      await tester.pumpAndSettle();

      // Act - Long press to show context menu
      await tester.longPress(find.byType(ClassListItem));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PinContextMenu), findsOneWidget);
      expect(find.text('Pin to top'), findsNothing);
      expect(find.text('Unpin from top'), findsOneWidget);
      expect(find.text('Edit class'), findsOneWidget);
      expect(find.text('Delete class'), findsOneWidget);
    });

    testWidgets('should pin class from context menu', (WidgetTester tester) async {
      // Arrange - Add an unpinned test class
      await db.insert(AppConstants.classTable, {
        'name': 'Test Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Wait for classes to load
      await classProvider.loadClasses();
      await tester.pumpAndSettle();

      // Verify class is initially unpinned
      expect(classProvider.classes[0].isPinned, isFalse);

      // Act - Long press to show context menu
      await tester.longPress(find.byType(ClassListItem));
      await tester.pumpAndSettle();

      // Tap pin option
      await tester.tap(find.text('Pin to top'));
      await tester.pumpAndSettle();

      // Assert
      expect(classProvider.classes[0].isPinned, isTrue);
      expect(find.text('Test Class pinned to top'), findsOneWidget);
    });

    testWidgets('should unpin class from context menu', (WidgetTester tester) async {
      // Arrange - Add a pinned test class
      await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Wait for classes to load
      await classProvider.loadClasses();
      await tester.pumpAndSettle();

      // Verify class is initially pinned
      expect(classProvider.classes[0].isPinned, isTrue);

      // Act - Long press to show context menu
      await tester.longPress(find.byType(ClassListItem));
      await tester.pumpAndSettle();

      // Tap unpin option
      await tester.tap(find.text('Unpin from top'));
      await tester.pumpAndSettle();

      // Assert
      expect(classProvider.classes[0].isPinned, isFalse);
      expect(find.text('Pinned Class unpinned'), findsOneWidget);
    });

    testWidgets('should display classes in correct order with pinned first', (WidgetTester tester) async {
      // Arrange - Add multiple classes with different pin states
      await db.insert(AppConstants.classTable, {
        'name': 'Unpinned Class A',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await db.insert(AppConstants.classTable, {
        'name': 'Pinned Class B',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': 1,
        'pin_order': 1,
      });

      await db.insert(AppConstants.classTable, {
        'name': 'Unpinned Class C',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Wait for classes to load
      await classProvider.loadClasses();
      await tester.pumpAndSettle();

      // Assert - Pinned class should be first
      expect(classProvider.classes.length, equals(3));
      expect(classProvider.classes[0].name, equals('Pinned Class B'));
      expect(classProvider.classes[0].isPinned, isTrue);
      
      // Unpinned classes should follow
      expect(classProvider.classes[1].isPinned, isFalse);
      expect(classProvider.classes[2].isPinned, isFalse);
    });
  });
}