import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';

void main() {
  group('CustomSnackBar Tests', () {
    testWidgets('should show snackbar with message', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Test message';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CustomSnackBar.show(
                        context: context,
                        message: testMessage,
                      );
                    },
                    child: const Text('Show SnackBar'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('Show SnackBar'));
      await tester.pump(); // Build scheduled animation.
      await tester.pump(); // Schedule animation.
      await tester.pump(const Duration(milliseconds: 750)); // Forward animation.
      
      // Assert
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget); // Default icon
    });
    
    testWidgets('should show snackbar with success type', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Success message';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CustomSnackBar.show(
                        context: context,
                        message: testMessage,
                        type: SnackBarType.success,
                      );
                    },
                    child: const Text('Show SnackBar'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      
      // Assert
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
    
    testWidgets('should show snackbar with error type', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Error message';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CustomSnackBar.show(
                        context: context,
                        message: testMessage,
                        type: SnackBarType.error,
                      );
                    },
                    child: const Text('Show SnackBar'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      
      // Assert
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
    
    testWidgets('should show snackbar with action', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Test message';
      bool actionPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CustomSnackBar.show(
                        context: context,
                        message: testMessage,
                        action: SnackBarAction(
                          label: 'Action',
                          onPressed: () {
                            actionPressed = true;
                          },
                        ),
                      );
                    },
                    child: const Text('Show SnackBar'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      
      // Assert
      expect(find.text(testMessage), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      
      // Tap the action button
      await tester.tap(find.text('Action'));
      await tester.pump();
      
      // Verify the action callback was called
      expect(actionPressed, isTrue);
    });
  });
}