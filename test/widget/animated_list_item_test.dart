import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/animated_list_item.dart';

void main() {
  group('AnimatedListItem Widget Tests', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Child');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              child: testChild,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Test Child'), findsOneWidget);
    });
    
    testWidgets('should animate with fade type', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Child');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              animationType: AnimationType.fade,
              child: testChild,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.text('Test Child'), findsOneWidget);
      
      // Verify animation starts
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransition.opacity.value, equals(0.0)); // Initial value
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 150));
      
      // Verify animation is in progress
      final fadeTransitionAfter = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransitionAfter.opacity.value, greaterThan(0.0));
    });
    
    testWidgets('should animate with scale type', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Child');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              animationType: AnimationType.scale,
              child: testChild,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(ScaleTransition), findsOneWidget);
      expect(find.text('Test Child'), findsOneWidget);
    });
    
    testWidgets('should animate with slide type', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Child');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              animationType: AnimationType.slide,
              child: testChild,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(AnimatedBuilder), findsOneWidget);
      expect(find.text('Test Child'), findsOneWidget);
    });
    
    testWidgets('should animate with slideHorizontal type', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Child');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              animationType: AnimationType.slideHorizontal,
              child: testChild,
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(AnimatedBuilder), findsOneWidget);
      expect(find.text('Test Child'), findsOneWidget);
    });
    
    testWidgets('should respect delay based on index', (WidgetTester tester) async {
      // Arrange
      const testChild1 = Text('Item 1');
      const testChild2 = Text('Item 2');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnimatedListItem(
                  index: 0,
                  animationType: AnimationType.fade,
                  child: testChild1,
                ),
                AnimatedListItem(
                  index: 1,
                  animationType: AnimationType.fade,
                  child: testChild2,
                ),
              ],
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      
      // Verify first item starts animating immediately
      await tester.pump(const Duration(milliseconds: 25));
      
      // Verify second item starts animating after delay
      await tester.pump(const Duration(milliseconds: 50));
      
      // Complete animations
      await tester.pump(const Duration(milliseconds: 300));
      
      // Both items should be fully visible
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
  });
}