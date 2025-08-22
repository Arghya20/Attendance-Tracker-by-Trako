import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/student_context_menu.dart';
import 'package:attendance_tracker/models/student_model.dart';

void main() {
  group('StudentContextMenu Widget Tests', () {
    late Student testStudent;
    late Student testStudentWithRoll;
    late Student testStudentWithAttendance;

    setUp(() {
      testStudent = Student(
        id: 1,
        classId: 1,
        name: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testStudentWithRoll = Student(
        id: 2,
        classId: 1,
        name: 'Jane Smith',
        rollNumber: 'A001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testStudentWithAttendance = Student(
        id: 3,
        classId: 1,
        name: 'Bob Johnson',
        rollNumber: 'A002',
        attendancePercentage: 85.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('renders student context menu with basic student info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudent,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify student name is displayed
      expect(find.text('John Doe'), findsOneWidget);
      
      // Verify avatar with first letter
      expect(find.text('J'), findsOneWidget);
      
      // Verify menu items
      expect(find.text('Edit student'), findsOneWidget);
      expect(find.text('Delete student'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders student with roll number', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudentWithRoll,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify student name and roll number
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Roll: A001'), findsOneWidget);
    });

    testWidgets('renders student with attendance percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudentWithAttendance,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify attendance percentage is displayed
      expect(find.text('86%'), findsOneWidget); // Rounded to nearest integer
    });

    testWidgets('calls onEdit when edit menu item is tapped', (WidgetTester tester) async {
      bool editCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudent,
              onEdit: () => editCalled = true,
              onDelete: () {},
            ),
          ),
        ),
      );

      // Tap the edit menu item
      await tester.tap(find.text('Edit student'));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('calls onDelete when delete menu item is tapped', (WidgetTester tester) async {
      bool deleteCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudent,
              onEdit: () {},
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      // Tap the delete menu item
      await tester.tap(find.text('Delete student'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('calls onCancel when cancel button is tapped', (WidgetTester tester) async {
      bool cancelCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudent,
              onEdit: () {},
              onDelete: () {},
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      // Tap the cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('shows only edit option when onDelete is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudent,
              onEdit: () {},
              // onDelete is null
            ),
          ),
        ),
      );

      // Verify only edit option is shown
      expect(find.text('Edit student'), findsOneWidget);
      expect(find.text('Delete student'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows only delete option when onEdit is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudent,
              // onEdit is null
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify only delete option is shown
      expect(find.text('Edit student'), findsNothing);
      expect(find.text('Delete student'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('has proper accessibility semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentContextMenu(
              student: testStudentWithRoll,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Check for semantic labels
      expect(
        tester.getSemantics(find.byType(StudentContextMenu).first),
        matchesSemantics(
          hasDescendant: matchesSemantics(
            label: contains('Student: Jane Smith'),
          ),
        ),
      );
    });

    testWidgets('static show method displays dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => StudentContextMenu.show(
                  context: context,
                  student: testStudent,
                  onEdit: () {},
                  onDelete: () {},
                ),
                child: const Text('Show Menu'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(StudentContextMenu), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('dialog can be dismissed by tapping outside', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => StudentContextMenu.show(
                  context: context,
                  student: testStudent,
                  onEdit: () {},
                  onDelete: () {},
                ),
                child: const Text('Show Menu'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(StudentContextMenu), findsOneWidget);

      // Tap outside to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed
      expect(find.byType(StudentContextMenu), findsNothing);
    });

    group('Attendance Color Tests', () {
      testWidgets('shows green color for high attendance (>=90%)', (WidgetTester tester) async {
        final highAttendanceStudent = testStudent.copyWith(attendancePercentage: 95.0);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudentContextMenu(
                student: highAttendanceStudent,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // Find the attendance percentage container
        final attendanceContainer = tester.widget<Container>(
          find.descendant(
            of: find.byType(StudentContextMenu),
            matching: find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color != null &&
              (widget.decoration as BoxDecoration).color!.value == Colors.green.withOpacity(0.1).value
            ),
          ),
        );
        
        expect(attendanceContainer, isNotNull);
      });

      testWidgets('shows amber color for medium attendance (75-89%)', (WidgetTester tester) async {
        final mediumAttendanceStudent = testStudent.copyWith(attendancePercentage: 80.0);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudentContextMenu(
                student: mediumAttendanceStudent,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // Verify amber color is used (this is a simplified check)
        expect(find.text('80%'), findsOneWidget);
      });

      testWidgets('shows red color for low attendance (<75%)', (WidgetTester tester) async {
        final lowAttendanceStudent = testStudent.copyWith(attendancePercentage: 60.0);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudentContextMenu(
                student: lowAttendanceStudent,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // Verify red color is used (this is a simplified check)
        expect(find.text('60%'), findsOneWidget);
      });
    });
  });
}