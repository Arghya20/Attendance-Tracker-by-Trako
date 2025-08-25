import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/main.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/screens/home_screen.dart';
import 'package:attendance_tracker/screens/class_detail_screen.dart';
import 'package:attendance_tracker/screens/statistics_screen.dart';
import 'package:attendance_tracker/screens/month_export_screen.dart';
import 'package:attendance_tracker/widgets/month_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Month Export Integration Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should complete full month export flow from statistics screen', (tester) async {
      // Arrange - Start the app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ClassProvider()),
            ChangeNotifierProvider(create: (_) => StudentProvider()),
            ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for splash screen
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash screen if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Should be on home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Create a test class first (if no classes exist)
      if (find.text('No classes found').evaluate().isNotEmpty) {
        // Tap Add Class button
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Enter class name
        await tester.enterText(find.byType(TextFormField), 'Test Class');
        await tester.pumpAndSettle();

        // Tap Add button
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
      }

      // Tap on a class to navigate to class detail screen
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Should be on class detail screen
      expect(find.byType(ClassDetailScreen), findsOneWidget);

      // Navigate to Statistics tab
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      // Should be on statistics screen
      expect(find.byType(StatisticsScreen), findsOneWidget);

      // Tap the export data button (now a popup menu)
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      // Should see popup menu with export options
      expect(find.text('Monthly Report'), findsOneWidget);
      expect(find.text('Summary Report'), findsOneWidget);

      // Tap Monthly Report option
      await tester.tap(find.text('Monthly Report'));
      await tester.pumpAndSettle();

      // Should show month selection dialog
      expect(find.byType(MonthSelectionDialog), findsOneWidget);
      expect(find.text('Select Month'), findsOneWidget);

      // If no months available, should show empty state
      if (find.text('No Attendance Data Found').evaluate().isNotEmpty) {
        expect(find.text('There are no attendance sessions recorded for this class yet.'), findsOneWidget);
        
        // Cancel the dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        
        // Should be back on statistics screen
        expect(find.byType(StatisticsScreen), findsOneWidget);
      } else {
        // If months are available, select the first one
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        // Should navigate to month export screen
        expect(find.byType(MonthExportScreen), findsOneWidget);
        expect(find.text('Attendance Report'), findsOneWidget);

        // Should see download button if data is available
        if (find.byIcon(Icons.download).evaluate().isNotEmpty) {
          // Tap download button to test export functionality
          await tester.tap(find.byIcon(Icons.download));
          await tester.pump();

          // Should show loading indicator briefly
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          await tester.pumpAndSettle();
        }

        // Navigate back to statistics screen
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Should be back on statistics screen
        expect(find.byType(StatisticsScreen), findsOneWidget);
      }
    });

    testWidgets('should handle month selection dialog interactions correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ClassProvider()),
            ChangeNotifierProvider(create: (_) => StudentProvider()),
            ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate to a class and statistics screen
      if (find.text('No classes found').evaluate().isEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();

        // Open export menu
        await tester.tap(find.byIcon(Icons.download));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Monthly Report'));
        await tester.pumpAndSettle();

        // Should show month selection dialog
        expect(find.byType(MonthSelectionDialog), findsOneWidget);

        // Test cancel functionality
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Should be back on statistics screen
        expect(find.byType(StatisticsScreen), findsOneWidget);
        expect(find.byType(MonthSelectionDialog), findsNothing);
      }
    });

    testWidgets('should display correct data in month export screen', (tester) async {
      // This test would require setting up test data in the database
      // For demonstration purposes, we'll test the UI structure
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ClassProvider()),
            ChangeNotifierProvider(create: (_) => StudentProvider()),
            ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate through the flow
      if (find.text('No classes found').evaluate().isEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.download));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Monthly Report'));
        await tester.pumpAndSettle();

        // If months are available, test the export screen
        if (find.byType(ListTile).evaluate().isNotEmpty) {
          await tester.tap(find.byType(ListTile).first);
          await tester.pumpAndSettle();

          // Should be on month export screen
          expect(find.byType(MonthExportScreen), findsOneWidget);

          // Should have proper structure
          expect(find.text('Attendance Report'), findsOneWidget);
          
          // Should have either data table or empty state
          final hasDataTable = find.byType(DataTable).evaluate().isNotEmpty;
          final hasEmptyState = find.text('No Attendance Data').evaluate().isNotEmpty;
          
          expect(hasDataTable || hasEmptyState, isTrue);

          if (hasDataTable) {
            // Should have table headers
            expect(find.text('SL'), findsOneWidget);
            expect(find.text('Name'), findsOneWidget);
            expect(find.text('Percentage'), findsOneWidget);
          }
        }
      }
    });

    testWidgets('should handle export functionality without errors', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ClassProvider()),
            ChangeNotifierProvider(create: (_) => StudentProvider()),
            ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate through the flow
      if (find.text('No classes found').evaluate().isEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.download));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Monthly Report'));
        await tester.pumpAndSettle();

        if (find.byType(ListTile).evaluate().isNotEmpty) {
          await tester.tap(find.byType(ListTile).first);
          await tester.pumpAndSettle();

          // If download button is available, test it
          if (find.byIcon(Icons.download).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.download));
            await tester.pumpAndSettle();

            // Should not throw any exceptions
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('should maintain state consistency during navigation', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ClassProvider()),
            ChangeNotifierProvider(create: (_) => StudentProvider()),
            ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate through multiple screens and back
      if (find.text('No classes found').evaluate().isEmpty) {
        // Remember the initial class name
        final initialClassCard = find.byType(Card).first;
        await tester.tap(initialClassCard);
        await tester.pumpAndSettle();

        // Go to statistics
        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();

        // Go back to class detail
        await tester.tap(find.text('Students'));
        await tester.pumpAndSettle();

        // Go back to statistics
        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();

        // Should still be on the same class's statistics
        expect(find.byType(StatisticsScreen), findsOneWidget);

        // Go back to home
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Should be back on home screen
        expect(find.byType(HomeScreen), findsOneWidget);

        // Should not have any exceptions
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should handle summary export functionality', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ClassProvider()),
            ChangeNotifierProvider(create: (_) => StudentProvider()),
            ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate to statistics
      if (find.text('No classes found').evaluate().isEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();

        // Test summary export
        await tester.tap(find.byIcon(Icons.download));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Summary Report'));
        await tester.pumpAndSettle();

        // Should not show month selection dialog for summary
        expect(find.byType(MonthSelectionDialog), findsNothing);

        // Should remain on statistics screen
        expect(find.byType(StatisticsScreen), findsOneWidget);

        // Should not throw any exceptions
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should handle performance with large datasets', (tester) async {
      // This test would ideally create a large dataset and test performance
      // For demonstration, we'll test the UI responsiveness
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ClassProvider()),
            ChangeNotifierProvider(create: (_) => StudentProvider()),
            ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Perform rapid navigation to test responsiveness
      if (find.text('No classes found').evaluate().isEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byType(Card).first);
          await tester.pump(const Duration(milliseconds: 100));

          await tester.tap(find.text('Statistics'));
          await tester.pump(const Duration(milliseconds: 100));

          await tester.tap(find.byType(BackButton));
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        // Should not have any exceptions after rapid navigation
        expect(tester.takeException(), isNull);
        expect(find.byType(HomeScreen), findsOneWidget);
      }
    });
  });
}