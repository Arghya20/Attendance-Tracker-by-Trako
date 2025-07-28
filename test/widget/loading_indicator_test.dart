import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';

void main() {
  group('LoadingIndicator Widget Tests', () {
    testWidgets('should display CircularProgressIndicator', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('should display message when provided', (WidgetTester tester) async {
      // Arrange
      const testMessage = 'Loading data...';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: testMessage),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
    });
    
    testWidgets('should not display message when not provided', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });
    
    testWidgets('should be centered', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(Center), findsOneWidget);
    });
  });
}