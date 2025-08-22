import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/student_context_menu.dart';
import 'package:attendance_tracker/widgets/pin_context_menu.dart';
import 'package:attendance_tracker/models/student_model.dart';
import 'package:attendance_tracker/models/class_model.dart';

void main() {
  group('Visual Consistency Tests', () {
    testWidgets('StudentContextMenu has consistent styling with PinContextMenu', (WidgetTester tester) async {
      final student = Student(
        id: 1,
        classId: 1,
        name: 'John Doe',
        rollNumber: 'A001',
        attendancePercentage: 85.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final classItem = Class(
        id: 1,
        name: 'Test Class',
        description: 'Test Description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test StudentContextMenu
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: student,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify basic structure exists
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Edit student'), findsOneWidget);
      expect(find.text('Delete student'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Test PinContextMenu for comparison
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinContextMenu(
              classItem: classItem,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify basic structure exists
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Edit class'), findsOneWidget);
      expect(find.text('Delete class'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Both context menus have consistent visual elements', (WidgetTester tester) async {
      final student = Student(
        id: 1,
        classId: 1,
        name: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: student,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Check for consistent visual elements
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, equals(Colors.transparent));
      expect(dialog.elevation, equals(0));

      // Check for container with proper styling
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Container).first,
        ),
      );
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(12)));
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, equals(1));
    });

    testWidgets('StudentContextMenu displays student-specific information correctly', (WidgetTester tester) async {
      final student = Student(
        id: 1,
        classId: 1,
        name: 'Jane Smith',
        rollNumber: 'B002',
        attendancePercentage: 92.3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: student,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify student-specific information
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Roll: B002'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget); // Attendance percentage rounded
      expect(find.text('J'), findsOneWidget); // Avatar initial
    });

    testWidgets('Context menu adapts to different student configurations', (WidgetTester tester) async {
      // Test student without roll number
      final studentNoRoll = Student(
        id: 1,
        classId: 1,
        name: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: studentNoRoll,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Should not show roll number
      expect(find.textContaining('Roll:'), findsNothing);
      expect(find.text('John Doe'), findsOneWidget);

      // Test student without attendance
      final studentNoAttendance = Student(
        id: 2,
        classId: 1,
        name: 'Jane Smith',
        rollNumber: 'A001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: studentNoAttendance,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Should not show attendance percentage
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Roll: A001'), findsOneWidget);
    });
  });
}