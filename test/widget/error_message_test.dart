import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/error_message.dart';

void main() {
  group('ErrorMessage Widget Tests', () {
    testWidgets('should display error message', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'An error occurred';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: testMessage),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Error'), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
    
    testWidgets('should display retry button when onRetry is provided', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'An error occurred';
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorMessage(
              message: testMessage,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Tap the retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      // Verify the onRetry callback was called
      expect(retryPressed, isTrue);
    });
    
    testWidgets('should not display retry button when onRetry is not provided', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'An error occurred';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: testMessage),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Retry'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });
    
    testWidgets('should be centered', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'An error occurred';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: testMessage),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(Center), findsOneWidget);
    });
  });
}