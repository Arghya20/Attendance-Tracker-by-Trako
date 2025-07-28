import 'package:flutter/foundation.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/repositories/student_repository.dart';

class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository = StudentRepository();
  
  List<Student> _students = [];
  Student? _selectedStudent;
  bool _isLoading = false;
  String? _error;
  int? _currentClassId;
  
  // Cache for student details
  final Map<int, Student> _studentCache = {};
  final Map<int, DateTime> _lastLoadTimeByClass = {};
  
  // Getters
  List<Student> get students => _students;
  Student? get selectedStudent => _selectedStudent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentClassId => _currentClassId;
  
  // Load students for a class
  Future<void> loadStudents(int classId) async {
    // Check if we have recently loaded students for this class (within the last 30 seconds)
    final now = DateTime.now();
    if (_lastLoadTimeByClass.containsKey(classId) && 
        now.difference(_lastLoadTimeByClass[classId]!).inSeconds < 30 && 
        _currentClassId == classId &&
        _students.isNotEmpty) {
      // Use cached data
      return;
    }
    
    _setLoading(true);
    try {
      _currentClassId = classId;
      _students = await _repository.getStudentsWithAttendanceStats(classId);
      
      // Update cache
      for (final student in _students) {
        if (student.id != null) {
          _studentCache[student.id!] = student;
        }
      }
      
      _lastLoadTimeByClass[classId] = now;
      _error = null;
    } catch (e) {
      _error = 'Failed to load students: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Select a student
  Future<void> selectStudent(int studentId) async {
    // Check if we have this student in cache
    if (_studentCache.containsKey(studentId)) {
      _selectedStudent = _studentCache[studentId];
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    try {
      _selectedStudent = await _repository.getStudentById(studentId);
      
      // Update cache
      if (_selectedStudent != null && _selectedStudent!.id != null) {
        _studentCache[_selectedStudent!.id!] = _selectedStudent!;
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load student details: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Add a new student
  Future<bool> addStudent(int classId, String name, String? rollNumber) async {
    _setLoading(true);
    try {
      final newStudent = await _repository.createStudent(classId, name, rollNumber);
      if (newStudent != null) {
        _students.add(newStudent);
        notifyListeners();
        _error = null;
        return true;
      }
      _error = 'Failed to add student';
      return false;
    } catch (e) {
      _error = 'Failed to add student: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update a student
  Future<bool> updateStudent(Student student) async {
    _setLoading(true);
    try {
      final success = await _repository.updateStudent(student);
      if (success) {
        final index = _students.indexWhere((s) => s.id == student.id);
        if (index != -1) {
          _students[index] = student;
        }
        if (_selectedStudent?.id == student.id) {
          _selectedStudent = student;
        }
        notifyListeners();
        _error = null;
        return true;
      }
      _error = 'Failed to update student';
      return false;
    } catch (e) {
      _error = 'Failed to update student: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a student
  Future<bool> deleteStudent(int studentId) async {
    _setLoading(true);
    try {
      final success = await _repository.deleteStudent(studentId);
      if (success) {
        _students.removeWhere((s) => s.id == studentId);
        if (_selectedStudent?.id == studentId) {
          _selectedStudent = null;
        }
        notifyListeners();
        _error = null;
        return true;
      }
      _error = 'Failed to delete student';
      return false;
    } catch (e) {
      _error = 'Failed to delete student: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Clear selected student
  void clearSelectedStudent() {
    _selectedStudent = null;
    notifyListeners();
  }
  
  // Clear cache
  void clearCache() {
    _studentCache.clear();
    _lastLoadTimeByClass.clear();
  }
}