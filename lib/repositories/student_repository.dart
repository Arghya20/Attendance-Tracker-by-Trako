import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/services/database_helper.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/services/cloud_sync_service.dart';
import 'package:flutter/foundation.dart';

class StudentRepository {
  final DatabaseService _databaseService = DatabaseService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  
  // Get all students for a class
  Future<List<Student>> getStudentsByClassId(int classId) async {
    try {
      final studentsData = await _databaseHelper.getStudentsByClassId(classId);
      return studentsData.map((data) => Student.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting students by class ID: $e');
      return [];
    }
  }
  
  // Get all students with attendance statistics
  Future<List<Student>> getStudentsWithAttendanceStats(int classId) async {
    try {
      final studentsData = await _databaseHelper.getStudentsWithAttendanceStats(classId);
      return studentsData.map((data) => Student.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting students with attendance stats: $e');
      return [];
    }
  }
  
  // Get a student by ID
  Future<Student?> getStudentById(int id) async {
    try {
      final studentData = await _databaseService.getById(AppConstants.studentTable, id);
      if (studentData == null) return null;
      
      // Calculate attendance percentage
      final attendanceData = await _databaseHelper.getAttendanceByStudentId(id);
      double attendancePercentage = 0.0;
      
      if (attendanceData.isNotEmpty) {
        final presentCount = attendanceData.where((record) => record['is_present'] == 1).length;
        attendancePercentage = (presentCount / attendanceData.length) * 100;
      }
      
      final student = Student.fromMap(studentData);
      return student.copyWith(attendancePercentage: attendancePercentage);
    } catch (e) {
      debugPrint('Error getting student by ID: $e');
      return null;
    }
  }
  
  // Create a new student
  Future<Student?> createStudent(int classId, String name, String? rollNumber) async {
    try {
      final now = DateTime.now().toIso8601String();
      final id = await _databaseService.insert(
        AppConstants.studentTable,
        {
          'class_id': classId,
          'name': name,
          'roll_number': rollNumber,
          'created_at': now,
          'updated_at': now,
        },
      );
      
      // Trigger sync after data change
      _cloudSyncService.syncAfterDataChange();
      
      return Student(
        id: id,
        classId: classId,
        name: name,
        rollNumber: rollNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attendancePercentage: 0.0,
      );
    } catch (e) {
      debugPrint('Error creating student: $e');
      return null;
    }
  }
  
  // Update a student
  Future<bool> updateStudent(Student student) async {
    try {
      final result = await _databaseService.update(
        AppConstants.studentTable,
        {
          'name': student.name,
          'roll_number': student.rollNumber,
          'updated_at': DateTime.now().toIso8601String(),
        },
        student.id!,
      );
      
      // Trigger sync after data change
      if (result > 0) {
        _cloudSyncService.syncAfterDataChange();
      }
      
      return result > 0;
    } catch (e) {
      debugPrint('Error updating student: $e');
      return false;
    }
  }
  
  // Delete a student
  Future<bool> deleteStudent(int id) async {
    try {
      await _databaseHelper.deleteStudent(id);
      
      // Trigger sync after data change
      _cloudSyncService.syncAfterDataChange();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting student: $e');
      return false;
    }
  }
}