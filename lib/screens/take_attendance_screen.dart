import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';
import 'package:attendance_tracker/widgets/error_message.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/utils/attendance_utils.dart';
import 'package:intl/intl.dart';
import 'package:neopop/neopop.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final Class classItem;
  
  const TakeAttendanceScreen({
    super.key,
    required this.classItem,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  final Map<int, bool> _attendanceStatus = {};
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }
  
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      await studentProvider.loadStudents(widget.classItem.id!);
      
      // Initialize all students as present by default
      for (final student in studentProvider.students) {
        _attendanceStatus[student.id!] = true;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load students: $e';
        });
      }
    }
  }
  
  Future<void> _saveAttendance() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    // Clear any previous errors
    attendanceProvider.clearError();
    
    if (studentProvider.students.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'No students to record attendance for',
        type: SnackBarType.warning,
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      // Check if attendance already exists for this date
      final hasExisting = await AttendanceUtils.hasExistingAttendance(
        attendanceProvider,
        widget.classItem.id!,
        _selectedDate,
      );
      
      if (hasExisting) {
        // Show confirmation dialog
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          
          final shouldOverwrite = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Attendance Already Exists'),
              content: Text(
                'Attendance records already exist for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}. '
                'Do you want to overwrite them?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Overwrite'),
                ),
              ],
            ),
          );
          
          if (shouldOverwrite != true) {
            return;
          }
          
          setState(() {
            _isSaving = true;
          });
        }
      }
      
      // Create or get session for the selected date
      final session = await attendanceProvider.createOrGetSession(
        widget.classItem.id!,
        _selectedDate,
      );
      
      if (session == null) {
        throw Exception('Failed to create attendance session');
      }
      
      // Create attendance records
      final records = studentProvider.students.map((student) {
        return AttendanceRecord(
          sessionId: session.id!,
          studentId: student.id!,
          isPresent: _attendanceStatus[student.id!] ?? true,
        );
      }).toList();
      
      // Save records
      final success = await attendanceProvider.saveAttendanceRecords(
        session.id!,
        records,
      );
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        if (success) {
          CustomSnackBar.show(
            context: context,
            message: 'Attendance saved successfully',
            type: SnackBarType.success,
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = attendanceProvider.error ?? 'Failed to save attendance';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error saving attendance: $e');
        setState(() {
          _isSaving = false;
          _errorMessage = 'An error occurred: $e';
        });
        
        // Show error message
        CustomSnackBar.show(
          context: context,
          message: 'Failed to save attendance: ${e.toString().replaceAll('Exception: ', '')}',
          type: SnackBarType.error,
        );
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  void _toggleAllAttendance(bool value) {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    setState(() {
      for (final student in studentProvider.students) {
        _attendanceStatus[student.id!] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh Students',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading students...')
          : _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildBody() {
    if (_errorMessage != null) {
      return ErrorMessage(
        message: _errorMessage!,
        onRetry: _loadStudents,
      );
    }
    
    final studentProvider = Provider.of<StudentProvider>(context);
    
    if (studentProvider.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No students in this class',
              style: AppConstants.subheadingStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Add students to the class before taking attendance',
              style: AppConstants.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        _buildDateSelector(),
        _buildAttendanceControls(),
        Expanded(
          child: _buildStudentList(),
        ),
      ],
    );
  }
  
  Widget _buildDateSelector() {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // For very narrow screens, use a more compact layout
            if (constraints.maxWidth < 350) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        'Attendance Date',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_selectedDate),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // For wider screens, use the original layout
              return Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Date',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                          style: theme.textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Change'),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildAttendanceControls() {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // If screen is narrow, use a column layout
            if (constraints.maxWidth < 400) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _toggleAllAttendance(true);
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('All Present'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _toggleAllAttendance(false);
                          },
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('All Absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // For wider screens, use a row layout
              return Row(
                children: [
                  const Text('Quick Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _toggleAllAttendance(true);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('All Present'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _toggleAllAttendance(false);
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('All Absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildStudentList() {
    final studentProvider = Provider.of<StudentProvider>(context);
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: studentProvider.students.length,
      itemBuilder: (context, index) {
        final student = studentProvider.students[index];
        final isPresent = _attendanceStatus[student.id!] ?? true;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // For very narrow screens, use a more compact layout
              if (constraints.maxWidth < 340) {
                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _attendanceStatus[student.id!] = !isPresent;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              radius: 16,
                              child: Text(
                                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: theme.textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (student.rollNumber != null && student.rollNumber!.isNotEmpty)
                                    Text(
                                      'Roll: ${student.rollNumber}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPresent ? 'Present' : 'Absent',
                              style: TextStyle(
                                color: isPresent ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildAttendanceToggle(student.id!, isPresent),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // For wider screens, use the original layout
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(student.name),
                  subtitle: student.rollNumber != null && student.rollNumber!.isNotEmpty
                      ? Text('Roll: ${student.rollNumber}')
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAttendanceToggle(student.id!, isPresent),
                      const SizedBox(width: 8),
                      Text(
                        isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: isPresent ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _attendanceStatus[student.id!] = !isPresent;
                    });
                  },
                );
              }
            },
          ),
        );
      },
    );
  }
  
  Widget _buildAttendanceToggle(int studentId, bool isPresent) {
    return Switch(
      value: isPresent,
      onChanged: (value) {
        HapticFeedback.lightImpact();
        setState(() {
          _attendanceStatus[studentId] = value;
        });
      },
      activeColor: Colors.green,
      inactiveThumbColor: Colors.red,
    );
  }
  
  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: NeoPopButton(
                  color: Colors.grey,
                  onTapUp: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: const Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: NeoPopButton(
                  color: Colors.green,
                  onTapUp: _isSaving ? null : () {
                    HapticFeedback.lightImpact();
                    _saveAttendance();
                  },
                  child: Center(
                    child: _isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Save Attendance',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}