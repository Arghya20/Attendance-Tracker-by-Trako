import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/models/models.dart';

void main() {
  group('MonthAttendanceData', () {
    late List<Student> testStudents;
    late List<DateTime> testAttendanceDays;
    late Map<int, Map<DateTime, bool>> testAttendanceMatrix;
    late Map<int, double> testAttendancePercentages;
    late DateTime testMonth;

    setUp(() {
      testMonth = DateTime(2024, 8);
      
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

      testAttendanceDays = [
        DateTime(2024, 8, 1),
        DateTime(2024, 8, 2),
        DateTime(2024, 8, 3),
        DateTime(2024, 8, 4),
        DateTime(2024, 8, 5),
      ];

      testAttendanceMatrix = {
        1: {
          DateTime(2024, 8, 1): true,
          DateTime(2024, 8, 2): false,
          DateTime(2024, 8, 3): true,
          DateTime(2024, 8, 4): true,
          DateTime(2024, 8, 5): true,
        },
        2: {
          DateTime(2024, 8, 1): false,
          DateTime(2024, 8, 2): false,
          DateTime(2024, 8, 3): false,
          DateTime(2024, 8, 4): false,
          DateTime(2024, 8, 5): false,
        },
      };

      testAttendancePercentages = {
        1: 80.0,
        2: 0.0,
      };
    });

    test('should create MonthAttendanceData with all properties', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(monthData.month, equals(testMonth));
      expect(monthData.students, equals(testStudents));
      expect(monthData.attendanceDays, equals(testAttendanceDays));
      expect(monthData.attendanceMatrix, equals(testAttendanceMatrix));
      expect(monthData.attendancePercentages, equals(testAttendancePercentages));
    });

    test('should get attendance status for specific student and date', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(monthData.getAttendanceStatus(1, DateTime(2024, 8, 1)), isTrue);
      expect(monthData.getAttendanceStatus(1, DateTime(2024, 8, 2)), isFalse);
      expect(monthData.getAttendanceStatus(2, DateTime(2024, 8, 1)), isFalse);
      expect(monthData.getAttendanceStatus(3, DateTime(2024, 8, 1)), isNull);
    });

    test('should get attendance percentage for specific student', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(monthData.getAttendancePercentage(1), equals(80.0));
      expect(monthData.getAttendancePercentage(2), equals(0.0));
      expect(monthData.getAttendancePercentage(3), equals(0.0));
    });

    test('should get present count for specific student', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(monthData.getPresentCount(1), equals(4));
      expect(monthData.getPresentCount(2), equals(0));
      expect(monthData.getPresentCount(3), equals(0));
    });

    test('should get absent count for specific student', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(monthData.getAbsentCount(1), equals(1));
      expect(monthData.getAbsentCount(2), equals(5));
      expect(monthData.getAbsentCount(3), equals(0));
    });

    test('should get total attendance days for specific student', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(monthData.getTotalAttendanceDays(1), equals(5));
      expect(monthData.getTotalAttendanceDays(2), equals(5));
      expect(monthData.getTotalAttendanceDays(3), equals(0));
    });

    test('should calculate attendance percentage correctly', () {
      expect(MonthAttendanceData.calculateAttendancePercentage(4, 5), equals(80.0));
      expect(MonthAttendanceData.calculateAttendancePercentage(0, 5), equals(0.0));
      expect(MonthAttendanceData.calculateAttendancePercentage(5, 5), equals(100.0));
      expect(MonthAttendanceData.calculateAttendancePercentage(0, 0), equals(0.0));
    });

    test('should create empty MonthAttendanceData', () {
      final emptyData = MonthAttendanceData.empty(testMonth);

      expect(emptyData.month, equals(testMonth));
      expect(emptyData.students, isEmpty);
      expect(emptyData.attendanceDays, isEmpty);
      expect(emptyData.attendanceMatrix, isEmpty);
      expect(emptyData.attendancePercentages, isEmpty);
      expect(emptyData.isEmpty, isTrue);
    });

    test('should check if data is empty', () {
      final emptyData = MonthAttendanceData.empty(testMonth);
      final nonEmptyData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(emptyData.isEmpty, isTrue);
      expect(nonEmptyData.isEmpty, isFalse);
    });

    test('should get student count', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(monthData.studentCount, equals(2));
    });

    test('should get attendance day count', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      expect(monthData.attendanceDayCount, equals(5));
    });

    test('should create copy with modified properties', () {
      final originalData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      final newMonth = DateTime(2024, 9);
      final copiedData = originalData.copyWith(month: newMonth);

      expect(copiedData.month, equals(newMonth));
      expect(copiedData.students, equals(testStudents));
      expect(copiedData.attendanceDays, equals(testAttendanceDays));
    });

    test('should serialize to and from Map correctly', () {
      final originalData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      final map = originalData.toMap();
      final deserializedData = MonthAttendanceData.fromMap(map);

      expect(deserializedData.month, equals(originalData.month));
      expect(deserializedData.students.length, equals(originalData.students.length));
      expect(deserializedData.attendanceDays.length, equals(originalData.attendanceDays.length));
      expect(deserializedData.attendanceMatrix.length, equals(originalData.attendanceMatrix.length));
      expect(deserializedData.attendancePercentages, equals(originalData.attendancePercentages));
    });

    test('should have correct toString representation', () {
      final monthData = MonthAttendanceData(
        month: testMonth,
        students: testStudents,
        attendanceDays: testAttendanceDays,
        attendanceMatrix: testAttendanceMatrix,
        attendancePercentages: testAttendancePercentages,
      );

      final stringRepresentation = monthData.toString();
      expect(stringRepresentation, contains('MonthAttendanceData'));
      expect(stringRepresentation, contains('month: $testMonth'));
      expect(stringRepresentation, contains('students: 2'));
      expect(stringRepresentation, contains('attendanceDays: 5'));
    });
  });
}