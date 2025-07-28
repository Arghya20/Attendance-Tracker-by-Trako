import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';

class EditAttendanceDialog extends StatefulWidget {
  final AttendanceSession session;
  final List<Map<String, dynamic>> attendanceRecords;
  
  const EditAttendanceDialog({
    super.key,
    required this.session,
    required this.attendanceRecords,
  });

  @override
  State<EditAttendanceDialog> createState() => _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends State<EditAttendanceDialog> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final Map<int, bool> _attendanceStatus = {};
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _animationController.forward();
    
    // Initialize attendance status
    for (final record in widget.attendanceRecords) {
      _attendanceStatus[record['id']] = record['is_present'] == 1;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _saveAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      
      // Create updated records
      final updatedRecords = widget.attendanceRecords.map((record) {
        return AttendanceRecord(
          id: record['id'],
          sessionId: widget.session.id!,
          studentId: record['student_id'],
          isPresent: _attendanceStatus[record['id']] ?? (record['is_present'] == 1),
        );
      }).toList();
      
      // Save each record individually
      bool allSuccess = true;
      for (final record in updatedRecords) {
        final success = await attendanceProvider.updateAttendanceRecord(record);
        if (!success) {
          allSuccess = false;
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (allSuccess) {
          _animationController.reverse().then((_) {
            Navigator.pop(context, true);
            CustomSnackBar.show(
              context: context,
              message: 'Attendance records updated successfully',
              type: SnackBarType.success,
            );
          });
        } else {
          setState(() {
            _errorMessage = attendanceProvider.error ?? 'Failed to update some attendance records';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }
  
  void _toggleAllAttendance(bool value) {
    setState(() {
      for (final record in widget.attendanceRecords) {
        _attendanceStatus[record['id']] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionDate = DateFormat('MMMM d, yyyy').format(widget.session.date);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
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
                  Icon(
                    Icons.edit,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Attendance',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          'Date: $sessionDate',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _toggleAllAttendance(true),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('All Present'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _toggleAllAttendance(false),
                    icon: const Icon(Icons.cancel),
                    label: const Text('All Absent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.attendanceRecords.map((record) {
                      final isPresent = _attendanceStatus[record['id']] ?? (record['is_present'] == 1);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            child: Text(
                              record['student_name'].isNotEmpty
                                  ? record['student_name'][0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(record['student_name']),
                          subtitle: record['student_roll_number'] != null
                              ? Text('Roll: ${record['student_roll_number']}')
                              : null,
                          trailing: Switch(
                            value: isPresent,
                            onChanged: (value) {
                              setState(() {
                                _attendanceStatus[record['id']] = value;
                              });
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                          ),
                          onTap: () {
                            setState(() {
                              _attendanceStatus[record['id']] = !isPresent;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _animationController.reverse().then((_) {
                              Navigator.pop(context);
                            });
                          },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}