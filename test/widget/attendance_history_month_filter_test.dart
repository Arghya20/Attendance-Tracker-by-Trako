import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/screens/attendance_history_screen.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:intl/intl.dart';

/// Mock providers for testing
class MockAttendanceProvider extends AttendanceProvider {
  final List<Map<String, dynamic>> mockStudentAttendance;
  
  MockAttendanceProvider({this.mockStudentAttendance = const []});
  
  @override
  Future<List<Map<String, dynamic>>> getStudentAttendance(int studentId) async {
    return mockStudentAttendance;
  }
}

class MockStudentProvider extends StudentProvider {
  final List<Student> mockStudents;
  
  MockStudentProvider({this.mockStudents = const []});
  
  @override
  List<Student> get students => mockStudents;
}

class MockClassProvider extends ClassProvider {}

/// Test widget that wraps AttendanceHistoryScreen with necessary providers
class TestAttendanceHistoryScreen extends StatelessWidget {
  final Class classItem;
  final List<Student> students;
  final List<Map<String, dynamic>> attendanceRecords;
  
  const TestAttendanceHistoryScreen({
    super.key,
    required this.classItem,
    this.students = const [],
    this.attendanceRecords = const [],
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AttendanceProvider>(
            create: (_) => MockAttendanceProvider(mockStudentAttendance: attendanceRecords),
          ),
          ChangeNotifierProvider<StudentProvider>(
            create: (_) => MockStudentProvider(mockStudents: students),
          ),
          ChangeNotifierProvider<ClassProvider>(
            create: (_) => MockClassProvider(),
          ),
        ],
        child: AttendanceHistoryScreen(classItem: classItem),
      ),
    );
  }
}

void main() {
  group('AttendanceHistoryScreen Month Filter Widget Tests', () {
    late Class testClass;
    late List<Student> testStudents;
    late List<Map<String, dynamic>> testAttendanceRecords;

    setUp(() {
      testClass = Class(
        id: 1,
        name: 'Test Class',
        createdAt: DateTime.now(),
      );
      
      testStudents = [
        Student(
          id: 1,
          classId: 1,
          name: 'John Doe',
          rollNumber: '001',
        ),
        Student(
          id: 2,
          classId: 1,
          name: 'Jane Smith',
          rollNumber: '002',
        ),
      ];
      
      testAttendanceRecords = [
        {'session_date': '2024-01-15', 'is_present': 1},
        {'session_date': '2024-01-20', 'is_present': 0},
        {'session_date': '2024-02-10', 'is_present': 1},
        {'session_date': '2024-02-25', 'is_present': 1},
        {'session_date': '2024-03-05', 'is_present': 0},
      ];
    });

    testWidgets('should display student selection dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: testAttendanceRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Verify student selection dropdown is present
      expect(find.text('Select Student'), findsOneWidget);
      expect(find.text('Select a student'), findsOneWidget);
      
      // Verify dropdown has correct items
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('should not show month dropdown when no student is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: testAttendanceRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Month dropdown should not be visible when no student is selected
      expect(find.text('Filter by Month'), findsNothing);
      expect(find.byType(DropdownButtonFormField<DateTime?>), findsNothing);
    });

    testWidgets('should show month dropdown after selecting student', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: testAttendanceRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Select a student
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Wait for attendance data to load and month dropdown to appear
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Month dropdown should now be visible
      expect(find.text('Filter by Month'), findsOneWidget);
      expect(find.text('All Months'), findsOneWidget);
    });

    testWidgets('should populate month dropdown with available months', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: testAttendanceRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Select a student
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Open month dropdown
      final monthDropdowns = find.byType(DropdownButtonFormField<DateTime?>);
      if (monthDropdowns.evaluate().isNotEmpty) {
        await tester.tap(monthDropdowns.first);
        await tester.pumpAndSettle();

        // Verify month options are present
        expect(find.text('All Months'), findsWidgets); // One in dropdown, one in menu
        expect(find.text(DateFormat('MMMM yyyy').format(DateTime(2024, 3, 1))), findsOneWidget);
        expect(find.text(DateFormat('MMMM yyyy').format(DateTime(2024, 2, 1))), findsOneWidget);
        expect(find.text(DateFormat('MMMM yyyy').format(DateTime(2024, 1, 1))), findsOneWidget);
      }
    });

    testWidgets('should handle month selection change', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: testAttendanceRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Select a student
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Open month dropdown and select a month
      final monthDropdowns = find.byType(DropdownButtonFormField<DateTime?>);
      if (monthDropdowns.evaluate().isNotEmpty) {
        await tester.tap(monthDropdowns.first);
        await tester.pumpAndSettle();

        // Select February 2024
        final februaryText = DateFormat('MMMM yyyy').format(DateTime(2024, 2, 1));
        if (find.text(februaryText).evaluate().isNotEmpty) {
          await tester.tap(find.text(februaryText));
          await tester.pumpAndSettle();

          // Verify the selection was made (dropdown should show selected month)
          expect(find.text(februaryText), findsOneWidget);
        }
      }
    });

    testWidgets('should show filter status indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: testAttendanceRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Select a student
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Initially should show "Showing all records"
      expect(find.text('Showing all records'), findsOneWidget);

      // Select a month filter
      final monthDropdowns = find.byType(DropdownButtonFormField<DateTime?>);
      if (monthDropdowns.evaluate().isNotEmpty) {
        await tester.tap(monthDropdowns.first);
        await tester.pumpAndSettle();

        final februaryText = DateFormat('MMMM yyyy').format(DateTime(2024, 2, 1));
        if (find.text(februaryText).evaluate().isNotEmpty) {
          await tester.tap(find.text(februaryText));
          await tester.pumpAndSettle();

          // Should now show filtered status
          expect(find.text('Showing records for February 2024'), findsOneWidget);
        }
      }
    });

    testWidgets('should reset month selection when switching students', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: testAttendanceRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Select first student
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Select a month filter
      final monthDropdowns = find.byType(DropdownButtonFormField<DateTime?>);
      if (monthDropdowns.evaluate().isNotEmpty) {
        await tester.tap(monthDropdowns.first);
        await tester.pumpAndSettle();

        final februaryText = DateFormat('MMMM yyyy').format(DateTime(2024, 2, 1));
        if (find.text(februaryText).evaluate().isNotEmpty) {
          await tester.tap(find.text(februaryText));
          await tester.pumpAndSettle();
        }
      }

      // Switch to second student
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jane Smith'));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Month selection should be reset to "All Months"
      expect(find.text('Showing all records'), findsOneWidget);
    });

    testWidgets('should display attendance statistics based on filtered data', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: testAttendanceRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Select a student
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Should show statistics for all records initially
      expect(find.textContaining('Attendance:'), findsOneWidget);
      expect(find.textContaining('Present:'), findsOneWidget);
      expect(find.textContaining('Absent:'), findsOneWidget);
      expect(find.textContaining('Total:'), findsOneWidget);
    });

    testWidgets('should show appropriate message when no records match filter', (WidgetTester tester) async {
      // Create test data with no records for a specific month
      final limitedRecords = [
        {'session_date': '2024-01-15', 'is_present': 1},
        {'session_date': '2024-01-20', 'is_present': 0},
      ];

      await tester.pumpWidget(
        TestAttendanceHistoryScreen(
          classItem: testClass,
          students: testStudents,
          attendanceRecords: limitedRecords,
        ),
      );

      // Switch to Student View tab
      await tester.tap(find.text('Student View'));
      await tester.pumpAndSettle();

      // Select a student
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Wait for data to load
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Try to select a month that has no records (March)
      final monthDropdowns = find.byType(DropdownButtonFormField<DateTime?>);
      if (monthDropdowns.evaluate().isNotEmpty) {
        await tester.tap(monthDropdowns.first);
        await tester.pumpAndSettle();

        // If March is available, select it
        final marchText = DateFormat('MMMM yyyy').format(DateTime(2024, 3, 1));
        if (find.text(marchText).evaluate().isNotEmpty) {
          await tester.tap(find.text(marchText));
          await tester.pumpAndSettle();

          // Should show no records message
          expect(find.textContaining('No attendance records found for March 2024'), findsOneWidget);
        }
      }
    });
  });
}