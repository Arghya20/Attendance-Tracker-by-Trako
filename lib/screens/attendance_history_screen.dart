import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';
import 'package:attendance_tracker/widgets/error_message.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/widgets/confirmation_dialog.dart';
import 'package:attendance_tracker/widgets/edit_attendance_dialog.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final Class classItem;
  
  const AttendanceHistoryScreen({
    super.key,
    required this.classItem,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;
  String? _errorMessage;
  Map<DateTime, List<AttendanceSession>> _sessions = {};
  List<Student> _students = [];
  int? _selectedStudentId;
  AttendanceSession? _selectedSession;
  List<Map<String, dynamic>> _attendanceRecords = [];
  
  // Month filtering state variables
  DateTime? _selectedMonth;
  List<DateTime> _availableMonths = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize month filtering state variables
    _selectedMonth = null;
    _availableMonths = [];
    
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Load sessions
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.loadSessions(widget.classItem.id!);
      
      // Load students
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      await studentProvider.loadStudents(widget.classItem.id!);
      
      if (mounted) {
        setState(() {
          _sessions = _groupSessionsByDay(attendanceProvider.sessions);
          _students = studentProvider.students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load attendance data: $e';
        });
      }
    }
  }
  
  Map<DateTime, List<AttendanceSession>> _groupSessionsByDay(List<AttendanceSession> sessions) {
    final Map<DateTime, List<AttendanceSession>> result = {};
    
    for (final session in sessions) {
      final date = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      
      if (result.containsKey(date)) {
        result[date]!.add(session);
      } else {
        result[date] = [session];
      }
    }
    
    return result;
  }
  
  Future<void> _loadSessionDetails(AttendanceSession session) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedSession = session;
    });
    
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.loadAttendanceRecords(session.id!);
      final records = attendanceProvider.attendanceWithStudentInfo;
      
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
          _errorMessage = 'Failed to load attendance details: $e';
        });
      }
    }
  }
  
  Future<void> _deleteSession(AttendanceSession session) async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    final success = await attendanceProvider.deleteSession(session.id!);
    
    if (!mounted) return;
    
    if (success) {
      CustomSnackBar.show(
        context: context,
        message: 'Attendance record deleted successfully',
        type: SnackBarType.success,
      );
      
      // Reload data
      _loadData();
      
      // Clear selection
      setState(() {
        _selectedSession = null;
        _attendanceRecords = [];
      });
    } else {
      CustomSnackBar.show(
        context: context,
        message: attendanceProvider.error ?? 'Failed to delete attendance record',
        type: SnackBarType.error,
      );
    }
  }
  
  List<Map<String, dynamic>> _getFilteredRecords() {
    if (_selectedStudentId == null) {
      return _attendanceRecords;
    }
    
    return _attendanceRecords
        .where((record) => record['student_id'] == _selectedStudentId)
        .toList();
  }
  
  /// Extracts unique months from attendance records for the selected student
  /// Returns months sorted in chronological order (most recent first)
  List<DateTime> _extractAvailableMonths(List<Map<String, dynamic>> attendanceRecords) {
    if (attendanceRecords.isEmpty) {
      return [];
    }
    
    try {
      // Extract unique months from attendance records
      final Set<DateTime> monthsSet = {};
      
      for (final record in attendanceRecords) {
        final dateStr = record['session_date'] as String?;
        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          // Create a DateTime representing the first day of the month
          final monthDate = DateTime(date.year, date.month, 1);
          monthsSet.add(monthDate);
        }
      }
      
      // Convert to list and sort in chronological order (most recent first)
      final monthsList = monthsSet.toList();
      monthsList.sort((a, b) => b.compareTo(a)); // Descending order (most recent first)
      
      return monthsList;
    } catch (e) {
      // Handle errors in month extraction
      debugPrint('Error extracting available months: $e');
      _showFilteringError('month extraction');
      return [];
    }
  }
  
  /// Filters attendance records by the selected month
  /// Returns all records if no month is selected (null)
  List<Map<String, dynamic>> _getFilteredAttendanceRecords(List<Map<String, dynamic>> attendanceRecords) {
    // If no month is selected, return all records
    if (_selectedMonth == null) {
      return attendanceRecords;
    }
    
    try {
      return attendanceRecords.where((record) {
        final dateStr = record['session_date'] as String?;
        if (dateStr == null) return false;
        
        final recordDate = DateTime.parse(dateStr);
        // Check if the record's month and year match the selected month
        return recordDate.year == _selectedMonth!.year && 
               recordDate.month == _selectedMonth!.month;
      }).toList();
    } catch (e) {
      // Handle errors in record filtering
      debugPrint('Error filtering attendance records: $e');
      _showFilteringError('record filtering');
      return attendanceRecords; // Return unfiltered records on error
    }
  }
  
  /// Calculates attendance statistics from filtered records
  Map<String, dynamic> _calculateAttendanceStats(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return {
        'percentage': 0.0,
        'presentCount': 0,
        'totalCount': 0,
      };
    }
    
    try {
      final presentCount = records.where((record) => record['is_present'] == 1).length;
      final totalCount = records.length;
      final percentage = totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;
      
      return {
        'percentage': percentage,
        'presentCount': presentCount,
        'totalCount': totalCount,
      };
    } catch (e) {
      // Handle errors in statistics calculation
      debugPrint('Error calculating attendance statistics: $e');
      _showFilteringError('statistics calculation');
      return {
        'percentage': 0.0,
        'presentCount': 0,
        'totalCount': 0,
      };
    }
  }
  
  /// Shows error message to user with recovery options
  void _showFilteringError(String operation) {
    if (mounted) {
      CustomSnackBar.show(
        context: context,
        message: 'Error in $operation. Please try refreshing the data.',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Calendar View'),
            Tab(text: 'Student View'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading attendance data...')
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
    
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCalendarView(),
        _buildStudentView(),
      ],
    );
  }
  
  Widget _buildCalendarView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCalendar(),
          const Divider(),
          _selectedDay != null
              ? _buildSessionList()
              : const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('Select a date to view attendance records'),
                  ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildCalendar() {
    final theme = Theme.of(context);
    
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: (day) {
        final normalizedDay = DateTime(day.year, day.month, day.day);
        return _sessions[normalizedDay] ?? [];
      },
      selectedDayPredicate: (day) {
        return _selectedDay != null &&
            day.year == _selectedDay!.year &&
            day.month == _selectedDay!.month &&
            day.day == _selectedDay!.day;
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          _selectedSession = null;
          _attendanceRecords = [];
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
  
  Widget _buildSessionList() {
    final normalizedDay = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final sessionsForDay = _sessions[normalizedDay] ?? [];
    
    if (sessionsForDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No attendance records for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
              style: AppConstants.subheadingStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Text(
            'Attendance for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        // Sessions list
        ...sessionsForDay.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final isSelected = _selectedSession?.id == session.id;
          
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              title: Text(
                'Session ${index + 1}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              subtitle: Text(
                'Created: ${DateFormat('h:mm a').format(session.createdAt)}',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : null,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditAttendanceDialog(session),
                    tooltip: 'Edit',
                    color: isSelected ? Colors.white : Colors.blue,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(session),
                    tooltip: 'Delete',
                    color: Colors.red,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _loadSessionDetails(session),
            ),
          );
        }).toList(),
        if (_selectedSession != null) ...[
          const Divider(),
          _buildAttendanceDetails(),
        ],
      ],
    );
  }
  
  Widget _buildAttendanceDetails() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading attendance details...');
    }
    
    if (_attendanceRecords.isEmpty) {
      return const Center(
        child: Text('No attendance records found for this session'),
      );
    }
    
    final presentCount = _attendanceRecords.where((r) => r['is_present'] == 1).length;
    final totalCount = _attendanceRecords.length;
    final presentPercentage = totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCard(
                    'Present',
                    '$presentCount',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    'Absent',
                    '${totalCount - presentCount}',
                    Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    'Percentage',
                    '${presentPercentage.toStringAsFixed(1)}%',
                    presentPercentage >= 75 ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Show all students without ListView.builder constraints
        ..._attendanceRecords.map((record) {
          final isPresent = record['is_present'] == 1;
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isPresent ? Colors.green : Colors.red,
              child: Icon(
                isPresent ? Icons.check : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(record['student_name']),
            subtitle: record['student_roll_number'] != null
                ? Text('Roll: ${record['student_roll_number']}')
                : null,
            trailing: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: isPresent ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 20), // Add some bottom padding
      ],
    );
  }
  
  Widget _buildStudentView() {
    if (_students.isEmpty) {
      return const Center(
        child: Text('No students found in this class'),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStudentFilter(),
          SizedBox(
            height: 600, // Fixed height for the student attendance section
            child: _selectedStudentId != null
                ? _buildStudentAttendance()
                : const Center(
                    child: Text('Select a student to view attendance records'),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentFilter() {
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Student',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedStudentId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              hint: const Text('Select a student'),
              items: _students.map((student) {
                return DropdownMenuItem<int>(
                  value: student.id,
                  child: Text(student.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStudentId = value;
                  // Reset month filtering state when student selection changes
                  _selectedMonth = null;
                  _availableMonths = [];
                });
              },
            ),
            // Month selection dropdown - only show when student is selected and has available months
            if (_selectedStudentId != null && _availableMonths.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Filter by Month',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DateTime?>(
                value: _selectedMonth,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                hint: const Text('All Months'),
                items: [
                  // "All Months" option
                  const DropdownMenuItem<DateTime?>(
                    value: null,
                    child: Text('All Months'),
                  ),
                  // Available months
                  ..._availableMonths.map((month) {
                    return DropdownMenuItem<DateTime?>(
                      value: month,
                      child: Text(DateFormat('MMMM yyyy').format(month)),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStudentAttendance() {
    if (_selectedStudentId == null) {
      return const SizedBox.shrink();
    }
    
    final student = _students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => Student(classId: -1, name: 'Unknown'),
    );
    
    if (student.id == null) {
      return const Center(
        child: Text('Student not found'),
      );
    }
    
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _selectedMonth != null 
                    ? 'Showing records for ${DateFormat('MMMM yyyy').format(_selectedMonth!)}'
                    : 'Showing all records',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: Provider.of<AttendanceProvider>(context, listen: false)
                .getStudentAttendance(student.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }
              
              if (snapshot.hasError) {
                return ErrorMessage(
                  message: 'Failed to load attendance history: ${snapshot.error}',
                  onRetry: () => setState(() {}),
                );
              }
              
              final allRecords = snapshot.data ?? [];
              
              // Update available months when data is loaded
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  final availableMonths = _extractAvailableMonths(allRecords);
                  if (_availableMonths.length != availableMonths.length ||
                      !_availableMonths.every((month) => availableMonths.contains(month))) {
                    setState(() {
                      _availableMonths = availableMonths;
                      // Reset month selection if it's no longer available
                      if (_selectedMonth != null && !_availableMonths.contains(_selectedMonth)) {
                        _selectedMonth = null;
                      }
                    });
                  }
                } catch (e) {
                  debugPrint('Error updating available months: $e');
                  _showFilteringError('month data update');
                }
              });
              
              // Apply month filtering
              final filteredRecords = _getFilteredAttendanceRecords(allRecords);
              
              if (allRecords.isEmpty) {
                return const Center(
                  child: Text('No attendance records found for this student'),
                );
              }
              
              if (filteredRecords.isEmpty && _selectedMonth != null) {
                return Center(
                  child: Text(
                    'No attendance records found for ${DateFormat('MMMM yyyy').format(_selectedMonth!)}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              // Calculate attendance statistics from filtered records
              final stats = _calculateAttendanceStats(filteredRecords);
              final attendancePercentage = stats['percentage'] as double;
              
              return Column(
                children: [
                  // Student statistics card
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                child: Text(
                                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
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
                                      student.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    if (student.rollNumber != null && student.rollNumber!.isNotEmpty)
                                      Text(
                                        'Roll Number: ${student.rollNumber}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: attendancePercentage / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getAttendanceColor(attendancePercentage),
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Attendance: ${attendancePercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getAttendanceColor(attendancePercentage),
                                ),
                              ),
                              Text(
                                _getAttendanceStatus(attendancePercentage),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getAttendanceColor(attendancePercentage),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Present: ${stats['presentCount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Absent: ${stats['totalCount'] - stats['presentCount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                'Total: ${stats['totalCount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Attendance records list
                  Expanded(
                    child: ListView.builder(
                itemCount: filteredRecords.length,
                itemBuilder: (context, index) {
                  final record = filteredRecords[index];
                  final date = DateTime.parse(record['session_date']);
                  final isPresent = record['is_present'] == 1;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                      vertical: AppConstants.smallPadding / 2,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPresent ? Colors.green : Colors.red,
                        child: Icon(
                          isPresent ? Icons.check : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(DateFormat('EEEE, MMMM d, yyyy').format(date)),
                      trailing: Text(
                        isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: isPresent ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                    },
                  ),
                ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String label, String value, Color color) {
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
      ),
    );
  }
  
  void _showEditAttendanceDialog(AttendanceSession session) async {
    if (_attendanceRecords.isEmpty) {
      await _loadSessionDetails(session);
    }
    
    if (!mounted) return;
    
    if (_attendanceRecords.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'No attendance records found for this session',
        type: SnackBarType.warning,
      );
      return;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditAttendanceDialog(
        session: session,
        attendanceRecords: _attendanceRecords,
      ),
    );
    
    if (result == true && mounted) {
      // Reload session details
      _loadSessionDetails(session);
    }
  }
  
  void _showDeleteConfirmation(AttendanceSession session) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Attendance Record',
        message: 'Are you sure you want to delete this attendance record? '
            'This action cannot be undone.',
        confirmText: 'Delete',
        onConfirm: () => _deleteSession(session),
        icon: Icons.delete_forever,
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