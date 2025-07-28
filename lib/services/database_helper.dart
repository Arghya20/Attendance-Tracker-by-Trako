import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  final DatabaseService _databaseService = DatabaseService();
  
  // Class table operations
  Future<List<Map<String, dynamic>>> getClassesWithStats() async {
    try {
      const query = '''
        SELECT 
          c.*,
          (SELECT COUNT(*) FROM ${AppConstants.studentTable} WHERE class_id = c.id) as student_count,
          (SELECT COUNT(*) FROM ${AppConstants.attendanceSessionTable} WHERE class_id = c.id) as session_count
        FROM ${AppConstants.classTable} c
        ORDER BY 
          CASE WHEN c.is_pinned = 1 THEN 0 ELSE 1 END,
          c.pin_order ASC,
          c.name ASC
      ''';
      
      return await _databaseService.rawQuery(query);
    } catch (e) {
      debugPrint('Error getting classes with stats: $e');
      rethrow;
    }
  }

  // Pin operations
  Future<void> pinClass(int classId, int pinOrder) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        AppConstants.classTable,
        {
          'is_pinned': 1,
          'pin_order': pinOrder,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [classId],
      );
    } catch (e) {
      debugPrint('Error pinning class: $e');
      rethrow;
    }
  }

  Future<void> unpinClass(int classId) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        AppConstants.classTable,
        {
          'is_pinned': 0,
          'pin_order': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [classId],
      );
    } catch (e) {
      debugPrint('Error unpinning class: $e');
      rethrow;
    }
  }

  Future<int> getNextPinOrder() async {
    try {
      const query = '''
        SELECT COALESCE(MAX(pin_order), 0) + 1 as next_order
        FROM ${AppConstants.classTable}
        WHERE is_pinned = 1
      ''';
      
      final result = await _databaseService.rawQuery(query);
      return result.first['next_order'] as int;
    } catch (e) {
      debugPrint('Error getting next pin order: $e');
      rethrow;
    }
  }
  
  // Student table operations
  Future<List<Map<String, dynamic>>> getStudentsByClassId(int classId) async {
    try {
      final db = await _databaseService.database;
      return await db.query(
        AppConstants.studentTable,
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'name',
      );
    } catch (e) {
      debugPrint('Error getting students by class ID: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getStudentsWithAttendanceStats(int classId) async {
    try {
      const query = '''
        SELECT 
          s.*,
          (
            SELECT CAST(SUM(CASE WHEN ar.is_present = 1 THEN 1 ELSE 0 END) AS REAL) / 
                   CAST(COUNT(ar.id) AS REAL) * 100
            FROM ${AppConstants.attendanceRecordTable} ar
            JOIN ${AppConstants.attendanceSessionTable} ats ON ar.session_id = ats.id
            WHERE ar.student_id = s.id AND ats.class_id = ?
          ) as attendance_percentage
        FROM ${AppConstants.studentTable} s
        WHERE s.class_id = ?
        ORDER BY s.name
      ''';
      
      return await _databaseService.rawQuery(query, [classId, classId]);
    } catch (e) {
      debugPrint('Error getting students with attendance stats: $e');
      rethrow;
    }
  }
  
  // Attendance session operations
  Future<Map<String, dynamic>?> getSessionByClassAndDate(int classId, DateTime date) async {
    try {
      final db = await _databaseService.database;
      final dateStr = date.toIso8601String().split('T')[0];
      
      final List<Map<String, dynamic>> result = await db.query(
        AppConstants.attendanceSessionTable,
        where: 'class_id = ? AND date LIKE ?',
        whereArgs: [classId, '$dateStr%'],
        limit: 1,
      );
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting session by class and date: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getSessionsByClassId(int classId) async {
    try {
      final db = await _databaseService.database;
      return await db.query(
        AppConstants.attendanceSessionTable,
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'date DESC',
      );
    } catch (e) {
      debugPrint('Error getting sessions by class ID: $e');
      rethrow;
    }
  }
  
  // Attendance record operations
  Future<List<Map<String, dynamic>>> getRecordsBySessionId(int sessionId) async {
    try {
      final db = await _databaseService.database;
      return await db.query(
        AppConstants.attendanceRecordTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      debugPrint('Error getting records by session ID: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getAttendanceBySessionWithStudentInfo(int sessionId) async {
    try {
      const query = '''
        SELECT 
          ar.*,
          s.name as student_name,
          s.roll_number as student_roll_number
        FROM ${AppConstants.attendanceRecordTable} ar
        JOIN ${AppConstants.studentTable} s ON ar.student_id = s.id
        WHERE ar.session_id = ?
        ORDER BY s.name
      ''';
      
      return await _databaseService.rawQuery(query, [sessionId]);
    } catch (e) {
      debugPrint('Error getting attendance with student info: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getAttendanceByStudentId(int studentId) async {
    try {
      const query = '''
        SELECT 
          ar.*,
          ats.date as session_date
        FROM ${AppConstants.attendanceRecordTable} ar
        JOIN ${AppConstants.attendanceSessionTable} ats ON ar.session_id = ats.id
        WHERE ar.student_id = ?
        ORDER BY ats.date DESC
      ''';
      
      return await _databaseService.rawQuery(query, [studentId]);
    } catch (e) {
      debugPrint('Error getting attendance by student ID: $e');
      rethrow;
    }
  }
  
  // Batch operations for attendance
  Future<void> saveAttendanceRecords(int sessionId, List<Map<String, dynamic>> records) async {
    try {
      await _databaseService.batch((batch) {
        for (var record in records) {
          batch.insert(
            AppConstants.attendanceRecordTable,
            {
              'session_id': sessionId,
              'student_id': record['student_id'],
              'is_present': record['is_present'] ? 1 : 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      debugPrint('Error saving attendance records: $e');
      rethrow;
    }
  }
  
  // Delete operations with cascading
  Future<void> deleteClass(int classId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        AppConstants.classTable,
        where: 'id = ?',
        whereArgs: [classId],
      );
    } catch (e) {
      debugPrint('Error deleting class: $e');
      rethrow;
    }
  }
  
  Future<void> deleteStudent(int studentId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        AppConstants.studentTable,
        where: 'id = ?',
        whereArgs: [studentId],
      );
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }
  
  Future<void> deleteAttendanceSession(int sessionId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        AppConstants.attendanceSessionTable,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      debugPrint('Error deleting attendance session: $e');
      rethrow;
    }
  }
}