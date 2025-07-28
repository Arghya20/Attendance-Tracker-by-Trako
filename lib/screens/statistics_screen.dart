import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';
import 'package:attendance_tracker/widgets/error_message.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StatisticsScreen extends StatefulWidget {
  final Class classItem;
  
  const StatisticsScreen({
    super.key,
    required this.classItem,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Student> _students = [];
  List<AttendanceSession> _sessions = [];
  Map<int, List<Map<String, dynamic>>> _studentAttendance = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Load students
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      await studentProvider.loadStudents(widget.classItem.id!);
      
      // Load sessions
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.loadSessions(widget.classItem.id!);
      
      // Load attendance for each student
      final Map<int, List<Map<String, dynamic>>> studentAttendance = {};
      final List<Student> studentsWithAttendance = [];
      
      for (final student in studentProvider.students) {
        final attendance = await attendanceProvider.getStudentAttendance(student.id!);
        studentAttendance[student.id!] = attendance;
        
        // Calculate attendance percentage
        final presentCount = attendance.where((a) => a['is_present'] == 1).length;
        final percentage = attendance.isEmpty
            ? 0.0
            : (presentCount / attendance.length) * 100;
        
        // Create a new student with the attendance percentage
        final updatedStudent = student.copyWith(attendancePercentage: percentage);
        studentsWithAttendance.add(updatedStudent);
      }
      
      if (mounted) {
        setState(() {
          _students = studentsWithAttendance;
          _sessions = attendanceProvider.sessions;
          _studentAttendance = studentAttendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load statistics data: $e';
        });
      }
    }
  }
  
  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create CSV data
      final List<List<dynamic>> csvData = [];
      
      // Add header row
      final headerRow = ['Student Name', 'Roll Number', 'Present', 'Absent', 'Percentage'];
      csvData.add(headerRow);
      
      // Add data rows
      for (final student in _students) {
        final attendance = _studentAttendance[student.id!] ?? [];
        final presentCount = attendance.where((a) => a['is_present'] == 1).length;
        final absentCount = attendance.length - presentCount;
        final percentage = attendance.isEmpty
            ? 0.0
            : (presentCount / attendance.length) * 100;
        
        final row = [
          student.name,
          student.rollNumber ?? '',
          presentCount,
          absentCount,
          percentage.toStringAsFixed(2) + '%',
        ];
        
        csvData.add(row);
      }
      
      // Convert to CSV string
      final csv = const ListToCsvConverter().convert(csvData);
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final fileName = 'attendance_${widget.classItem.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report - ${widget.classItem.name}',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        CustomSnackBar.show(
          context: context,
          message: 'Attendance data exported successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        CustomSnackBar.show(
          context: context,
          message: 'Failed to export data: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('StatisticsScreen.build: isLoading=$_isLoading, students=${_students.length}, sessions=${_sessions.length}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading statistics data...')
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_errorMessage != null) {
      return ErrorMessage(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }
    
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No students found in this class',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Add students to the class to see statistics',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: _buildStudentList(),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard() {
    // Calculate overall statistics
    int totalPresent = 0;
    int totalAbsent = 0;
    
    for (final attendance in _studentAttendance.values) {
      totalPresent += attendance.where((a) => a['is_present'] == 1).length;
      totalAbsent += attendance.where((a) => a['is_present'] == 0).length;
    }
    
    final totalAttendance = totalPresent + totalAbsent;
    final overallPercentage = totalAttendance > 0
        ? (totalPresent / totalAttendance) * 100
        : 0.0;
    
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Class Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Students',
                  '${_students.length}',
                  Colors.blue,
                  Icons.people,
                ),
                _buildStatCard(
                  'Sessions',
                  '${_sessions.length}',
                  Colors.purple,
                  Icons.calendar_today,
                ),
                _buildStatCard(
                  'Attendance',
                  '${overallPercentage.toStringAsFixed(1)}%',
                  _getAttendanceColor(overallPercentage),
                  Icons.analytics,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: overallPercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAttendanceColor(overallPercentage),
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Present: $totalPresent',
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  'Absent: $totalAbsent',
                  style: const TextStyle(color: Colors.red),
                ),
                Text(
                  'Total: $totalAttendance',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStudentList() {
    // Check if there are any sessions
    if (_sessions.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No attendance sessions found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Take attendance for this class to see statistics',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Sort students by attendance percentage (highest to lowest)
    final sortedStudents = List<Student>.from(_students);
    sortedStudents.sort((a, b) {
      final aPercentage = a.attendancePercentage ?? 0.0;
      final bPercentage = b.attendancePercentage ?? 0.0;
      return bPercentage.compareTo(aPercentage);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
          ),
          child: Row(
            children: [
              Icon(
                Icons.leaderboard,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Student Rankings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: sortedStudents.length,
            itemBuilder: (context, index) {
              final student = sortedStudents[index];
              final attendance = _studentAttendance[student.id!] ?? [];
              final presentCount = attendance.where((a) => a['is_present'] == 1).length;
              final absentCount = attendance.length - presentCount;
              final percentage = student.attendancePercentage ?? 0.0;
              
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding / 2,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(student.name),
                  subtitle: Text(
                    'Present: $presentCount, Absent: $absentCount',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getAttendanceColor(percentage),
                        ),
                      ),
                      Text(
                        _getAttendanceStatus(percentage),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getAttendanceColor(percentage),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    } else if (percentage >= 75) {
      return Colors.amber.shade700;
    } else {
      return Colors.red;
    }
  }
  
  String _getAttendanceStatus(double percentage) {
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