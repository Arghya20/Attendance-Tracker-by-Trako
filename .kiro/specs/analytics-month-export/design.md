# Design Document

## Overview

The Analytics Month Export feature enhances the existing StatisticsScreen by adding a month-specific data export functionality. The feature will be integrated into the current analytics workflow, allowing users to select specific months and view detailed daily attendance data in a tabular format similar to traditional attendance registers.

The design leverages the existing Flutter architecture with Provider pattern for state management, repository pattern for data access, and follows the established UI/UX patterns in the application.

## Architecture

### High-Level Flow
1. User clicks "Export Data" in the Analytics tab (StatisticsScreen)
2. System displays a month selection dialog/screen
3. User selects a specific month
4. System queries attendance data for that month and displays it in a tabular format
5. User can download the displayed data as CSV/Excel file

### Integration Points
- **StatisticsScreen**: Modified to show month selection instead of direct export
- **AttendanceProvider**: Extended with month-specific data retrieval methods
- **AttendanceRepository**: New methods for month-based queries
- **DatabaseHelper**: New queries for month-filtered attendance data

## Components and Interfaces

### 1. Month Selection Dialog
**Component**: `MonthSelectionDialog`
- **Purpose**: Display available months with attendance data
- **Input**: Class ID
- **Output**: Selected month (DateTime)
- **UI Elements**:
  - List of available months in "Month Year" format
  - Loading indicator while fetching months
  - Empty state when no data exists

### 2. Month Export Screen
**Component**: `MonthExportScreen`
- **Purpose**: Display detailed attendance data for selected month
- **Input**: Class ID, Selected month
- **Output**: Tabular attendance view with download capability
- **UI Elements**:
  - Header with month/year and class name
  - Horizontally scrollable table with:
    - Student serial number and name columns (fixed)
    - Daily attendance columns (P/A for each day)
    - Attendance percentage column (fixed)
  - Download button
  - Back navigation

### 3. Enhanced AttendanceProvider
**Methods to Add**:
```dart
// Get all months that have attendance data for a class
Future<List<DateTime>> getAvailableMonths(int classId)

// Get detailed month attendance data
Future<MonthAttendanceData> getMonthAttendanceData(int classId, DateTime month)
```

### 4. Month Attendance Data Model
**New Model**: `MonthAttendanceData`
```dart
class MonthAttendanceData {
  final DateTime month;
  final List<Student> students;
  final List<DateTime> attendanceDays;
  final Map<int, Map<DateTime, bool>> attendanceMatrix; // studentId -> date -> isPresent
  final Map<int, double> attendancePercentages; // studentId -> percentage
}
```

### 5. Enhanced AttendanceRepository
**New Methods**:
```dart
// Get distinct months with attendance sessions for a class
Future<List<DateTime>> getAvailableMonthsForClass(int classId)

// Get all attendance data for a specific month and class
Future<MonthAttendanceData> getMonthAttendanceData(int classId, int year, int month)
```

## Data Models

### MonthAttendanceData
```dart
class MonthAttendanceData {
  final DateTime month;
  final List<Student> students;
  final List<DateTime> attendanceDays;
  final Map<int, Map<DateTime, bool>> attendanceMatrix;
  final Map<int, double> attendancePercentages;
  
  MonthAttendanceData({
    required this.month,
    required this.students,
    required this.attendanceDays,
    required this.attendanceMatrix,
    required this.attendancePercentages,
  });
}
```

### Database Queries
**New queries needed**:
1. Get distinct months with sessions:
```sql
SELECT DISTINCT strftime('%Y-%m', date) as month_year 
FROM attendance_sessions 
WHERE class_id = ? 
ORDER BY month_year DESC
```

2. Get month attendance data:
```sql
SELECT 
  s.id as student_id,
  s.name as student_name,
  s.roll_number,
  sess.date,
  COALESCE(ar.is_present, NULL) as is_present
FROM students s
CROSS JOIN attendance_sessions sess
LEFT JOIN attendance_records ar ON s.id = ar.student_id AND sess.id = ar.session_id
WHERE s.class_id = ? 
  AND sess.class_id = ?
  AND strftime('%Y-%m', sess.date) = ?
ORDER BY s.name, sess.date
```

## Error Handling

### Error Scenarios
1. **No attendance data exists**: Show empty state with helpful message
2. **Network/Database errors**: Display error message with retry option
3. **Export failures**: Show error toast with specific failure reason
4. **Large dataset handling**: Implement pagination or chunking for performance

### Error Recovery
- Retry mechanisms for failed data loads
- Graceful degradation when partial data is available
- User-friendly error messages with actionable guidance

## Testing Strategy

### Unit Tests
1. **MonthAttendanceData model**: Test data structure and calculations
2. **AttendanceRepository methods**: Test month-based queries
3. **AttendanceProvider methods**: Test state management and data flow
4. **Percentage calculations**: Test accuracy of attendance percentage logic

### Widget Tests
1. **MonthSelectionDialog**: Test month list display and selection
2. **MonthExportScreen**: Test table rendering and scrolling
3. **Export functionality**: Test CSV generation and download
4. **Error states**: Test loading and error state displays

### Integration Tests
1. **End-to-end flow**: From month selection to data export
2. **Data consistency**: Verify exported data matches displayed data
3. **Performance**: Test with large datasets (100+ students, full month)

## Implementation Details

### UI/UX Considerations
1. **Responsive Design**: Table should work on mobile and desktop
2. **Performance**: Virtual scrolling for large student lists
3. **Accessibility**: Proper labels and navigation for screen readers
4. **Loading States**: Clear indicators during data fetching

### File Export Format
**CSV Structure**:
```
Student Name,Roll Number,01 Aug,02 Aug,...,31 Aug,Attendance %
John Doe,001,P,A,P,...,P,85%
Jane Smith,002,A,P,P,...,A,92%
```

### Navigation Flow
```
StatisticsScreen 
  → [Export Data] 
  → MonthSelectionDialog 
  → [Select Month] 
  → MonthExportScreen 
  → [Download] 
  → File Export
```

### State Management
- Use existing Provider pattern
- Maintain month selection state
- Cache month data to avoid repeated queries
- Handle loading states consistently

### Performance Optimizations
1. **Lazy loading**: Load month data only when selected
2. **Caching**: Cache month data in provider
3. **Efficient queries**: Use indexed database queries
4. **Virtual scrolling**: For large student lists in table view