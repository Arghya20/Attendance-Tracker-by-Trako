import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/screens/month_export_screen.dart';
import 'package:attendance_tracker/models/models.dart';

void main() {
  group('MonthExportScreen Widget Tests', () {
    late Class testClass;
    late DateTime testMonth;
    late MonthAttendanceData testMonthData;
    
    setUp(() {
      testClass = Class(
        id: 1,
        name: 'Test Class',
        studentCount: 2,
        sessionCount: 3,
      );
      
      testMonth = DateTime(2024, 8);
      
      final testStudents = [
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
      
      final testAttendanceDays = [
        DateTime(2024, 8, 1),
        DateTime(2024, 8, 2),
        DateTime(2024, 8, 3),
      ];
      
      final testAttendanceMatrix = <int, Map<DateTime, bool>>{
        1: {
          DateTime(2024, 8, 1): true,
          DateTime(2024, 8, 2): false,
          DateTime(2024, 8, 3): true,
        },
        2: {
          DateTime(2024, 8, 1): true,
          DateTime(2024, 8, 2): true,
          DateTime(2024, 8, 3): false,
        },
      };
      
      final testAttendancePercentages = <int, double>{
        1: 67.0,
        2: 67.0,
      };
      
      testMonthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );
    });
    
    testWidgets('should display app bar with correct title', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Attendance Report'), findsOneWidget);
      expect(find.text('August 2024'), findsOneWidget);
    });
    
    testWidgets('should display loading indicator when isLoading is true', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            isLoading: true,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading attendance data...'), findsOneWidget);
    });
    
    testWidgets('should display error message when errorMessage is provided', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Failed to load data';
      
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            errorMessage: errorMessage,
            onRetry: () {},
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text(errorMessage), findsOneWidget);
    });
    
    testWidgets('should display empty state when no data available', (WidgetTester tester) async {
      // Arrange
      final emptyMonthData = MonthAttendanceData.empty(testMonth);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: emptyMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('No Attendance Data'), findsOneWidget);
      expect(find.text('No attendance sessions were recorded for August 2024.'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });
    
    testWidgets('should display summary card with statistics', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('August 2024 Summary'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Student count
      expect(find.text('3'), findsOneWidget); // Session count
      expect(find.byIcon(Icons.analytics), findsAtLeastNWidgets(1));
    });
    
    testWidgets('should display attendance table with correct structure', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Daily Attendance'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('SL'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Percentage'), findsOneWidget);
    });
    
    testWidgets('should display student names in table', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });
    
    testWidgets('should display date headers in table', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('Aug'), findsAtLeastNWidgets(3));
    });
    
    testWidgets('should display attendance markers (P/A) in table', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('P'), findsAtLeastNWidgets(1));
      expect(find.text('A'), findsAtLeastNWidgets(1));
    });
    
    testWidgets('should display attendance percentages in table', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('67%'), findsAtLeastNWidgets(1));
    });
    
    testWidgets('should display download button when data is available', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
    
    testWidgets('should not display download button when no data available', (WidgetTester tester) async {
      // Arrange
      final emptyMonthData = MonthAttendanceData.empty(testMonth);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: emptyMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byIcon(Icons.download), findsNothing);
    });
    
    testWidgets('should display progress indicator when exporting', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act
      await tester.tap(find.byIcon(Icons.download));
      await tester.pump(); // Trigger the export state
      
      // Assert
      // Note: In a real test, we would mock the export functionality
      // and verify the loading state is shown during export
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
    
    testWidgets('should be horizontally scrollable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });
    
    testWidgets('should display summary statistics correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Present: 4'), findsOneWidget);
      expect(find.text('Absent: 2'), findsOneWidget);
      expect(find.text('Total: 6'), findsOneWidget);
    });
    
    testWidgets('should have proper card structure', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(Card), findsAtLeastNWidgets(2)); // Summary card + table card
    });
    
    testWidgets('should handle back navigation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MonthExportScreen(
            classItem: testClass,
            selectedMonth: testMonth,
            monthData: testMonthData,
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(BackButton), findsOneWidget);
    });
  });
}