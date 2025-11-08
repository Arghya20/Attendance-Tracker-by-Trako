import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/services/database_helper.dart';
import 'package:attendance_tracker/services/database_service.dart';
import 'package:attendance_tracker/services/cloud_sync_service.dart';
import 'package:flutter/foundation.dart';

class ClassRepository {
  final DatabaseService _databaseService = DatabaseService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  
  // Get all classes with student and session counts
  Future<List<Class>> getAllClasses() async {
    try {
      final classesData = await _databaseHelper.getClassesWithStats();
      return classesData.map((data) => Class.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error getting all classes: $e');
      return [];
    }
  }
  
  // Get a class by ID
  Future<Class?> getClassById(int id) async {
    try {
      final classData = await _databaseService.getById(AppConstants.classTable, id);
      if (classData == null) return null;
      
      // Get student count
      final studentsData = await _databaseHelper.getStudentsByClassId(id);
      final studentCount = studentsData.length;
      
      // Get session count
      final sessionsData = await _databaseHelper.getSessionsByClassId(id);
      final sessionCount = sessionsData.length;
      
      final classModel = Class.fromMap(classData);
      return classModel.copyWith(
        studentCount: studentCount,
        sessionCount: sessionCount,
      );
    } catch (e) {
      debugPrint('Error getting class by ID: $e');
      return null;
    }
  }
  
  // Create a new class
  Future<Class?> createClass(String name) async {
    try {
      final now = DateTime.now().toIso8601String();
      final id = await _databaseService.insert(
        AppConstants.classTable,
        {
          'name': name,
          'created_at': now,
          'updated_at': now,
        },
      );
      
      // Trigger sync after data change
      _cloudSyncService.syncAfterDataChange();
      
      return Class(
        id: id,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        studentCount: 0,
        sessionCount: 0,
      );
    } catch (e) {
      debugPrint('Error creating class: $e');
      return null;
    }
  }
  
  // Update a class
  Future<bool> updateClass(Class classModel) async {
    try {
      final result = await _databaseService.update(
        AppConstants.classTable,
        {
          'name': classModel.name,
          'updated_at': DateTime.now().toIso8601String(),
        },
        classModel.id!,
      );
      
      // Trigger sync after data change
      if (result > 0) {
        _cloudSyncService.syncAfterDataChange();
      }
      
      return result > 0;
    } catch (e) {
      debugPrint('Error updating class: $e');
      return false;
    }
  }
  
  // Delete a class
  Future<bool> deleteClass(int id) async {
    try {
      await _databaseHelper.deleteClass(id);
      
      // Trigger sync after data change
      _cloudSyncService.syncAfterDataChange();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting class: $e');
      return false;
    }
  }

  // Pin operations
  Future<bool> pinClass(int classId) async {
    try {
      final pinOrder = await _databaseHelper.getNextPinOrder();
      await _databaseHelper.pinClass(classId, pinOrder);
      return true;
    } catch (e) {
      debugPrint('Error pinning class: $e');
      return false;
    }
  }

  Future<bool> unpinClass(int classId) async {
    try {
      await _databaseHelper.unpinClass(classId);
      return true;
    } catch (e) {
      debugPrint('Error unpinning class: $e');
      return false;
    }
  }

  Future<bool> togglePinStatus(int classId) async {
    try {
      // Get current class to check pin status
      final classData = await _databaseService.getById(AppConstants.classTable, classId);
      if (classData == null) return false;
      
      final isPinned = (classData['is_pinned'] ?? 0) == 1;
      
      if (isPinned) {
        return await unpinClass(classId);
      } else {
        return await pinClass(classId);
      }
    } catch (e) {
      debugPrint('Error toggling pin status: $e');
      return false;
    }
  }
}