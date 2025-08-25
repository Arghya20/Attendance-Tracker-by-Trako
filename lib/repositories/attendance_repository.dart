import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/services/database_helper.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:flutter/foundation.dart';

class AttendanceRepository {
  final DatabaseService _databaseService = DatabaseService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Create or get attendance session
  Future<AttendanceSession?> createOrGetSession(int classId, DateTime date) async {
    try {
      // Check if session already exists for this class and date
      final existingSession = await _databaseHelper.getSessionByClassAndDate(classId, date);
      
      if (existingSession != null) {
        return AttendanceSession.fromMap(existingSession);
      }
      
      // Create new session
      final now = DateTime.now().toIso8601String();
      final dateStr = date.toIso8601String();
      
      final id = await _databaseService.insert(
        AppConstants.attendanceSessionTable,
        {
          'class_id': classId,
          'date': dateStr,
          'created_at': now,
          'updated_at': now,
        },
      );
      
      return AttendanceSession(
        id: id,
        classId: classId,
        date: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating or getting session: $e');
      return null;
    }
  }
  
  // Get all sessions for a class
  Future<List<AttendanceSession>> getSessionsByClassId(int classId) async {
    try {
      final sessionsData = await _databaseHelper.getSessionsByClassId(classId);
      return sessionsData.map((data) => AttendanceSession.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting sessions by class ID: $e');
      return [];
    }
  }
  
  // Get a session by ID
  Future<AttendanceSession?> getSessionById(int id) async {
    try {
      final sessionData = await _databaseService.getById(AppConstants.attendanceSessionTable, id);
      if (sessionData == null) return null;
      
      return AttendanceSession.fromMap(sessionData);
    } catch (e) {
      debugPrint('Error getting session by ID: $e');
      return null;
    }
  }
  
  // Delete a session
  Future<bool> deleteSession(int id) async {
    try {
      await _databaseHelper.deleteAttendanceSession(id);
      return true;
    } catch (e) {
      debugPrint('Error deleting session: $e');
      return false;
    }
  }
  
  // Delete attendance records for a session (without deleting the session itself)
  Future<bool> deleteAttendanceRecords(int sessionId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        AppConstants.attendanceRecordTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting attendance records: $e');
      return false;
    }
  }
  
  // Save attendance records for a session
  Future<bool> saveAttendanceRecords(int sessionId, List<AttendanceRecord> records) async {
    try {
      final recordsData = records.map((record) => {
        'student_id': record.studentId,
        'is_present': record.isPresent,
      }).toList();
      
      await _databaseHelper.saveAttendanceRecords(sessionId, recordsData);
      return true;
    } catch (e) {
      debugPrint('Error saving attendance records: $e');
      return false;
    }
  }
  
  // Get attendance records for a session
  Future<List<AttendanceRecord>> getRecordsBySessionId(int sessionId) async {
    try {
      final recordsData = await _databaseHelper.getRecordsBySessionId(sessionId);
      return recordsData.map((data) => AttendanceRecord.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting records by session ID: $e');
      return [];
    }
  }
  
  // Get attendance records with student info
  Future<List<Map<String, dynamic>>> getAttendanceWithStudentInfo(int sessionId) async {
    try {
      return await _databaseHelper.getAttendanceBySessionWithStudentInfo(sessionId);
    } catch (e) {
      debugPrint('Error getting attendance with student info: $e');
      return [];
    }
  }
  
  // Update a single attendance record
  Future<bool> updateAttendanceRecord(AttendanceRecord record) async {
    try {
      final result = await _databaseService.update(
        AppConstants.attendanceRecordTable,
        {
          'is_present': record.isPresent ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        record.id!,
      );
      
      return result > 0;
    } catch (e) {
      debugPrint('Error updating attendance record: $e');
      return false;
    }
  }
  
  // Get attendance records for a student
  Future<List<Map<String, dynamic>>> getAttendanceByStudentId(int studentId) async {
    try {
      return await _databaseHelper.getAttendanceByStudentId(studentId);
    } catch (e) {
      debugPrint('Error getting attendance by student ID: $e');
      return [];
    }
  }
  
  // Get distinct months with attendance sessions for a class
  Future<List<DateTime>> getAvailableMonthsForClass(int classId) async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT strftime('%Y-%m', date) as month_year 
        FROM ${AppConstants.attendanceSessionTable} 
        WHERE class_id = ? 
        ORDER BY month_year DESC
      ''', [classId]);
      
      return result.map((row) {
        final monthYear = row['month_year'] as String;
        final parts = monthYear.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateTime(year, month);
      }).toList();
    } catch (e) {
      debugPrint('Error getting available months for class: $e');
      return [];
    }
  }
  
  // Get all attendance data for a specific month and class
  Future<MonthAttendanceData> getMonthAttendanceData(int classId, int year, int month) async {
    try {
      final monthDateTime = DateTime(year, month);
      final monthStr = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
      
      // Get students for the class
      final studentsData = await _databaseHelper.getStudentsByClassId(classId);
      final students = studentsData.map((data) => Student.fromMap(data)).toList();
      
      if (students.isEmpty) {
        return MonthAttendanceData.empty(monthDateTime);
      }
      
      // Get attendance sessions for the month
      final db = await _databaseService.database;
      final sessionsResult = await db.rawQuery('''
        SELECT * FROM ${AppConstants.attendanceSessionTable}
        WHERE class_id = ? AND strftime('%Y-%m', date) = ?
        ORDER BY date ASC
      ''', [classId, monthStr]);
      
      final attendanceDays = sessionsResult
          .map((session) => DateTime.parse(session['date'] as String))
          .toList();
      
      if (attendanceDays.isEmpty) {
        return MonthAttendanceData(
          month: monthDateTime,
          students: students,
          attendanceDays: [],
          attendanceMatrix: {},
          attendancePercentages: {},
        );
      }
      
      // Get attendance records for all sessions in the month
      final sessionIds = sessionsResult.map((s) => s['id'] as int).toList();
      final sessionIdsStr = sessionIds.join(',');
      
      final attendanceResult = await db.rawQuery('''
        SELECT 
          ar.student_id,
          ar.is_present,
          ats.date
        FROM ${AppConstants.attendanceRecordTable} ar
        JOIN ${AppConstants.attendanceSessionTable} ats ON ar.session_id = ats.id
        WHERE ar.session_id IN ($sessionIdsStr)
        ORDER BY ar.student_id, ats.date
      ''');
      
      // Build attendance matrix
      final Map<int, Map<DateTime, bool>> attendanceMatrix = {};
      final Map<int, double> attendancePercentages = {};
      
      // Initialize matrix for all students
      for (final student in students) {
        attendanceMatrix[student.id!] = {};
      }
      
      // Fill attendance data
      for (final record in attendanceResult) {
        final studentId = record['student_id'] as int;
        final isPresent = (record['is_present'] as int) == 1;
        final date = DateTime.parse(record['date'] as String);
        
        attendanceMatrix[studentId]![date] = isPresent;
      }
      
      // Calculate attendance percentages
      for (final student in students) {
        final studentAttendance = attendanceMatrix[student.id!]!;
        final presentCount = studentAttendance.values.where((present) => present == true).length;
        final totalDays = studentAttendance.length;
        
        final percentage = totalDays > 0 
            ? MonthAttendanceData.calculateAttendancePercentage(presentCount, totalDays)
            : 0.0;
        
        attendancePercentages[student.id!] = percentage;
      }
      
      return MonthAttendanceData(
        month: monthDateTime,
        students: students,
        attendanceDays: attendanceDays,
        attendanceMatrix: attendanceMatrix,
        attendancePercentages: attendancePercentages,
      );
    } catch (e) {
      debugPrint('Error getting month attendance data: $e');
      return MonthAttendanceData.empty(DateTime(year, month));
    }
  }
}