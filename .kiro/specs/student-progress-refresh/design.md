# Design Document

## Overview

This design addresses the bug where student progress indicators (attendance percentages) do not refresh automatically after taking attendance. The solution involves implementing a proper data flow mechanism that ensures attendance statistics are updated when attendance records are modified, and the UI reflects these changes immediately.

## Architecture

The fix involves three main components working together:

1. **AttendanceProvider**: Modified to notify dependent providers when attendance is saved
2. **StudentProvider**: Enhanced to invalidate cache and refresh data when attendance changes
3. **ClassDetailScreen**: Updated to listen for attendance changes and trigger refreshes

### Data Flow

```
TakeAttendanceScreen -> AttendanceProvider.saveAttendanceRecords()
                    -> StudentProvider.invalidateAttendanceCache()
                    -> ClassDetailScreen refreshes automatically
```

## Components and Interfaces

### 1. AttendanceProvider Enhancement

**Purpose**: Notify other providers when attendance data changes

**New Methods**:
- `notifyAttendanceUpdated(int classId)`: Broadcasts attendance update events
- Enhanced `saveAttendanceRecords()`: Triggers notifications after successful save

**Interface Changes**:
```dart
class AttendanceProvider extends ChangeNotifier {
  // New callback for attendance updates
  void Function(int classId)? onAttendanceUpdated;
  
  // Enhanced save method
  Future<bool> saveAttendanceRecords(int sessionId, List<AttendanceRecord> records) async {
    // ... existing logic ...
    if (success) {
      // Notify about attendance update
      if (onAttendanceUpdated != null && session != null) {
        onAttendanceUpdated!(session.classId);
      }
    }
    return success;
  }
}
```

### 2. StudentProvider Enhancement

**Purpose**: Respond to attendance updates and refresh cached data

**New Methods**:
- `invalidateAttendanceCache(int classId)`: Clears cached attendance statistics
- `refreshAttendanceStats(int classId)`: Forces reload of attendance data
- Enhanced caching logic to handle attendance updates

**Interface Changes**:
```dart
class StudentProvider extends ChangeNotifier {
  // Cache invalidation tracking
  final Set<int> _invalidatedClasses = {};
  
  // New methods
  void invalidateAttendanceCache(int classId) {
    _invalidatedClasses.add(classId);
    _lastLoadTimeByClass.remove(classId);
    notifyListeners();
  }
  
  Future<void> refreshAttendanceStats(int classId) async {
    if (_currentClassId == classId) {
      await loadStudents(classId);
    }
  }
}
```

### 3. ClassDetailScreen Enhancement

**Purpose**: Coordinate provider interactions and handle navigation events

**New Features**:
- Listen for attendance provider updates
- Refresh student data when returning from attendance screen
- Handle navigation callbacks properly

**Implementation**:
```dart
class _ClassDetailScreenState extends State<ClassDetailScreen> {
  @override
  void initState() {
    super.initState();
    // ... existing code ...
    
    // Set up attendance update listener
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    attendanceProvider.onAttendanceUpdated = _onAttendanceUpdated;
  }
  
  void _onAttendanceUpdated(int classId) {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    studentProvider.invalidateAttendanceCache(classId);
    studentProvider.refreshAttendanceStats(classId);
  }
  
  void _takeAttendance(BuildContext context, Class classItem) async {
    final result = await NavigationService.navigateTo(
      context,
      TakeAttendanceScreen(classItem: classItem),
      transitionType: TransitionType.slide,
    );
    
    // Refresh data when returning from attendance screen
    if (result == true) {
      _onAttendanceUpdated(classItem.id!);
    }
  }
}
```

## Data Models

### AttendanceUpdateEvent

**Purpose**: Standardize attendance update notifications

```dart
class AttendanceUpdateEvent {
  final int classId;
  final int sessionId;
  final DateTime timestamp;
  
  AttendanceUpdateEvent({
    required this.classId,
    required this.sessionId,
    required this.timestamp,
  });
}
```

## Error Handling

### Refresh Failure Scenarios

1. **Database Connection Issues**
   - Show error message with retry option
   - Maintain existing cached data until refresh succeeds

2. **Network/Performance Issues**
   - Implement timeout for refresh operations (2 seconds)
   - Graceful degradation with cached data

3. **Concurrent Update Conflicts**
   - Use optimistic locking approach
   - Last update wins strategy

### Error Recovery

```dart
Future<void> _handleRefreshError(String error) async {
  CustomSnackBar.show(
    context: context,
    message: 'Failed to refresh attendance data: $error',
    type: SnackBarType.error,
    action: SnackBarAction(
      label: 'Retry',
      onPressed: () => _refreshStudentData(),
    ),
  );
}
```

## Testing Strategy

### Unit Tests

1. **AttendanceProvider Tests**
   - Verify notification callbacks are triggered
   - Test saveAttendanceRecords with callback
   - Mock provider interactions

2. **StudentProvider Tests**
   - Test cache invalidation logic
   - Verify refresh behavior
   - Test concurrent update handling

3. **Integration Tests**
   - End-to-end attendance flow
   - Navigation and refresh coordination
   - Error handling scenarios

### Widget Tests

1. **ClassDetailScreen Tests**
   - Verify UI updates after attendance changes
   - Test navigation callbacks
   - Progress indicator refresh behavior

2. **StudentListItem Tests**
   - Progress indicator updates
   - Percentage calculation accuracy
   - Visual state changes

### Test Scenarios

```dart
testWidgets('should refresh progress indicators after taking attendance', (tester) async {
  // Setup: Navigate to class detail screen
  // Action: Take attendance and return
  // Verify: Progress indicators show updated percentages
});

testWidgets('should handle refresh errors gracefully', (tester) async {
  // Setup: Mock database error
  // Action: Trigger refresh
  // Verify: Error message shown with retry option
});
```

## Performance Considerations

### Optimization Strategies

1. **Selective Refresh**
   - Only refresh data for the current class
   - Avoid unnecessary database queries

2. **Caching Strategy**
   - Maintain cache validity tracking
   - Implement smart cache invalidation

3. **UI Responsiveness**
   - Use RepaintBoundary for progress indicators
   - Minimize widget rebuilds during refresh

### Memory Management

- Clear invalidated cache entries periodically
- Limit cache size to prevent memory leaks
- Use weak references for callback listeners

## Implementation Phases

### Phase 1: Provider Enhancement
- Modify AttendanceProvider to support callbacks
- Enhance StudentProvider cache management
- Add notification mechanisms

### Phase 2: UI Integration
- Update ClassDetailScreen navigation handling
- Implement refresh coordination
- Add error handling UI

### Phase 3: Testing & Polish
- Comprehensive test coverage
- Performance optimization
- Error scenario handling

## Migration Strategy

This is a bug fix that enhances existing functionality without breaking changes:

1. **Backward Compatibility**: All existing APIs remain unchanged
2. **Incremental Rollout**: Changes can be deployed incrementally
3. **Fallback Behavior**: Manual refresh still works if automatic refresh fails