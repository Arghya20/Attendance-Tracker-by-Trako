import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/widgets/add_student_dialog.dart';
import 'package:intl/intl.dart';

class StudentDetailsDialog extends StatefulWidget {
  final Student student;
  
  const StudentDetailsDialog({
    super.key,
    required this.student,
  });

  @override
  State<StudentDetailsDialog> createState() => _StudentDetailsDialogState();
}

class _StudentDetailsDialogState extends State<StudentDetailsDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendanceRecords = [];
  
  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }
  
  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final records = await attendanceProvider.getStudentAttendance(widget.student.id!);
      
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendancePercentage = widget.student.attendancePercentage ?? 0.0;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: Text(
                    widget.student.name.isNotEmpty ? widget.student.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student.name,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (widget.student.rollNumber != null && widget.student.rollNumber!.isNotEmpty)
                        Text(
                          'Roll Number: ${widget.student.rollNumber}',
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context,
                  'Attendance',
                  '${attendancePercentage.toStringAsFixed(1)}%',
                  _getAttendanceColor(attendancePercentage),
                ),
                _buildStatCard(
                  context,
                  'Present',
                  _getPresentCount().toString(),
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Absent',
                  _getAbsentCount().toString(),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recent Attendance',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _buildAttendanceHistory(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AddStudentDialog(
                        classId: widget.student.classId,
                        studentToEdit: widget.student,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttendanceHistory() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_attendanceRecords.isEmpty) {
      return const Center(
        child: Text('No attendance records found'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        final date = DateTime.parse(record['session_date']);
        final isPresent = record['is_present'] == 1;
        
        return ListTile(
          leading: Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? Colors.green : Colors.red,
          ),
          title: Text(DateFormat('EEEE, MMMM d, yyyy').format(date)),
          trailing: Text(
            isPresent ? 'Present' : 'Absent',
            style: TextStyle(
              color: isPresent ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
  
  int _getPresentCount() {
    return _attendanceRecords.where((record) => record['is_present'] == 1).length;
  }
  
  int _getAbsentCount() {
    return _attendanceRecords.where((record) => record['is_present'] == 0).length;
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
}