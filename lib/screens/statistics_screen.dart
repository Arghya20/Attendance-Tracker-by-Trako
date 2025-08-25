import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';
import 'package:attendance_tracker/widgets/error_message.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/widgets/month_selection_dialog.dart';
import 'package:attendance_tracker/screens/month_export_screen.dart';
import 'package:attendance_tracker/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    // Load available months
    await attendanceProvider.loadAvailableMonths(widget.classItem.id!);
    
    if (!mounted) return;
    
    // Show month selection dialog
    final selectedMonth = await showMonthSelectionDialog(
      context: context,
      availableMonths: attendanceProvider.availableMonths,
      isLoading: attendanceProvider.isLoading,
      errorMessage: attendanceProvider.error,
      onRetry: () => attendanceProvider.loadAvailableMonths(widget.classItem.id!),
    );
    
    if (selectedMonth != null && mounted) {
      // Load month data and navigate to export screen
      await attendanceProvider.loadMonthAttendanceData(widget.classItem.id!, selectedMonth);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MonthExportScreen(
              classItem: widget.classItem,
              selectedMonth: selectedMonth,
              monthData: attendanceProvider.monthAttendanceData,
              isLoading: attendanceProvider.isLoading,
              errorMessage: attendanceProvider.error,
              onRetry: () => attendanceProvider.loadMonthAttendanceData(widget.classItem.id!, selectedMonth),
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _exportSummaryData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final fileName = 'attendance_summary_${widget.classItem.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Calculate overall statistics
      int totalPresent = 0;
      int totalAbsent = 0;
      
      for (final student in _students) {
        final attendance = _studentAttendance[student.id!] ?? [];
        totalPresent += attendance.where((a) => a['is_present'] == 1).length;
        totalAbsent += attendance.where((a) => a['is_present'] == 0).length;
      }
      
      final totalAttendance = totalPresent + totalAbsent;
      final overallPercentage = totalAttendance > 0
          ? (totalPresent / totalAttendance) * 100
          : 0.0;
      
      // Create table data
      final tableData = <List<String>>[];
      
      for (int i = 0; i < _students.length; i++) {
        final student = _students[i];
        final attendance = _studentAttendance[student.id!] ?? [];
        final presentCount = attendance.where((a) => a['is_present'] == 1).length;
        final absentCount = attendance.length - presentCount;
        final percentage = attendance.isEmpty
            ? 0.0
            : (presentCount / attendance.length) * 100;
        
        tableData.add([
          '${i + 1}',
          student.name,
          student.rollNumber ?? '-',
          presentCount.toString(),
          absentCount.toString(),
          '${percentage.toStringAsFixed(1)}%',
        ]);
      }
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  'Attendance Summary Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Class: ${widget.classItem.name}',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Generated on: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 20),
                
                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('Total Students', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('${_students.length}'),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Total Sessions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('${_sessions.length}'),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Overall Attendance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('${overallPercentage.toStringAsFixed(1)}%'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Student Summary Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(30), // SL
                    1: const pw.FlexColumnWidth(3), // Name
                    2: const pw.FlexColumnWidth(2), // Roll Number
                    3: const pw.FixedColumnWidth(50), // Present
                    4: const pw.FixedColumnWidth(50), // Absent
                    5: const pw.FixedColumnWidth(70), // Percentage
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        'SL',
                        'Student Name',
                        'Roll Number',
                        'Present',
                        'Absent',
                        'Percentage',
                      ].map((header) => 
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            header,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ).toList(),
                    ),
                    
                    // Data rows
                    ...tableData.map((row) => 
                      pw.TableRow(
                        children: row.asMap().entries.map((entry) {
                          final index = entry.key;
                          final cell = entry.value;
                          
                          return pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              cell,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: index == 1 ? pw.FontWeight.bold : pw.FontWeight.normal,
                              ),
                              textAlign: index == 0 || index > 2 
                                  ? pw.TextAlign.center 
                                  : pw.TextAlign.left,
                            ),
                          );
                        }).toList(),
                      ),
                    ).toList(),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Text(
                  'This report shows the overall attendance summary for all students in the class.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            );
          },
        ),
      );
      
      // Save PDF to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Summary - ${widget.classItem.name}',
        text: 'Attendance summary report for ${widget.classItem.name}',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        CustomSnackBar.show(
          context: context,
          message: 'Attendance summary saved successfully',
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
          message: 'Failed to save summary: $e',
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.assessment),
            tooltip: 'Monthly Reports',
            onSelected: (value) {
              if (value == 'monthly') {
                _exportData();
              } else if (value == 'summary') {
                _exportSummaryData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'monthly',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Monthly Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'summary',
                child: Row(
                  children: [
                    Icon(Icons.summarize),
                    SizedBox(width: 8),
                    Text('Summary Report'),
                  ],
                ),
              ),
            ],
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