# Design Document

## Overview

The month filter feature enhances the Attendance History screen's Student View by adding a month selection dropdown that allows teachers to filter attendance records by specific months. This provides better data analysis capabilities and improves the user experience when reviewing historical attendance data.

## Architecture

The feature will be implemented as an enhancement to the existing `AttendanceHistoryScreen` widget, specifically in the Student View tab. The implementation will:

1. Add month filtering state management to the existing screen state
2. Create a month selection UI component
3. Implement filtering logic for attendance records
4. Update statistics calculations to work with filtered data

## Components and Interfaces

### State Management

New state variables to be added to `_AttendanceHistoryScreenState`:

```dart
DateTime? _selectedMonth; // Selected month for filtering (null = show all)
List<DateTime> _availableMonths = []; // Months with attendance data for selected student
```

### UI Components

#### Month Selection Dropdown
- **Location**: Below the student selection dropdown in the Student View tab
- **Behavior**: 
  - Only visible when a student is selected
  - Populated with months that have attendance records for the selected student
  - Includes an "All Months" option to clear the filter
- **Styling**: Consistent with existing form elements using `DropdownButtonFormField`

#### Filter Status Indicator
- **Location**: In the attendance history section header
- **Behavior**: Shows current filter state (e.g., "Showing records for March 2025" or "Showing all records")
- **Styling**: Subtle text below the "Attendance History" title

### Data Flow

1. **Student Selection**: When a student is selected, calculate available months from their attendance records
2. **Month Selection**: When a month is selected, filter attendance records and recalculate statistics
3. **Statistics Update**: Attendance percentage, status, and progress bar update based on filtered data
4. **Record Display**: ListView shows only records matching the selected month

## Data Models

No new data models required. The feature will work with existing models:
- `Student` - for selected student information
- `AttendanceRecord` - for filtering attendance data by date

## Error Handling

### Month Calculation Errors
- **Scenario**: Error while calculating available months from attendance records
- **Handling**: Log error, disable month dropdown, show error message
- **Recovery**: Retry when student selection changes

### Filtering Errors
- **Scenario**: Error while filtering attendance records by month
- **Handling**: Reset to show all records, display error snackbar
- **Recovery**: Allow user to retry month selection

### Empty Results
- **Scenario**: Selected month has no attendance records (edge case)
- **Handling**: Show "No records found for selected month" message
- **Recovery**: Allow user to select different month or clear filter

## Testing Strategy

### Unit Tests
1. **Month Calculation Logic**
   - Test extraction of unique months from attendance records
   - Test sorting of months in chronological order
   - Test handling of empty attendance records

2. **Filtering Logic**
   - Test filtering records by selected month
   - Test statistics calculation with filtered data
   - Test clearing of month filter

3. **State Management**
   - Test state updates when student changes
   - Test state updates when month selection changes
   - Test state reset scenarios

### Widget Tests
1. **Month Dropdown Component**
   - Test dropdown visibility based on student selection
   - Test dropdown population with available months
   - Test month selection interaction

2. **Filter Status Display**
   - Test status text updates based on filter state
   - Test visual indicators for active filters

3. **Statistics Updates**
   - Test attendance percentage updates with filtered data
   - Test progress bar updates with filtered data
   - Test status text updates (Excellent/Good/etc.)

### Integration Tests
1. **End-to-End Filtering**
   - Test complete flow: select student → select month → view filtered results
   - Test filter clearing and statistics reset
   - Test switching between different months

2. **Data Consistency**
   - Test that filtered statistics match filtered records
   - Test that clearing filter restores original statistics

## Implementation Details

### Month Extraction Algorithm
```dart
List<DateTime> _extractAvailableMonths(List<Map<String, dynamic>> records) {
  final Set<DateTime> months = {};
  
  for (final record in records) {
    final date = DateTime.parse(record['session_date']);
    final monthYear = DateTime(date.year, date.month);
    months.add(monthYear);
  }
  
  final sortedMonths = months.toList()..sort((a, b) => b.compareTo(a));
  return sortedMonths;
}
```

### Filtering Logic
```dart
List<Map<String, dynamic>> _getFilteredRecords(List<Map<String, dynamic>> allRecords) {
  if (_selectedMonth == null) return allRecords;
  
  return allRecords.where((record) {
    final date = DateTime.parse(record['session_date']);
    return date.year == _selectedMonth!.year && date.month == _selectedMonth!.month;
  }).toList();
}
```

### Statistics Calculation
```dart
double _calculateFilteredAttendancePercentage(List<Map<String, dynamic>> filteredRecords) {
  if (filteredRecords.isEmpty) return 0.0;
  
  final presentCount = filteredRecords.where((r) => r['is_present'] == 1).length;
  return (presentCount / filteredRecords.length) * 100;
}
```

## User Experience Considerations

### Progressive Disclosure
- Month dropdown only appears after student selection to avoid overwhelming the interface
- Clear visual hierarchy with student selection first, then month filtering

### Performance
- Month calculation happens only when student changes to avoid unnecessary computations
- Filtering is performed on already-loaded data for responsive interaction

### Accessibility
- Month dropdown includes proper labels and hints
- Filter status is announced to screen readers
- Clear visual indicators for active filters

### Responsive Design
- Month dropdown adapts to different screen sizes
- Filter status text wraps appropriately on smaller screens
- Maintains consistency with existing responsive patterns