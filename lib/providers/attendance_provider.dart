import 'package:flutter/foundation.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/repositories/attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repository = AttendanceRepository();
  
  List<AttendanceSession> _sessions = [];
  AttendanceSession? _selectedSession;
  List<AttendanceRecord> _records = [];
  List<Map<String, dynamic>> _attendanceWithStudentInfo = [];
  bool _isLoading = false;
  String? _error;
  
  // Callback for attendance updates
  void Function(int classId)? onAttendanceUpdated;
  
  // Getters
  List<AttendanceSession> get sessions => _sessions;
  AttendanceSession? get selectedSession => _selectedSession;
  List<AttendanceRecord> get records => _records;
  List<Map<String, dynamic>> get attendanceWithStudentInfo => _attendanceWithStudentInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load sessions for a class
  Future<void> loadSessions(int classId) async {
    _setLoading(true);
    try {
      _sessions = await _repository.getSessionsByClassId(classId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load attendance sessions: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Create or get a session for a specific date
  Future<AttendanceSession?> createOrGetSession(int classId, DateTime date) async {
    _setLoading(true);
    try {
      final session = await _repository.createOrGetSession(classId, date);
      if (session != null) {
        // Check if session already exists in the list
        final existingIndex = _sessions.indexWhere((s) => s.id == session.id);
        if (existingIndex == -1) {
          _sessions.add(session);
          notifyListeners();
        }
        _selectedSession = session;
        _error = null;
      } else {
        _error = 'Failed to create attendance session';
      }
      return session;
    } catch (e) {
      _error = 'Failed to create attendance session: $e';
      debugPrint(_error);
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Select a session
  Future<void> selectSession(int sessionId) async {
    _setLoading(true);
    try {
      _selectedSession = await _repository.getSessionById(sessionId);
      if (_selectedSession != null) {
        await loadAttendanceRecords(_selectedSession!.id!);
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load session details: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Load attendance records for a session
  Future<void> loadAttendanceRecords(int sessionId) async {
    _setLoading(true);
    try {
      _records = await _repository.getRecordsBySessionId(sessionId);
      _attendanceWithStudentInfo = await _repository.getAttendanceWithStudentInfo(sessionId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load attendance records: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Save attendance records
  Future<bool> saveAttendanceRecords(int sessionId, List<AttendanceRecord> records) async {
    _setLoading(true);
    try {
      // Get the session details before deleting records
      final session = await _repository.getSessionById(sessionId);
      if (session == null) {
        _error = 'Failed to get attendance session';
        return false;
      }
      
      // Delete only the attendance records, not the session itself
      final db = await _repository.deleteAttendanceRecords(sessionId);
      
      // Save the new records
      final success = await _repository.saveAttendanceRecords(sessionId, records);
      if (success) {
        _records = records;
        await loadAttendanceRecords(sessionId);
        _error = null;
        
        // Notify about attendance update
        notifyAttendanceUpdated(session.classId);
        
        return true;
      }
      _error = 'Failed to save attendance records';
      return false;
    } catch (e) {
      _error = 'Failed to save attendance records: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update a single attendance record
  Future<bool> updateAttendanceRecord(AttendanceRecord record) async {
    _setLoading(true);
    try {
      final success = await _repository.updateAttendanceRecord(record);
      if (success) {
        final index = _records.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          _records[index] = record;
        }
        await loadAttendanceRecords(record.sessionId);
        _error = null;
        return true;
      }
      _error = 'Failed to update attendance record';
      return false;
    } catch (e) {
      _error = 'Failed to update attendance record: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a session
  Future<bool> deleteSession(int sessionId) async {
    _setLoading(true);
    try {
      final success = await _repository.deleteSession(sessionId);
      if (success) {
        _sessions.removeWhere((s) => s.id == sessionId);
        if (_selectedSession?.id == sessionId) {
          _selectedSession = null;
          _records = [];
          _attendanceWithStudentInfo = [];
        }
        notifyListeners();
        _error = null;
        return true;
      }
      _error = 'Failed to delete attendance session';
      return false;
    } catch (e) {
      _error = 'Failed to delete attendance session: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get attendance records for a student
  Future<List<Map<String, dynamic>>> getStudentAttendance(int studentId) async {
    _setLoading(true);
    try {
      final records = await _repository.getAttendanceByStudentId(studentId);
      _error = null;
      return records;
    } catch (e) {
      _error = 'Failed to get student attendance: $e';
      debugPrint(_error);
      return [];
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
  
  // Clear selected session
  void clearSelectedSession() {
    _selectedSession = null;
    _records = [];
    _attendanceWithStudentInfo = [];
    notifyListeners();
  }
  
  // Notify about attendance updates
  void notifyAttendanceUpdated(int classId) {
    if (onAttendanceUpdated != null) {
      onAttendanceUpdated!(classId);
    }
  }
  
  // Month export functionality
  List<DateTime> _availableMonths = [];
  MonthAttendanceData? _monthAttendanceData;
  
  // Getters for month export
  List<DateTime> get availableMonths => _availableMonths;
  MonthAttendanceData? get monthAttendanceData => _monthAttendanceData;
  
  // Get all months that have attendance data for a class
  Future<void> loadAvailableMonths(int classId) async {
    _setLoading(true);
    try {
      _availableMonths = await _repository.getAvailableMonthsForClass(classId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load available months: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Get detailed month attendance data
  Future<void> loadMonthAttendanceData(int classId, DateTime month) async {
    _setLoading(true);
    try {
      _monthAttendanceData = await _repository.getMonthAttendanceData(
        classId, 
        month.year, 
        month.month,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load month attendance data: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Clear month data
  void clearMonthData() {
    _availableMonths = [];
    _monthAttendanceData = null;
    notifyListeners();
  }
}