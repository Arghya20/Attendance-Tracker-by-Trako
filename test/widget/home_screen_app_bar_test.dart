import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/screens/home_screen.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

import 'home_screen_theme_test.mocks.dart';

@GenerateMocks([
  ClassProvider,
  StudentProvider,
  AttendanceProvider,
  ThemeProvider,
])
void main() {
  group('HomeScreen App Bar Tests', () {
    late MockClassProvider mockClassProvider;
    late MockStudentProvider mockStudentProvider;
    late MockAttendanceProvider mockAttendanceProvider;
    late MockThemeProvider mockThemeProvider;
    late List<Class> testClasses;

    setUp(() {
      mockClassProvider = MockClassProvider();
      mockStudentProvider = MockStudentProvider();
      mockAttendanceProvider = MockAttendanceProvider();
      mockThemeProvider = MockThemeProvider();

      testClasses = [
        Class(
          id: 1,
          name: 'Test Class 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Class(
          id: 2,
          name: 'Test Class 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Setup default mock behaviors
      when(mockClassProvider.classes).thenReturn(testClasses);
      when(mockClassProvider.isLoading).thenReturn(false);
      when(mockClassProvider.error).thenReturn(null);
      when(mockClassProvider.loadClasses()).thenAnswer((_) async {});
      when(mockStudentProvider.isLoading).thenReturn(false);
      when(mockStudentProvider.error).thenReturn(null);
      when(mockAttendanceProvider.isLoading).thenReturn(false);
      when(mockAttendanceProvider.error).thenReturn(null);
      
      // Setup theme provider defaults
      when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
      when(mockThemeProvider.colorSchemeIndex).thenReturn(0);
      when(mockThemeProvider.lightTheme).thenReturn(ThemeData.light());
      when(mockThemeProvider.darkTheme).thenReturn(ThemeData.dark());
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ClassProvider>.value(value: mockClassProvider),
            ChangeNotifierProvider<StudentProvider>.value(value: mockStudentProvider),
            ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendanceProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ],
          child: const HomeScreen(),
        ),
      );
    }

    testWidgets('should display app bar with correct title', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
    });

    testWidgets('should display only settings button in app bar actions', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Settings button should be present
      expect(find.byIcon(Icons.settings), findsOneWidget);
      
      // Assert - Refresh button should NOT be present
      expect(find.byIcon(Icons.refresh), findsNothing);
      
      // Assert - Only one action button should be present
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions?.length, equals(1));
    });

    testWidgets('should have correct tooltip for settings button', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the settings IconButton
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);

      // Get the IconButton widget and check its tooltip
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: settingsButton,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.tooltip, equals('Settings'));
    });

    testWidgets('should have tappable settings button', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Settings button should be tappable (no exception thrown)
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
      
      // Verify the button is enabled and has an onPressed callback
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: settingsButton,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('should display RefreshIndicator for pull-to-refresh', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - RefreshIndicator should be present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should trigger refresh when pull-to-refresh is used', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Perform pull-to-refresh gesture
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert - loadClasses should be called
      verify(mockClassProvider.loadClasses()).called(greaterThan(1));
    });

    testWidgets('should maintain app bar structure with empty class list', (tester) async {
      // Arrange - Empty class list
      when(mockClassProvider.classes).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - App bar should still have correct structure
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
      
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions?.length, equals(1));
    });

    testWidgets('should maintain app bar structure during loading state', (tester) async {
      // Arrange - Loading state
      when(mockClassProvider.isLoading).thenReturn(true);
      when(mockClassProvider.classes).thenReturn([]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump instead of pumpAndSettle for loading state

      // Assert - App bar should still have correct structure
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
      
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions?.length, equals(1));
    });

    testWidgets('should maintain app bar structure during error state', (tester) async {
      // Arrange - Error state
      when(mockClassProvider.error).thenReturn('Test error');

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - App bar should still have correct structure
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
      
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions?.length, equals(1));
    });

    testWidgets('should have correct app bar elevation', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.elevation, equals(2));
    });

    testWidgets('should not have refresh functionality in app bar actions', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Verify no refresh-related widgets in app bar
      expect(find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.refresh),
      ), findsNothing);
      
      expect(find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Refresh'),
      ), findsNothing);
      
      // Verify only settings-related action exists
      expect(find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.settings),
      ), findsOneWidget);
    });

    testWidgets('should work correctly with pull-to-refresh when classes exist', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify classes are displayed
      expect(find.text('Test Class 1'), findsOneWidget);
      expect(find.text('Test Class 2'), findsOneWidget);

      // Reset the mock call count
      clearInteractions(mockClassProvider);

      // Perform pull-to-refresh
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert - loadClasses should be called for refresh
      verify(mockClassProvider.loadClasses()).called(1);
    });
  });
}