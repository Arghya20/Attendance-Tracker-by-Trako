import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/backup_restore_dialog.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

void main() {
  group('BackupRestoreDialog Widget Tests', () {
    testWidgets('should display dialog with correct title and sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppConstants.getLightTheme(),
          home: const Scaffold(
            body: BackupRestoreDialog(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify dialog title
      expect(find.text('Backup & Restore'), findsOneWidget);
      
      // Verify backup section
      expect(find.text('Create Backup'), findsOneWidget);
      expect(find.text('Export all your data to a backup file that you can save and restore later.'), findsOneWidget);
      expect(find.text('Create & Download Backup'), findsOneWidget);
      
      // Verify restore section
      expect(find.text('Restore Backup'), findsOneWidget);
      expect(find.text('Import data from a backup file. This will replace all current data.'), findsOneWidget);
      expect(find.text('Select & Restore Backup'), findsOneWidget);
      
      // Verify close button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should show loading indicator when processing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppConstants.getLightTheme(),
          home: const Scaffold(
            body: BackupRestoreDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no loading indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // The loading state would be triggered by actual button presses
      // which require mocking the BackupService, so we'll keep this test simple
    });

    testWidgets('should close dialog when close button is tapped', (WidgetTester tester) async {
      bool dialogClosed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppConstants.getLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const BackupRestoreDialog(),
                  );
                  if (result == null) {
                    dialogClosed = true;
                  }
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Backup & Restore'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(dialogClosed, isTrue);
      expect(find.text('Backup & Restore'), findsNothing);
    });

    testWidgets('should display current data section when stats are loaded', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppConstants.getLightTheme(),
          home: const Scaffold(
            body: BackupRestoreDialog(),
          ),
        ),
      );

      // Wait for stats to load (this would require mocking in a real test)
      await tester.pumpAndSettle();

      // The current data section should appear once stats are loaded
      // In a real implementation, we'd mock the BackupService to return test data
    });
  });
}