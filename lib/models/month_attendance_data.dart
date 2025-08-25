import 'package:attendance_tracker/models/student_model.dart';

class MonthAttendanceData {
  final DateTime month;
  final List<Student> students;
  final List<DateTime> attendanceDays;
  final Map<int, Map<DateTime, bool>> attendanceMatrix; // studentId -> date -> isPresent
  final Map<int, double> attendancePercentages; // studentId -> percentage
  
  MonthAttendanceData({
    required this.month,
    required this.students,
    required this.attendanceDays,
    required this.attendanceMatrix,
    required this.attendancePercentages,
  });
  
  // Create a copy of this MonthAttendanceData with the given fields replaced
  MonthAttendanceData copyWith({
    DateTime? month,
    List<Student>? students,
    List<DateTime>? attendanceDays,
    Map<int, Map<DateTime, bool>>? attendanceMatrix,
    Map<int, double>? attendancePercentages,
  }) {
    return MonthAttendanceData(
      month: month ?? this.month,
      students: students ?? this.students,
      attendanceDays: attendanceDays ?? this.attendanceDays,
      attendanceMatrix: attendanceMatrix ?? this.attendanceMatrix,
      attendancePercentages: attendancePercentages ?? this.attendancePercentages,
    );
  }
  
  // Get attendance status for a specific student on a specific date
  bool? getAttendanceStatus(int studentId, DateTime date) {
    return attendanceMatrix[studentId]?[date];
  }
  
  // Get attendance percentage for a specific student
  double getAttendancePercentage(int studentId) {
    return attendancePercentages[studentId] ?? 0.0;
  }
  
  // Get present count for a specific student
  int getPresentCount(int studentId) {
    final studentAttendance = attendanceMatrix[studentId];
    if (studentAttendance == null) return 0;
    
    return studentAttendance.values.where((isPresent) => isPresent == true).length;
  }
  
  // Get absent count for a specific student
  int getAbsentCount(int studentId) {
    final studentAttendance = attendanceMatrix[studentId];
    if (studentAttendance == null) return 0;
    
    return studentAttendance.values.where((isPresent) => isPresent == false).length;
  }
  
  // Get total attendance days for a specific student (excluding null values)
  int getTotalAttendanceDays(int studentId) {
    final studentAttendance = attendanceMatrix[studentId];
    if (studentAttendance == null) return 0;
    
    return studentAttendance.values.where((isPresent) => isPresent != null).length;
  }
  
  // Calculate attendance percentage for a student
  static double calculateAttendancePercentage(int presentCount, int totalDays) {
    if (totalDays == 0) return 0.0;
    return (presentCount / totalDays) * 100;
  }
  
  // Convert MonthAttendanceData instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'month': month.toIso8601String(),
      'students': students.map((student) => student.toMap()).toList(),
      'attendance_days': attendanceDays.map((date) => date.toIso8601String()).toList(),
      'attendance_matrix': _attendanceMatrixToMap(),
      'attendance_percentages': attendancePercentages,
    };
  }
  
  // Helper method to convert attendance matrix to serializable format
  Map<String, dynamic> _attendanceMatrixToMap() {
    final Map<String, dynamic> result = {};
    
    attendanceMatrix.forEach((studentId, dateMap) {
      final Map<String, bool?> serializedDateMap = {};
      dateMap.forEach((date, isPresent) {
        serializedDateMap[date.toIso8601String()] = isPresent;
      });
      result[studentId.toString()] = serializedDateMap;
    });
    
    return result;
  }
  
  // Create a MonthAttendanceData instance from a Map
  factory MonthAttendanceData.fromMap(Map<String, dynamic> map) {
    final students = (map['students'] as List<dynamic>)
        .map((studentMap) => Student.fromMap(studentMap as Map<String, dynamic>))
        .toList();
    
    final attendanceDays = (map['attendance_days'] as List<dynamic>)
        .map((dateStr) => DateTime.parse(dateStr as String))
        .toList();
    
    final attendancePercentages = Map<int, double>.from(
      (map['attendance_percentages'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), value.toDouble()),
      ),
    );
    
    final attendanceMatrix = _attendanceMatrixFromMap(
      map['attendance_matrix'] as Map<String, dynamic>,
    );
    
    return MonthAttendanceData(
      month: DateTime.parse(map['month'] as String),
      students: students,
      attendanceDays: attendanceDays,
      attendanceMatrix: attendanceMatrix,
      attendancePercentages: attendancePercentages,
    );
  }
  
  // Helper method to convert serialized attendance matrix back to proper format
  static Map<int, Map<DateTime, bool>> _attendanceMatrixFromMap(Map<String, dynamic> map) {
    final Map<int, Map<DateTime, bool>> result = {};
    
    map.forEach((studentIdStr, dateMapData) {
      final studentId = int.parse(studentIdStr);
      final Map<DateTime, bool> dateMap = {};
      
      (dateMapData as Map<String, dynamic>).forEach((dateStr, isPresent) {
        dateMap[DateTime.parse(dateStr)] = isPresent as bool;
      });
      
      result[studentId] = dateMap;
    });
    
    return result;
  }
  
  // Create an empty MonthAttendanceData for a given month
  factory MonthAttendanceData.empty(DateTime month) {
    return MonthAttendanceData(
      month: month,
      students: [],
      attendanceDays: [],
      attendanceMatrix: {},
      attendancePercentages: {},
    );
  }
  
  // Check if the data is empty
  bool get isEmpty => students.isEmpty || attendanceDays.isEmpty;
  
  // Get the number of students
  int get studentCount => students.length;
  
  // Get the number of attendance days
  int get attendanceDayCount => attendanceDays.length;
  
  @override
  String toString() {
    return 'MonthAttendanceData{month: $month, students: ${students.length}, attendanceDays: ${attendanceDays.length}}';
  }
}