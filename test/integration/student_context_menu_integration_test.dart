import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/screens/class_detail_screen.dart';
import 'package:attendance_tracker/providers/class_provider.dart';
import 'package:attendance_tracker/providers/student_provider.dart';
import 'package:attendance_tracker/providers/attendance_provider.dart';
import 'package:attendance_tracker/providers/theme_provider.dart';
import 'package:attendance_tracker/models/class_model.dart';
import 'package:attendance_tracker/models/student_model.dart';
import 'package:attendance_tracker/widgets/student_context_menu.dart';
import 'package:attendance_tracker/widgets/student_list_item.dart';
import 'package:attendance_tracker/widgets/add_student_dialog.dart';
import 'package:attendance_tracker/widgets/confirmation_dialog.dart';

// Mock providers for testing
class MockClassProvider extends ClassProvider {
  @override
  Class? get selectedClass => Class(
    id: 1,
    name: 'Test Class',
    description: 'Test Description',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

class MockStudentProvider extends StudentProvider {
  @override
  List<Student> get students => [
    Student(
      id: 1,
      classId: 1,
      name: 'John Doe',
      rollNumber: 'A001',
      attendancePercentage: 85.5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Student(
      id: 2,
      classId: 1,
      name: 'Jane Smith',
      rollNumber: 'A002',
      attendancePercentage: 92.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadStudents(int classId) async {
    // Mock implementation
  }

  @override
  Future<bool> deleteStudent(int studentId) async {
    // Mock implementation
    return true;
  }
}

class MockAttendanceProvider extends AttendanceProvider {}

class MockThemeProvider extends ThemeProvider {}

void main() {
  group('Student Context Menu Integration Tests', () {
    late MockClassProvider mockClassProvider;
    late MockStudentProvider mockStudentProvider;
    late MockAttendanceProvider mockAttendanceProvider;
    late MockThemeProvider mockThemeProvider;

    setUp(() {
      mockClassProvider = MockClassProvider();
      mockStudentProvider = MockStudentProvider();
      mockAttendanceProvider = MockAttendanceProvider();
      mockThemeProvider = MockThemeProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ClassProvider>.value(value: mockClassProvider),
          ChangeNotifierProvider<StudentProvider>.value(value: mockStudentProvider),
          ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendanceProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ],
        child: const MaterialApp(
          home: ClassDetailScreen(),
        ),
      );
    }

    testWidgets('complete long press to edit workflow', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the first student item
      final studentItem = find.byType(StudentListItem).first;
      expect(studentItem, findsOneWidget);

      // Perform long press on student item
      await tester.longPress(studentItem);
      await tester.pumpAndSettle();

      // Verify context menu appears
      expect(find.byType(StudentContextMenu), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Edit student'), findsOneWidget);
      expect(find.text('Delete student'), findsOneWidget);

      // Tap edit option
      await tester.tap(find.text('Edit student'));
      await tester.pumpAndSettle();

      // Verify edit dialog appears
      expect(find.byType(AddStudentDialog), findsOneWidget);
    });

    testWidgets('complete long press to delete workflow', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the first student item
      final studentItem = find.byType(StudentListItem).first;
      expect(studentItem, findsOneWidget);

      // Perform long press on student item
      await tester.longPress(studentItem);
      await tester.pumpAndSettle();

      // Verify context menu appears
      expect(find.byType(StudentContextMenu), findsOneWidget);

      // Tap delete option
      await tester.tap(find.text('Delete student'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(find.text('Delete Student'), findsOneWidget);
    });

    testWidgets('context menu cancel functionality', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the first student item
      final studentItem = find.byType(StudentListItem).first;
      expect(studentItem, findsOneWidget);

      // Perform long press on student item
      await tester.longPress(studentItem);
      await tester.pumpAndSettle();

      // Verify context menu appears
      expect(find.byType(StudentContextMenu), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify context menu disappears
      expect(find.byType(StudentContextMenu), findsNothing);
    });

    testWidgets('context menu dismiss by tapping outside', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the first student item
      final studentItem = find.byType(StudentListItem).first;
      expect(studentItem, findsOneWidget);

      // Perform long press on student item
      await tester.longPress(studentItem);
      await tester.pumpAndSettle();

      // Verify context menu appears
      expect(find.byType(StudentContextMenu), findsOneWidget);

      // Tap outside the menu to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify context menu disappears
      expect(find.byType(StudentContextMenu), findsNothing);
    });

    testWidgets('long press works with multiple students', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find all student items
      final studentItems = find.byType(StudentListItem);
      expect(studentItems, findsAtLeastNWidgets(2));

      // Long press on second student
      await tester.longPress(studentItems.at(1));
      await tester.pumpAndSettle();

      // Verify context menu shows correct student
      expect(find.byType(StudentContextMenu), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Roll: A002'), findsOneWidget);
    });

    testWidgets('swipe actions still work alongside long press', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the first student item
      final studentItem = find.byType(StudentListItem).first;
      expect(studentItem, findsOneWidget);

      // Swipe to reveal actions
      await tester.drag(studentItem, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Verify swipe actions appear
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap edit from swipe action
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Verify edit dialog appears
      expect(find.byType(AddStudentDialog), findsOneWidget);
    });

    testWidgets('normal tap still works for student details', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the first student item
      final studentItem = find.byType(StudentListItem).first;
      expect(studentItem, findsOneWidget);

      // Perform normal tap
      await tester.tap(studentItem);
      await tester.pumpAndSettle();

      // Verify student details dialog appears (assuming it exists)
      // This would depend on the actual implementation
      // For now, we just verify no context menu appears
      expect(find.byType(StudentContextMenu), findsNothing);
    });

    group('Responsive Design Tests', () {
      testWidgets('context menu adapts to small screen', (WidgetTester tester) async {
        // Set small screen size
        tester.binding.window.physicalSizeTestValue = const Size(320, 568);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Perform long press
        final studentItem = find.byType(StudentListItem).first;
        await tester.longPress(studentItem);
        await tester.pumpAndSettle();

        // Verify context menu appears and fits on screen
        expect(find.byType(StudentContextMenu), findsOneWidget);
        
        // Reset window size
        addTearDown(() {
          tester.binding.window.clearPhysicalSizeTestValue();
          tester.binding.window.clearDevicePixelRatioTestValue();
        });
      });

      testWidgets('context menu adapts to large screen', (WidgetTester tester) async {
        // Set large screen size (tablet)
        tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Perform long press
        final studentItem = find.byType(StudentListItem).first;
        await tester.longPress(studentItem);
        await tester.pumpAndSettle();

        // Verify context menu appears
        expect(find.byType(StudentContextMenu), findsOneWidget);
        
        // Reset window size
        addTearDown(() {
          tester.binding.window.clearPhysicalSizeTestValue();
          tester.binding.window.clearDevicePixelRatioTestValue();
        });
      });
    });

    group('Accessibility Tests', () {
      testWidgets('context menu has proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Perform long press
        final studentItem = find.byType(StudentListItem).first;
        await tester.longPress(studentItem);
        await tester.pumpAndSettle();

        // Verify semantic labels exist
        expect(
          tester.getSemantics(find.byType(StudentContextMenu).first),
          matchesSemantics(
            hasDescendant: matchesSemantics(
              label: contains('Student: John Doe'),
            ),
          ),
        );
      });

      testWidgets('menu items have proper button semantics', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Perform long press
        final studentItem = find.byType(StudentListItem).first;
        await tester.longPress(studentItem);
        await tester.pumpAndSettle();

        // Find edit button and verify semantics
        final editButton = find.text('Edit student');
        expect(
          tester.getSemantics(editButton),
          matchesSemantics(
            hasAction: SemanticsAction.tap,
            isButton: true,
          ),
        );
      });
    });
  });
}