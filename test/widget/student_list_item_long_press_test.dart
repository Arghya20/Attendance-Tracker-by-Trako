import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/student_list_item.dart';
import 'package:attendance_tracker/models/student_model.dart';

void main() {
  group('StudentListItem Long Press Tests', () {
    late Student testStudent;

    setUp(() {
      testStudent = Student(
        id: 1,
        classId: 1,
        name: 'John Doe',
        rollNumber: 'A001',
        attendancePercentage: 85.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('calls onLongPress when long pressed', (WidgetTester tester) async {
      bool longPressCalled = false;
      bool tapCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentListItem(
              student: testStudent,
              onTap: () => tapCalled = true,
              onEdit: () {},
              onDelete: () {},
              onLongPress: () => longPressCalled = true,
            ),
          ),
        ),
      );

      // Perform long press
      await tester.longPress(find.byType(StudentListItem));
      await tester.pumpAndSettle();

      expect(longPressCalled, isTrue);
      expect(tapCalled, isFalse); // Ensure tap wasn't called
    });

    testWidgets('calls onTap when tapped normally', (WidgetTester tester) async {
      bool longPressCalled = false;
      bool tapCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentListItem(
              student: testStudent,
              onTap: () => tapCalled = true,
              onEdit: () {},
              onDelete: () {},
              onLongPress: () => longPressCalled = true,
            ),
          ),
        ),
      );

      // Perform normal tap
      await tester.tap(find.byType(StudentListItem));
      await tester.pumpAndSettle();

      expect(tapCalled, isTrue);
      expect(longPressCalled, isFalse); // Ensure long press wasn't called
    });

    testWidgets('does not crash when onLongPress is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentListItem(
              student: testStudent,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              // onLongPress is null
            ),
          ),
        ),
      );

      // Perform long press - should not crash
      await tester.longPress(find.byType(StudentListItem));
      await tester.pumpAndSettle();

      // Test passes if no exception is thrown
    });

    testWidgets('swipe actions still work with long press enabled', (WidgetTester tester) async {
      bool editCalled = false;
      bool deleteCalled = false;
      bool longPressCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentListItem(
              student: testStudent,
              onTap: () {},
              onEdit: () => editCalled = true,
              onDelete: () => deleteCalled = true,
              onLongPress: () => longPressCalled = true,
            ),
          ),
        ),
      );

      // Swipe to reveal actions
      await tester.drag(find.byType(StudentListItem), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Tap edit action
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
      expect(longPressCalled, isFalse);
    });

    testWidgets('long press and swipe do not interfere with each other', (WidgetTester tester) async {
      bool longPressCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentListItem(
              student: testStudent,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              onLongPress: () => longPressCalled = true,
            ),
          ),
        ),
      );

      // Start a drag gesture but don't complete it
      final gesture = await tester.startGesture(tester.getCenter(find.byType(StudentListItem)));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Now perform long press
      await gesture.up();
      await tester.longPress(find.byType(StudentListItem));
      await tester.pumpAndSettle();

      expect(longPressCalled, isTrue);
    });

    testWidgets('has proper touch targets for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentListItem(
              student: testStudent,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
              onLongPress: () {},
            ),
          ),
        ),
      );

      // Verify the widget has adequate size for touch interaction
      final studentListItem = tester.getSize(find.byType(StudentListItem));
      expect(studentListItem.height, greaterThan(48)); // Minimum touch target
    });

    group('Gesture Recognition Tests', () {
      testWidgets('distinguishes between tap and long press correctly', (WidgetTester tester) async {
        bool tapCalled = false;
        bool longPressCalled = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudentListItem(
                student: testStudent,
                onTap: () => tapCalled = true,
                onEdit: () {},
                onDelete: () {},
                onLongPress: () => longPressCalled = true,
              ),
            ),
          ),
        );

        // Quick tap
        await tester.tap(find.byType(StudentListItem));
        await tester.pumpAndSettle();
        
        expect(tapCalled, isTrue);
        expect(longPressCalled, isFalse);
        
        // Reset flags
        tapCalled = false;
        longPressCalled = false;
        
        // Long press
        await tester.longPress(find.byType(StudentListItem));
        await tester.pumpAndSettle();
        
        expect(tapCalled, isFalse);
        expect(longPressCalled, isTrue);
      });

      testWidgets('handles multiple rapid taps correctly', (WidgetTester tester) async {
        int tapCount = 0;
        int longPressCount = 0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudentListItem(
                student: testStudent,
                onTap: () => tapCount++,
                onEdit: () {},
                onDelete: () {},
                onLongPress: () => longPressCount++,
              ),
            ),
          ),
        );

        // Multiple rapid taps
        await tester.tap(find.byType(StudentListItem));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(StudentListItem));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(StudentListItem));
        await tester.pumpAndSettle();
        
        expect(tapCount, equals(3));
        expect(longPressCount, equals(0));
      });
    });
  });
}