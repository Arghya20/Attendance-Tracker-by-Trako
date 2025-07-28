import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/class_list_item.dart';
import 'package:attendance_tracker/widgets/pin_indicator.dart';
import 'package:attendance_tracker/models/class_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

void main() {
  group('ClassListItem Widget Tests', () {
    late Class testClass;
    late Class pinnedClass;

    setUp(() {
      testClass = Class(
        id: 1,
        name: 'Mathematics',
        studentCount: 25,
        sessionCount: 10,
      );

      pinnedClass = Class(
        id: 2,
        name: 'Science',
        isPinned: true,
        pinOrder: 1,
        studentCount: 30,
        sessionCount: 15,
      );
    });

    testWidgets('should display class information correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: testClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('25 Students'), findsOneWidget);
      expect(find.text('10 Sessions'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('should display Empty status for class with no students', (WidgetTester tester) async {
      // Arrange
      final emptyClass = Class(
        id: 1,
        name: 'Empty Class',
        studentCount: 0,
        sessionCount: 0,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: emptyClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('0 Students'), findsOneWidget);
      expect(find.text('0 Sessions'), findsOneWidget);
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
            body: ClassListItem(
              classItem: testClass,
              onTap: onTap,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should call onLongPress when long pressed', (WidgetTester tester) async {
      // Arrange
      bool longPressed = false;
      void onLongPress() {
        longPressed = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: testClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              onLongPress: onLongPress,
            ),
          ),
        ),
      );

      // Act
      await tester.longPress(find.byType(InkWell));
      await tester.pump();

      // Assert
      expect(longPressed, isTrue);
    });

    testWidgets('should display pin indicator for pinned class', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: pinnedClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PinIndicator), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('should not display pin indicator for unpinned class', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: testClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(PinIndicator), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsNothing);
    });

    testWidgets('should call onUnpin when pin indicator is tapped', (WidgetTester tester) async {
      // Arrange
      bool unpinCalled = false;
      void onUnpin() {
        unpinCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: pinnedClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              onUnpin: onUnpin,
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Act - Find the pin indicator and tap it
      final pinIndicator = find.byType(PinIndicator);
      expect(pinIndicator, findsOneWidget);
      
      await tester.tap(pinIndicator, warnIfMissed: false);
      await tester.pump();

      // Assert
      expect(unpinCalled, isTrue);
    });

    testWidgets('should show pin action in swipe for unpinned class', (WidgetTester tester) async {
      // Arrange
      bool pinCalled = false;
      void onPin() {
        pinCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: testClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              onPin: onPin,
            ),
          ),
        ),
      );

      // Act - Swipe right to reveal start actions
      await tester.drag(find.byType(Slidable), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.push_pin), findsAtLeastNWidgets(1));

      // Tap the pin action by finding the SlidableAction
      final pinAction = find.byType(SlidableAction).first;
      await tester.tap(pinAction);
      await tester.pump();

      expect(pinCalled, isTrue);
    });

    testWidgets('should show unpin action in swipe for pinned class', (WidgetTester tester) async {
      // Arrange
      bool unpinCalled = false;
      void onUnpin() {
        unpinCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: pinnedClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              onUnpin: onUnpin,
            ),
          ),
        ),
      );

      // Act - Swipe right to reveal start actions
      await tester.drag(find.byType(Slidable), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);

      // Tap the unpin action by finding the SlidableAction
      final unpinAction = find.byType(SlidableAction).first;
      await tester.tap(unpinAction);
      await tester.pump();

      expect(unpinCalled, isTrue);
    });

    testWidgets('should show edit and delete actions in end swipe', (WidgetTester tester) async {
      // Arrange
      bool editCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: testClass,
              onTap: () {},
              onEdit: () => editCalled = true,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      // Act - Swipe left to reveal end actions
      final slidable = find.byType(Slidable);
      await tester.drag(slidable, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Assert - Check for SlidableAction widgets instead of text
      final slidableActions = find.byType(SlidableAction);
      expect(slidableActions, findsAtLeastNWidgets(2));

      // Find edit and delete icons
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // Test edit action by tapping the edit icon
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      expect(editCalled, isTrue);

      // Reset slidable and test delete action
      await tester.drag(slidable, const Offset(300, 0)); // Reset
      await tester.pumpAndSettle();
      await tester.drag(slidable, const Offset(-300, 0)); // Swipe again
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();
      expect(deleteCalled, isTrue);
    });

    testWidgets('should have different styling for pinned class', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ClassListItem(
                  classItem: testClass,
                  onTap: () {},
                  onEdit: () {},
                  onDelete: () {},
                ),
                ClassListItem(
                  classItem: pinnedClass,
                  onTap: () {},
                  onEdit: () {},
                  onDelete: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Assert
      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards.length, equals(2));

      // Unpinned class should have elevation 1
      expect(cards[0].elevation, equals(1.0));
      
      // Pinned class should have higher elevation (animated)
      expect(cards[1].elevation, greaterThan(1.0));

      // Check for gradient container in pinned class
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final pinnedContainer = containers.firstWhere(
        (container) => container.decoration is BoxDecoration && 
                      (container.decoration as BoxDecoration).gradient != null,
        orElse: () => Container(),
      );
      
      expect(pinnedContainer.decoration, isA<BoxDecoration>());
    });

    testWidgets('should handle singular/plural text correctly', (WidgetTester tester) async {
      // Arrange
      final singleClass = Class(
        id: 1,
        name: 'Single Class',
        studentCount: 1,
        sessionCount: 1,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassListItem(
              classItem: singleClass,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('1 Student'), findsOneWidget);
      expect(find.text('1 Session'), findsOneWidget);
    });
  });
}