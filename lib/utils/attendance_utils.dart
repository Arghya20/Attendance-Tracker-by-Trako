import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:intl/intl.dart';

class AttendanceUtils {
  static Future<bool> hasExistingAttendance(
    AttendanceProvider attendanceProvider,
    int classId,
    DateTime date,
  ) async {
    // Get all sessions for the class
    await attendanceProvider.loadSessions(classId);
    final sessions = attendanceProvider.sessions;
    
    // Check if there's a session for the selected date
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final existingSession = sessions.firstWhere(
      (session) => DateFormat('yyyy-MM-dd').format(session.date) == dateString,
      orElse: () => AttendanceSession(classId: -1, date: DateTime.now()),
    );
    
    // If we found a session with records, return true
    if (existingSession.id != null) {
      await attendanceProvider.loadAttendanceRecords(existingSession.id!);
      return attendanceProvider.records.isNotEmpty;
    }
    
    return false;
  }
  
  static String getAttendanceStatusText(double percentage) {
    if (percentage >= 90) {
      return 'Excellent';
    } else if (percentage >= 75) {
      return 'Good';
    } else if (percentage >= 60) {
      return 'Average';
    } else {
      return 'Poor';
    }
  }
}