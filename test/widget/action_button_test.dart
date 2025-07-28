import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/action_button.dart';

void main() {
  group('ActionButton Widget Tests', () {
    testWidgets('should display label and icon', (WidgetTester tester) async {
      // Arrange
      const testLabel = 'Test Button';
      const testIcon = Icons.add;
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ActionButton(
                label: testLabel,
                icon: testIcon,
                onPressed: () {
                  buttonPressed = true;
                },
              ),
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text(testLabel), findsOneWidget);
      expect(find.byIcon(testIcon), findsOneWidget);
      
      // Tap the button
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      
      // Verify the onPressed callback was called
      expect(buttonPressed, isTrue);
    });
    
    testWidgets('should use provided color', (WidgetTester tester) async {
      // Arrange
      const testLabel = 'Test Button';
      const testIcon = Icons.add;
      const testColor = Colors.red;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ActionButton(
                label: testLabel,
                icon: testIcon,
                onPressed: () {},
                color: testColor,
              ),
            ),
          ),
        ),
      );
      
      // Act & Assert
      final iconContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(ActionButton),
          matching: find.byType(Container).first,
        ),
      );
      
      // Verify the color is used
      expect(
        (iconContainer.decoration as BoxDecoration).color,
        equals(testColor.withOpacity(0.1)), // This is a test, so we can ignore the deprecation warning
      );
      
      final icon = tester.widget<Icon>(find.byIcon(testIcon));
      expect(icon.color, equals(testColor));
    });
    
    testWidgets('should use theme color when no color is provided', (WidgetTester tester) async {
      // Arrange
      const testLabel = 'Test Button';
      const testIcon = Icons.add;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          home: const Scaffold(
            body: Center(
              child: ActionButton(
                label: testLabel,
                icon: testIcon,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      
      // Act & Assert
      final icon = tester.widget<Icon>(find.byIcon(testIcon));
      expect(icon.color, equals(Colors.blue));
    });
  });
}