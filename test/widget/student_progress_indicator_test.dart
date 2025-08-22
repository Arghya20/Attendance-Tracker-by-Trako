import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/student_list_item.dart';
import 'package:attendance_tracker/models/models.dart';

void main() {
  group('Student Progress Indicator Tests', () {
    late Student testStudent;

    setUp(() {
      testStudent = Student(
        id: 1,
        classId: 1,
        name: 'Test Student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attendancePercentage: 80.0,
      );
    });

    Widget createTestWidget(Student student) {
      return MaterialApp(
        home: Scaffold(
          body: StudentListItem(
            student: student,
            onTap: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      );
    }

    testWidgets('should display correct attendance percentage', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(testStudent));

      // Assert
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show green color for high attendance (>=90%)', (tester) async {
      // Arrange
      final highAttendanceStudent = testStudent.copyWith(attendancePercentage: 95.0);

      // Act
      await tester.pumpWidget(createTestWidget(highAttendanceStudent));

      // Assert
      expect(find.text('95.0%'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Find the progress indicator and verify color
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.valueColor?.value, equals(Colors.green));
    });

    testWidgets('should show amber color for medium attendance (75-89%)', (tester) async {
      // Arrange
      final mediumAttendanceStudent = testStudent.copyWith(attendancePercentage: 80.0);

      // Act
      await tester.pumpWidget(createTestWidget(mediumAttendanceStudent));

      // Assert
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);

      // Find the progress indicator and verify color
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.valueColor?.value, equals(Colors.amber.shade700));
    });

    testWidgets('should show red color for low attendance (<75%)', (tester) async {
      // Arrange
      final lowAttendanceStudent = testStudent.copyWith(attendancePercentage: 60.0);

      // Act
      await tester.pumpWidget(createTestWidget(lowAttendanceStudent));

      // Assert
      expect(find.text('60.0%'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Find the progress indicator and verify color
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.valueColor?.value, equals(Colors.red));
    });

    testWidgets('should handle null attendance percentage', (tester) async {
      // Arrange
      final nullAttendanceStudent = testStudent.copyWith(attendancePercentage: null);

      // Act
      await tester.pumpWidget(createTestWidget(nullAttendanceStudent));

      // Assert
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Find the progress indicator and verify it shows 0%
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.value, equals(0.0));
    });

    testWidgets('should update when attendance percentage changes', (tester) async {
      // Arrange - initial state
      await tester.pumpWidget(createTestWidget(testStudent));
      expect(find.text('80.0%'), findsOneWidget);

      // Act - update with new percentage
      final updatedStudent = testStudent.copyWith(attendancePercentage: 90.0);
      await tester.pumpWidget(createTestWidget(updatedStudent));

      // Assert
      expect(find.text('90.0%'), findsOneWidget);
      expect(find.text('80.0%'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show correct progress indicator value', (tester) async {
      // Arrange
      final student75 = testStudent.copyWith(attendancePercentage: 75.0);

      // Act
      await tester.pumpWidget(createTestWidget(student75));

      // Assert
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.value, equals(0.75)); // 75% as decimal
    });

    testWidgets('should handle edge case percentages correctly', (tester) async {
      // Test 0%
      final student0 = testStudent.copyWith(attendancePercentage: 0.0);
      await tester.pumpWidget(createTestWidget(student0));
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Test 100%
      final student100 = testStudent.copyWith(attendancePercentage: 100.0);
      await tester.pumpWidget(createTestWidget(student100));
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should maintain consistent sizing', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(testStudent));

      // Assert
      final progressIndicatorWidget = find.byType(CircularProgressIndicator);
      expect(progressIndicatorWidget, findsOneWidget);

      final progressIndicator = tester.widget<CircularProgressIndicator>(progressIndicatorWidget);
      expect(progressIndicator.strokeWidth, equals(4.0));

      // Check the container size
      final sizedBox = find.ancestor(
        of: progressIndicatorWidget,
        matching: find.byType(SizedBox),
      ).first;
      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
      expect(sizedBoxWidget.width, equals(40.0));
      expect(sizedBoxWidget.height, equals(40.0));
    });
  });
}