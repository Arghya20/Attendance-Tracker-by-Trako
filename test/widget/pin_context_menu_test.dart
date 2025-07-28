import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/pin_context_menu.dart';
import 'package:attendance_tracker/models/class_model.dart';

void main() {
  group('PinContextMenu Widget Tests', () {
    late Class unpinnedClass;
    late Class pinnedClass;

    setUp(() {
      unpinnedClass = Class(
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

    testWidgets('should display class name and info correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('should show pin indicator for pinned class', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: pinnedClass,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Science'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('should show pin option for unpinned class', (WidgetTester tester) async {
      // Arrange
      bool pinCalled = false;
      void onPin() {
        pinCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onPin: onPin,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Pin to top'), findsOneWidget);
      expect(find.text('Keep at the top of the list'), findsOneWidget);

      // Act
      await tester.tap(find.text('Pin to top'));
      await tester.pump();

      // Assert
      expect(pinCalled, isTrue);
    });

    testWidgets('should show unpin option for pinned class', (WidgetTester tester) async {
      // Arrange
      bool unpinCalled = false;
      void onUnpin() {
        unpinCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: pinnedClass,
              onUnpin: onUnpin,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Unpin from top'), findsOneWidget);
      expect(find.text('Remove from pinned classes'), findsOneWidget);

      // Act
      await tester.tap(find.text('Unpin from top'));
      await tester.pump();

      // Assert
      expect(unpinCalled, isTrue);
    });

    testWidgets('should show edit option when provided', (WidgetTester tester) async {
      // Arrange
      bool editCalled = false;
      void onEdit() {
        editCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onEdit: onEdit,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Edit class'), findsOneWidget);
      expect(find.text('Modify class details'), findsOneWidget);

      // Act
      await tester.tap(find.text('Edit class'));
      await tester.pump();

      // Assert
      expect(editCalled, isTrue);
    });

    testWidgets('should show delete option when provided', (WidgetTester tester) async {
      // Arrange
      bool deleteCalled = false;
      void onDelete() {
        deleteCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onDelete: onDelete,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Delete class'), findsOneWidget);
      expect(find.text('Remove class permanently'), findsOneWidget);

      // Act
      await tester.tap(find.text('Delete class'));
      await tester.pump();

      // Assert
      expect(deleteCalled, isTrue);
    });

    testWidgets('should call onCancel when cancel button is tapped', (WidgetTester tester) async {
      // Arrange
      bool cancelCalled = false;
      void onCancel() {
        cancelCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onCancel: onCancel,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Cancel'), findsOneWidget);

      // Act
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Assert
      expect(cancelCalled, isTrue);
    });

    testWidgets('should not show pin option when onPin is null', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onPin: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Pin to top'), findsNothing);
    });

    testWidgets('should not show unpin option when onUnpin is null', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: pinnedClass,
              onUnpin: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Unpin from top'), findsNothing);
    });

    testWidgets('should not show edit option when onEdit is null', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onEdit: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Edit class'), findsNothing);
    });

    testWidgets('should not show delete option when onDelete is null', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onDelete: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Delete class'), findsNothing);
    });

    testWidgets('should show all options when all callbacks are provided', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onPin: () {},
              onEdit: () {},
              onDelete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Pin to top'), findsOneWidget);
      expect(find.text('Edit class'), findsOneWidget);
      expect(find.text('Delete class'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should have proper styling for destructive action', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: unpinnedClass,
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert - The delete option should be styled differently
      expect(find.text('Delete class'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should show context menu using static show method', (WidgetTester tester) async {
      // Arrange
      bool pinCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  PinContextMenu.show(
                    context: context,
                    classItem: unpinnedClass,
                    onPin: () => pinCalled = true,
                  );
                },
                child: const Text('Show Menu'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PinContextMenu), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Pin to top'), findsOneWidget);

      // Test pin action
      await tester.tap(find.text('Pin to top'));
      await tester.pumpAndSettle();

      expect(pinCalled, isTrue);
      expect(find.byType(PinContextMenu), findsNothing); // Dialog should be closed
    });

    testWidgets('should close dialog when tapping outside', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  PinContextMenu.show(
                    context: context,
                    classItem: unpinnedClass,
                  );
                },
                child: const Text('Show Menu'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.byType(PinContextMenu), findsOneWidget);

      // Tap outside the dialog
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PinContextMenu), findsNothing);
    });
  });
}