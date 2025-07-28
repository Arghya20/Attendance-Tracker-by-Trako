import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/pin_indicator.dart';

void main() {
  group('PinIndicator Widget Tests', () {
    testWidgets('should not display when isPinned is false', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicator(isPinned: false),
          ),
        ),
      );

      // Assert
      expect(find.byType(PinIndicator), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('should display pin icon when isPinned is true', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicator(isPinned: true),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PinIndicator), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      void onTap() {
        tapped = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinIndicator(
              isPinned: true,
              onTap: onTap,
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should not call onTap when onTap is null', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicator(
              isPinned: true,
              onTap: null,
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Assert - Should not throw when tapped
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      // No assertion needed - test passes if no exception is thrown
    });

    testWidgets('should use custom size when provided', (WidgetTester tester) async {
      // Arrange
      const customSize = 24.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicator(
              isPinned: true,
              size: customSize,
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Act
      final container = tester.widget<Container>(find.byType(Container));
      final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin));

      // Assert
      expect(container.constraints?.maxWidth, equals(customSize));
      expect(container.constraints?.maxHeight, equals(customSize));
      expect(icon.size, equals(customSize * 0.75));
    });

    testWidgets('should use custom color when provided', (WidgetTester tester) async {
      // Arrange
      const customColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicator(
              isPinned: true,
              color: customColor,
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Act
      final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin));

      // Assert
      expect(icon.color, equals(customColor));
    });

    testWidgets('should use theme primary color when no custom color provided', (WidgetTester tester) async {
      // Arrange
      const primaryColor = Colors.blue;
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: PinIndicator(isPinned: true),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Act
      final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin));

      // Assert
      expect(icon.color, equals(theme.colorScheme.primary));
    });

    testWidgets('should have proper semantic label for accessibility', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicator(isPinned: true),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin));
      expect(icon.semanticLabel, equals('Pinned class'));
    });

    testWidgets('should have rounded container background', (WidgetTester tester) async {
      // Arrange
      const size = 20.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicator(
              isPinned: true,
              size: size,
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Act
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;

      // Assert
      expect(decoration.borderRadius, equals(BorderRadius.circular(size / 4)));
      expect(decoration.color, isNotNull);
    });

    testWidgets('should handle different theme modes correctly', (WidgetTester tester) async {
      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: PinIndicator(isPinned: true),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      final lightIcon = tester.widget<Icon>(find.byIcon(Icons.push_pin));
      expect(lightIcon.color, isNotNull);

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: PinIndicator(isPinned: true),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      final darkIcon = tester.widget<Icon>(find.byIcon(Icons.push_pin));
      expect(darkIcon.color, isNotNull);
    });
  });
}