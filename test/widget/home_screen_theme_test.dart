import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/screens/home_screen.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:neopop/neopop.dart';

import 'home_screen_theme_test.mocks.dart';

@GenerateMocks([
  ClassProvider,
  StudentProvider,
  AttendanceProvider,
  ThemeProvider,
])
void main() {
  group('HomeScreen Theme Tests', () {
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
          description: 'Test Description 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Setup default mock behaviors
      when(mockClassProvider.classes).thenReturn(testClasses);
      when(mockClassProvider.isLoading).thenReturn(false);
      when(mockClassProvider.error).thenReturn(null);
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

    Widget createTestWidget({ThemeData? theme}) {
      return MaterialApp(
        theme: theme ?? ThemeData.light(),
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

    testWidgets('should display Add Class button with correct color', (tester) async {
      // Arrange
      final blueTheme = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(theme: blueTheme));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(NeoPopTiltedButton), findsOneWidget);
      expect(find.text('Add Class'), findsOneWidget);

      // Find the NeoPopTiltedButton and check its color
      final button = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      expect(button.color, equals(Colors.blue));
    });

    testWidgets('should update Add Class button color when theme changes', (tester) async {
      // Arrange - Initial blue theme
      final blueTheme = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
        ),
      );

      await tester.pumpWidget(createTestWidget(theme: blueTheme));
      await tester.pumpAndSettle();

      // Verify initial color
      var button = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      expect(button.color, equals(Colors.blue));

      // Act - Change to green theme
      final greenTheme = ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.green,
        ),
      );

      await tester.pumpWidget(createTestWidget(theme: greenTheme));
      await tester.pumpAndSettle();

      // Assert - Button color should update
      button = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      expect(button.color, equals(Colors.green));
    });

    testWidgets('should handle rapid theme changes gracefully', (tester) async {
      // Arrange
      final themes = [
        ThemeData(colorScheme: const ColorScheme.light(primary: Colors.blue)),
        ThemeData(colorScheme: const ColorScheme.light(primary: Colors.green)),
        ThemeData(colorScheme: const ColorScheme.light(primary: Colors.purple)),
        ThemeData(colorScheme: const ColorScheme.light(primary: Colors.teal)),
      ];

      // Act - Rapidly change themes
      for (final theme in themes) {
        await tester.pumpWidget(createTestWidget(theme: theme));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      // Assert - Should end up with the last theme (teal)
      final button = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      expect(button.color, equals(Colors.teal));
    });

    testWidgets('should maintain button functionality after theme change', (tester) async {
      // Arrange
      final blueTheme = ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.blue),
      );

      await tester.pumpWidget(createTestWidget(theme: blueTheme));
      await tester.pumpAndSettle();

      // Act - Change theme
      final greenTheme = ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.green),
      );

      await tester.pumpWidget(createTestWidget(theme: greenTheme));
      await tester.pumpAndSettle();

      // Assert - Button should still be tappable
      expect(find.byType(NeoPopTiltedButton), findsOneWidget);
      
      // Tap the button to ensure it's still functional
      await tester.tap(find.byType(NeoPopTiltedButton));
      await tester.pumpAndSettle();

      // Should not throw any errors
    });

    testWidgets('should work with dark theme', (tester) async {
      // Arrange
      final darkTheme = ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.lightBlue,
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(theme: darkTheme));
      await tester.pumpAndSettle();

      // Assert
      final button = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      expect(button.color, equals(Colors.lightBlue));
    });

    testWidgets('should handle theme changes with empty class list', (tester) async {
      // Arrange - Empty class list
      when(mockClassProvider.classes).thenReturn([]);

      final blueTheme = ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.blue),
      );

      await tester.pumpWidget(createTestWidget(theme: blueTheme));
      await tester.pumpAndSettle();

      // Should show empty state with Add Class button
      expect(find.text('No classes yet'), findsOneWidget);
      expect(find.byType(NeoPopTiltedButton), findsOneWidget);

      // Act - Change theme
      final greenTheme = ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.green),
      );

      await tester.pumpWidget(createTestWidget(theme: greenTheme));
      await tester.pumpAndSettle();

      // Assert - Button color should update even in empty state
      final button = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      expect(button.color, equals(Colors.green));
    });

    testWidgets('should preserve RepaintBoundary optimization', (tester) async {
      // Arrange
      final theme = ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.blue),
      );

      // Act
      await tester.pumpWidget(createTestWidget(theme: theme));
      await tester.pumpAndSettle();

      // Assert - RepaintBoundary should be present for performance
      expect(find.byType(RepaintBoundary), findsWidgets);
      
      // The FloatingActionButton should be wrapped in RepaintBoundary
      final repaintBoundaries = find.byType(RepaintBoundary);
      expect(repaintBoundaries, findsAtLeastNWidgets(1));
    });

    testWidgets('should handle Consumer widget correctly', (tester) async {
      // Arrange
      final theme = ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.blue),
      );

      // Act
      await tester.pumpWidget(createTestWidget(theme: theme));
      await tester.pumpAndSettle();

      // Assert - Consumer should be present to listen to theme changes
      expect(find.byType(Consumer<ThemeProvider>), findsOneWidget);
    });

    testWidgets('should update button text color consistently', (tester) async {
      // Arrange
      final theme = ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.blue),
      );

      // Act
      await tester.pumpWidget(createTestWidget(theme: theme));
      await tester.pumpAndSettle();

      // Assert - Button text should be white (as hardcoded in the design)
      final textWidget = tester.widget<Text>(
        find.text('Add Class'),
      );
      expect(textWidget.style?.color, equals(Colors.white));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
    });
  });
}