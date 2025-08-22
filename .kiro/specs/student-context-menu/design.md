# Design Document

## Overview

This design implements tap-and-hold functionality for student list items by creating a reusable StudentContextMenu widget and integrating it with the existing StudentListItem. The solution maintains consistency with the existing PinContextMenu design while adapting it for student-specific actions. The implementation preserves existing swipe-to-reveal functionality and ensures both interaction methods work harmoniously.

## Architecture

### Component Structure

```
StudentListItem (existing)
├── GestureDetector (enhanced with onLongPress)
├── Slidable (existing swipe functionality)
└── Card/InkWell (existing tap functionality)

StudentContextMenu (new)
├── Dialog container
├── Header section (student info)
├── Menu items (edit/delete)
└── Cancel button
```

### Integration Points

1. **StudentListItem Enhancement**: Add onLongPress callback to existing InkWell
2. **Context Menu Creation**: New StudentContextMenu widget following PinContextMenu pattern
3. **Screen Integration**: Update ClassDetailScreen to handle context menu actions
4. **Gesture Coordination**: Ensure long press and swipe gestures don't conflict

## Components and Interfaces

### StudentContextMenu Widget

```dart
class StudentContextMenu extends StatelessWidget {
  final Student student;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;

  // Static show method for easy invocation
  static Future<void> show({
    required BuildContext context,
    required Student student,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onCancel,
  });
}
```

### StudentListItem Enhancement

```dart
class StudentListItem extends StatelessWidget {
  // Existing properties...
  final VoidCallback? onLongPress; // New property

  // Enhanced InkWell with onLongPress
  InkWell(
    onTap: onTap,
    onLongPress: () {
      HapticFeedback.mediumImpact();
      onLongPress?.call();
    },
    // ... existing properties
  )
}
```

### ClassDetailScreen Integration

```dart
// New method in _ClassDetailScreenState
void _showStudentContextMenu(BuildContext context, Student student) {
  StudentContextMenu.show(
    context: context,
    student: student,
    onEdit: () => _showEditStudentDialog(context, classItem.id!, student),
    onDelete: () => _showDeleteStudentConfirmation(context, student),
  );
}

// Enhanced StudentListItem usage
StudentListItem(
  student: student,
  onTap: () => _showStudentDetails(context, student),
  onEdit: () => _showEditStudentDialog(context, classItem.id!, student),
  onDelete: () => _showDeleteStudentConfirmation(context, student),
  onLongPress: () => _showStudentContextMenu(context, student), // New
)
```

## Data Models

### Student Model Usage

The existing Student model will be used without modifications:

```dart
class Student {
  final int? id;
  final String name;
  final String? rollNumber;
  final int classId;
  final double? attendancePercentage;
  // ... other properties
}
```

### Context Menu State

No persistent state required - the context menu is stateless and derives all information from the passed Student object.

## Error Handling

### Gesture Conflict Prevention

1. **Long Press Detection**: Use appropriate duration (500ms) to avoid conflicts with tap
2. **Swipe Gesture Coordination**: Ensure Slidable widget doesn't interfere with long press
3. **Touch Area Management**: Maintain proper touch targets for all interaction methods

### Menu Display Errors

1. **Screen Boundary Checks**: Ensure menu fits within screen bounds
2. **Keyboard Handling**: Adjust menu position when keyboard is visible
3. **Orientation Changes**: Handle menu repositioning during device rotation

### Action Execution Errors

1. **Context Validation**: Verify context is still valid before executing actions
2. **Student Existence**: Ensure student still exists before performing operations
3. **Permission Checks**: Validate user permissions for edit/delete operations

## Testing Strategy

### Unit Tests

1. **StudentContextMenu Widget Tests**
   - Menu rendering with student data
   - Action callback execution
   - Cancel functionality
   - Accessibility properties

2. **StudentListItem Enhancement Tests**
   - Long press gesture detection
   - Haptic feedback triggering
   - Gesture coordination with existing functionality

### Widget Tests

1. **Context Menu Integration Tests**
   - Menu display on long press
   - Menu dismissal on outside tap
   - Action execution flow
   - Visual consistency with design

2. **Gesture Interaction Tests**
   - Long press vs tap differentiation
   - Swipe vs long press coordination
   - Multi-touch handling

### Integration Tests

1. **End-to-End Workflow Tests**
   - Long press → context menu → edit student
   - Long press → context menu → delete student
   - Context menu → cancel → return to list

2. **Cross-Platform Tests**
   - Mobile device interaction
   - Tablet layout adaptation
   - Accessibility feature compatibility

### Visual Regression Tests

1. **Design Consistency Tests**
   - Context menu visual matching with PinContextMenu
   - Proper theming application
   - Responsive layout behavior

2. **Animation Tests**
   - Menu appearance/dismissal animations
   - Haptic feedback timing
   - Smooth gesture transitions

## Implementation Notes

### Design Consistency

The StudentContextMenu will follow the exact visual pattern of PinContextMenu:
- Same dialog container styling
- Consistent header design with student avatar/name
- Identical menu item layout and typography
- Matching color scheme and spacing

### Performance Considerations

1. **Widget Optimization**: Use RepaintBoundary for context menu to prevent unnecessary repaints
2. **Memory Management**: Ensure proper disposal of gesture recognizers
3. **Animation Efficiency**: Reuse animation controllers where possible

### Accessibility Features

1. **Semantic Labels**: Provide clear labels for screen readers
2. **Focus Management**: Proper focus handling for keyboard navigation
3. **High Contrast Support**: Ensure visibility in high contrast modes
4. **Voice Control**: Support for voice-activated interactions

### Platform Adaptations

1. **iOS Haptics**: Use appropriate haptic feedback patterns
2. **Android Material**: Follow Material Design guidelines
3. **Touch Targets**: Ensure minimum 44pt touch targets
4. **Safe Areas**: Respect device safe areas and notches