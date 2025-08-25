import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';
import 'package:attendance_tracker/widgets/error_message.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthExportScreen extends StatefulWidget {
  final Class classItem;
  final DateTime selectedMonth;
  final MonthAttendanceData? monthData;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  
  const MonthExportScreen({
    super.key,
    required this.classItem,
    required this.selectedMonth,
    this.monthData,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<MonthExportScreen> createState() => _MonthExportScreenState();
}

class _MonthExportScreenState extends State<MonthExportScreen> {
  bool _isExporting = false;
  
  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(widget.selectedMonth);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Report'),
            Text(
              monthName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.monthData != null && !widget.monthData!.isEmpty)
            TextButton.icon(
              icon: _isExporting 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_isExporting ? 'Saving...' : 'Save'),
              onPressed: _isExporting ? null : _exportData,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (widget.isLoading) {
      return const LoadingIndicator(message: 'Loading attendance data...');
    }
    
    if (widget.errorMessage != null) {
      return ErrorMessage(
        message: widget.errorMessage!,
        onRetry: widget.onRetry,
      );
    }
    
    if (widget.monthData == null || widget.monthData!.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildAttendanceTable();
  }
  
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(widget.selectedMonth);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Attendance Data',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No attendance sessions were recorded for $monthName.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttendanceTable() {
    final monthData = widget.monthData!;
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildSummaryCard(monthData),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_chart,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Attendance',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildDataTable(monthData),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(MonthAttendanceData monthData) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(widget.selectedMonth);
    
    // Calculate overall statistics
    int totalPresent = 0;
    int totalAbsent = 0;
    
    for (final student in monthData.students) {
      totalPresent += monthData.getPresentCount(student.id!);
      totalAbsent += monthData.getAbsentCount(student.id!);
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
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$monthName Summary',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Students',
                  '${monthData.studentCount}',
                  Colors.blue,
                  Icons.people,
                ),
                _buildStatCard(
                  'Sessions',
                  '${monthData.attendanceDayCount}',
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
  
  Widget _buildDataTable(MonthAttendanceData monthData) {
    final theme = Theme.of(context);
    
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 16,
      headingRowHeight: 56,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 48,
      border: TableBorder.all(
        color: theme.dividerColor,
        width: 1,
      ),
      columns: _buildTableColumns(monthData),
      rows: _buildTableRows(monthData),
    );
  }
  
  List<DataColumn> _buildTableColumns(MonthAttendanceData monthData) {
    final columns = <DataColumn>[
      const DataColumn(
        label: Text(
          'SL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Name',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];
    
    // Add date columns
    for (final date in monthData.attendanceDays) {
      final dayFormat = DateFormat('dd');
      final monthFormat = DateFormat('MMM');
      
      columns.add(
        DataColumn(
          label: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayFormat.format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                monthFormat.format(date),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Add percentage column
    columns.add(
      const DataColumn(
        label: Text(
          'Percentage',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
    
    return columns;
  }
  
  List<DataRow> _buildTableRows(MonthAttendanceData monthData) {
    final rows = <DataRow>[];
    
    for (int i = 0; i < monthData.students.length; i++) {
      final student = monthData.students[i];
      final percentage = monthData.getAttendancePercentage(student.id!);
      
      final cells = <DataCell>[
        DataCell(
          Text(
            '${i + 1}'.padLeft(2, '0'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            student.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ];
      
      // Add attendance cells
      for (final date in monthData.attendanceDays) {
        final isPresent = monthData.getAttendanceStatus(student.id!, date);
        
        cells.add(
          DataCell(
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isPresent == true 
                    ? Colors.green.withOpacity(0.1)
                    : isPresent == false
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  isPresent == true 
                      ? 'P'
                      : isPresent == false
                          ? 'A'
                          : '-',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPresent == true 
                        ? Colors.green
                        : isPresent == false
                            ? Colors.red
                            : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      
      // Add percentage cell
      cells.add(
        DataCell(
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getAttendanceColor(percentage),
            ),
          ),
        ),
      );
      
      rows.add(DataRow(cells: cells));
    }
    
    return rows;
  }
  
  Future<void> _exportData() async {
    if (widget.monthData == null || widget.monthData!.isEmpty) return;
    
    setState(() {
      _isExporting = true;
    });
    
    try {
      final monthData = widget.monthData!;
      final monthName = DateFormat('MMMM yyyy').format(widget.selectedMonth);
      final fileName = 'Attendance Tracker - ${widget.classItem.name} $monthName.pdf';
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Calculate overall statistics
      int totalPresent = 0;
      int totalAbsent = 0;
      
      for (final student in monthData.students) {
        totalPresent += monthData.getPresentCount(student.id!);
        totalAbsent += monthData.getAbsentCount(student.id!);
      }
      
      final totalAttendance = totalPresent + totalAbsent;
      final overallPercentage = totalAttendance > 0
          ? (totalPresent / totalAttendance) * 100
          : 0.0;
      
      // Create table headers
      final headers = <String>['SL', 'Name'];
      
      // Add date headers
      for (final date in monthData.attendanceDays) {
        final dateStr = DateFormat('dd\nMMM').format(date);
        headers.add(dateStr);
      }
      headers.add('Percentage');
      
      // Create table data
      final tableData = <List<String>>[];
      
      for (int i = 0; i < monthData.students.length; i++) {
        final student = monthData.students[i];
        final percentage = monthData.getAttendancePercentage(student.id!);
        
        final row = <String>[
          '${i + 1}'.padLeft(2, '0'),
          student.name,
        ];
        
        // Add attendance data
        for (final date in monthData.attendanceDays) {
          final isPresent = monthData.getAttendanceStatus(student.id!, date);
          row.add(isPresent == true ? 'P' : isPresent == false ? 'A' : '-');
        }
        
        row.add('${percentage.toStringAsFixed(0)}%');
        tableData.add(row);
      }
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Header
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Attendance Report',
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
                    'Month: $monthName',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated on: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
              
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
                        pw.Text('Students', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${monthData.studentCount}'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Sessions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${monthData.attendanceDayCount}'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Overall Attendance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${overallPercentage.toStringAsFixed(1)}%'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Present', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                        pw.Text('$totalPresent'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Absent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                        pw.Text('$totalAbsent'),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Attendance Table with dynamic column sizing
              _buildPdfAttendanceTable(monthData, headers, tableData),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Text(
                'Legend: P = Present, A = Absent, - = No Session',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ];
          },
        ),
      );
      
      // Show print dialog directly
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );
      
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Print dialog opened successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to save report: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
  
  pw.Widget _buildPdfAttendanceTable(MonthAttendanceData monthData, List<String> headers, List<List<String>> tableData) {
    // Calculate available space for date columns
    final totalDays = monthData.attendanceDayCount;
    final availableWidth = 800.0; // Approximate A4 landscape width minus margins
    final slWidth = 25.0;
    final nameWidth = totalDays > 25 ? 80.0 : 120.0; // Reduce name width for months with many days
    final percentageWidth = 50.0;
    final remainingWidth = availableWidth - slWidth - nameWidth - percentageWidth;
    final dateColumnWidth = remainingWidth / totalDays;
    
    // Use appropriate font sizes for readability
    final headerFontSize = totalDays > 25 ? 8.0 : 10.0;
    final cellFontSize = totalDays > 25 ? 7.0 : 9.0;
    final nameFontSize = totalDays > 25 ? 8.0 : 9.0;
    
    // Build column widths map
    final columnWidths = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(slWidth), // SL
      1: pw.FixedColumnWidth(nameWidth), // Name
    };
    
    // Add date column widths
    for (int i = 2; i < headers.length - 1; i++) {
      columnWidths[i] = pw.FixedColumnWidth(dateColumnWidth);
    }
    columnWidths[headers.length - 1] = pw.FixedColumnWidth(percentageWidth); // Percentage
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: columnWidths,
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.asMap().entries.map((entry) {
            final index = entry.key;
            final header = entry.value;
            
            return pw.Container(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: headerFontSize,
                ),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
              ),
            );
          }).toList(),
        ),
        
        // Data rows
        ...tableData.map((row) => 
          pw.TableRow(
            children: row.asMap().entries.map((entry) {
              final index = entry.key;
              final cell = entry.value;
              
              // Color coding for attendance
              PdfColor? backgroundColor;
              PdfColor textColor = PdfColors.black;
              
              if (index > 1 && index < row.length - 1) { // Attendance columns
                if (cell == 'P') {
                  backgroundColor = PdfColors.green100;
                  textColor = PdfColors.green800;
                } else if (cell == 'A') {
                  backgroundColor = PdfColors.red100;
                  textColor = PdfColors.red800;
                }
              }
              
              return pw.Container(
                padding: const pw.EdgeInsets.all(2),
                decoration: backgroundColor != null 
                    ? pw.BoxDecoration(color: backgroundColor)
                    : null,
                child: pw.Text(
                  cell,
                  style: pw.TextStyle(
                    fontSize: index == 1 ? nameFontSize : cellFontSize,
                    color: textColor,
                    fontWeight: index == 0 || index == 1 || index == row.length - 1 
                        ? pw.FontWeight.bold 
                        : pw.FontWeight.normal,
                  ),
                  textAlign: index == 1 
                      ? pw.TextAlign.left 
                      : pw.TextAlign.center,
                  maxLines: index == 1 ? 2 : 1,
                  overflow: pw.TextOverflow.clip,
                ),
              );
            }).toList(),
          ),
        ).toList(),
      ],
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
}