# Design Document

## Overview

This design addresses the bug where UI elements, particularly the "Add Class" button, do not refresh their colors immediately when theme or color scheme changes occur. The solution involves ensuring proper widget rebuilding and theme data propagation throughout the widget tree when theme changes are applied.

## Architecture

The fix involves three main components working together:

1. **ThemeProvider**: Enhanced to ensure proper notification of theme changes
2. **HomeScreen**: Modified to properly listen to theme changes and rebuild themed components
3. **Custom Widgets**: Updated to use theme data reactively rather than statically

### Root Cause Analysis

The issue occurs because:
1. The `NeoPopTiltedButton` captures the theme color at build time but doesn't rebuild when theme changes
2. The HomeScreen doesn't properly listen to ThemeProvider changes for custom components
3. Theme changes trigger `notifyListeners()` but some widgets don't rebuild due to improper Provider usage

## Components and Interfaces

### 1. ThemeProvider Enhancement

**Purpose**: Ensure reliable theme change notifications and proper state management

**Current Issues**:
- Theme changes notify listeners but some widgets don't rebuild
- Custom components may cache theme values

**Solution**:
```dart
class ThemeProvider extends ChangeNotifier {
  // Add explicit theme change notification
  void notifyThemeChanged() {
    notifyListeners();
    // Force a frame rebuild to ensure all widgets update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  
  // Enhanced setters that ensure proper notification
  Future<void> setColorScheme(int index) async {
    if (index >= 0 && index < _lightColorSchemes.length) {
      _colorSchemeIndex = index;
      notifyThemeChanged(); // Use enhanced notification
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_colorSchemeKey, index);
    }
  }
}
```

### 2. HomeScreen Enhancement

**Purpose**: Ensure proper theme listening and widget rebuilding

**Current Issues**:
- FloatingActionButton with NeoPopTiltedButton doesn't rebuild on theme changes
- Theme data is captured at build time but not updated

**Solution**:
```dart
class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Explicitly consume ThemeProvider to ensure rebuilds
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      // ... existing code ...
      floatingActionButton: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeoPopTiltedButton(
              color: theme.colorScheme.primary, // Will rebuild when theme changes
              onTapUp: () {
                HapticFeedback.lightImpact();
                _showAddClassDialog(context);
              },
              child: _buildAddClassButtonContent(),
            ),
          );
        },
      ),
    );
  }
}
```

### 3. Settings Screen Enhancement

**Purpose**: Ensure theme changes are properly applied when settings are modified

**Solution**:
```dart
// In settings screen when color scheme is changed
Future<void> _changeColorScheme(int index) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  await themeProvider.setColorScheme(index);
  
  // Ensure the current screen rebuilds
  if (mounted) {
    setState(() {});
  }
}
```

## Data Models

### ThemeChangeEvent

**Purpose**: Standardize theme change notifications

```dart
class ThemeChangeEvent {
  final ThemeMode? themeMode;
  final int? colorSchemeIndex;
  final DateTime timestamp;
  
  ThemeChangeEvent({
    this.themeMode,
    this.colorSchemeIndex,
    required this.timestamp,
  });
}
```

## Error Handling

### Theme Change Failures

1. **SharedPreferences Save Failures**
   - Continue with in-memory theme change
   - Show warning to user about persistence
   - Retry save operation

2. **Widget Rebuild Issues**
   - Use multiple notification strategies
   - Implement fallback rebuild mechanisms
   - Handle edge cases gracefully

### Error Recovery

```dart
Future<void> _handleThemeChangeError(String error) async {
  debugPrint('Theme change error: $error');
  
  // Show user feedback
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme change applied (settings may not persist)'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
```

## Testing Strategy

### Unit Tests

1. **ThemeProvider Tests**
   - Verify notification callbacks are triggered
   - Test theme persistence
   - Mock SharedPreferences interactions

2. **Widget Rebuild Tests**
   - Test Consumer widget behavior
   - Verify theme data propagation
   - Test custom component updates

### Widget Tests

1. **HomeScreen Tests**
   - Verify button color updates after theme change
   - Test FloatingActionButton rebuilding
   - Check theme consistency across components

2. **Integration Tests**
   - End-to-end theme change flow
   - Settings to HomeScreen theme propagation
   - Multiple screen theme consistency

### Test Scenarios

```dart
testWidgets('should update Add Class button color when theme changes', (tester) async {
  // Setup: Build HomeScreen with initial theme
  // Action: Change color scheme
  // Verify: Button color updates immediately
});

testWidgets('should handle rapid theme changes gracefully', (tester) async {
  // Setup: Build app with theme provider
  // Action: Rapidly change themes multiple times
  // Verify: UI remains stable and shows final theme
});
```

## Performance Considerations

### Optimization Strategies

1. **Selective Rebuilding**
   - Use Consumer widgets only where needed
   - Minimize widget tree rebuilds
   - Cache theme-dependent calculations

2. **Efficient Notifications**
   - Batch theme change notifications
   - Avoid redundant rebuilds
   - Use RepaintBoundary for expensive widgets

3. **Memory Management**
   - Clean up theme listeners properly
   - Avoid memory leaks in theme callbacks
   - Optimize theme data structures

### Implementation Approach

```dart
// Efficient theme listening
Widget build(BuildContext context) {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      // Only rebuild when theme actually changes
      return RepaintBoundary(
        child: ThemedWidget(
          color: Theme.of(context).colorScheme.primary,
          child: child,
        ),
      );
    },
    child: ExpensiveStaticWidget(), // Won't rebuild unnecessarily
  );
}
```

## Implementation Phases

### Phase 1: Core Theme Provider Fix
- Enhance ThemeProvider notification system
- Add proper theme change handling
- Implement fallback notification strategies

### Phase 2: Widget Updates
- Update HomeScreen FloatingActionButton
- Fix NeoPopTiltedButton theme responsiveness
- Add Consumer widgets where needed

### Phase 3: Settings Integration
- Ensure settings screen properly triggers theme changes
- Add immediate visual feedback for theme changes
- Handle navigation and state preservation

### Phase 4: Testing & Polish
- Comprehensive test coverage
- Performance optimization
- Edge case handling

## Migration Strategy

This is a bug fix that enhances existing functionality:

1. **Backward Compatibility**: All existing theme APIs remain unchanged
2. **Incremental Rollout**: Changes can be applied incrementally
3. **Fallback Behavior**: Existing theme system continues to work if enhancements fail

## Technical Implementation Details

### Consumer Widget Pattern

```dart
// Replace static theme usage
floatingActionButton: NeoPopTiltedButton(
  color: Theme.of(context).colorScheme.primary, // Static - won't update
  // ...
)

// With reactive theme usage
floatingActionButton: Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return NeoPopTiltedButton(
      color: Theme.of(context).colorScheme.primary, // Reactive - will update
      // ...
    );
  },
)
```

### Theme Data Propagation

```dart
// Ensure theme data flows properly
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          // ... rest of app
        );
      },
    );
  }
}
```