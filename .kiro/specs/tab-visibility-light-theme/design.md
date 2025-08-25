# Design Document

## Overview

This design addresses the tab visibility issue in the ClassDetailScreen where hardcoded white colors for tab indicators and text make them invisible in light theme mode. The solution involves replacing hardcoded colors with theme-aware colors that automatically adapt to the current theme.

## Architecture

The fix will be implemented at the widget level in the ClassDetailScreen's AppBar TabBar configuration. The current implementation uses hardcoded colors that don't respond to theme changes, while the new implementation will leverage Flutter's theme system and the existing ThemeProvider.

### Current Implementation Issues

1. **Hardcoded Colors**: The TabBar uses fixed white colors for `labelColor`, `unselectedLabelColor`, and `indicatorColor`
2. **No Theme Awareness**: Colors don't change when switching between light and dark themes
3. **Poor Contrast**: White indicators on light backgrounds are invisible
4. **Inconsistent Styling**: Tab colors don't match the app's theme system

### Proposed Solution

Replace hardcoded colors with theme-aware properties that automatically adapt to the current theme context.

## Components and Interfaces

### Modified Components

#### ClassDetailScreen TabBar
- **Location**: `lib/screens/class_detail_screen.dart`
- **Current Implementation**: Uses hardcoded white colors
- **New Implementation**: Uses theme-aware colors from `Theme.of(context)`

### Theme Integration

The solution leverages the existing ThemeProvider which already includes tabBarTheme configuration:

```dart
tabBarTheme: baseTheme.tabBarTheme.copyWith(
  labelColor: colorScheme.primary,
  indicator: UnderlineTabIndicator(
    borderSide: BorderSide(
      width: 2,
      color: colorScheme.primary,
    ),
  ),
),
```

## Data Models

No data model changes are required. This is purely a UI styling fix.

## Error Handling

### Fallback Colors
- If theme colors are unavailable, fall back to Material Design defaults
- Ensure minimum contrast ratios are maintained for accessibility

### Theme Transition
- Colors should update immediately when theme changes
- No visual glitches during theme transitions

## Testing Strategy

### Visual Testing
1. **Light Theme Verification**: Verify tab visibility in all light color schemes (Blue, Green, Purple, Teal)
2. **Dark Theme Regression**: Ensure dark theme appearance remains unchanged
3. **Theme Switching**: Test real-time color updates when switching themes
4. **Accessibility**: Verify contrast ratios meet WCAG guidelines

### Unit Testing
1. **Theme Color Resolution**: Test that correct colors are applied based on theme
2. **Color Scheme Variations**: Test all available color schemes
3. **System Theme Changes**: Test behavior when system theme changes

### Integration Testing
1. **Full Theme Workflow**: Test complete theme switching workflow
2. **Tab Functionality**: Ensure tab switching still works correctly
3. **Cross-Platform**: Verify appearance on different platforms

## Implementation Details

### Color Selection Strategy

#### Light Theme
- **Active Tab Text**: Use `theme.colorScheme.primary` for strong visibility
- **Inactive Tab Text**: Use `theme.colorScheme.onSurface.withOpacity(0.6)` for subtle appearance
- **Indicator**: Use `theme.colorScheme.primary` for clear active state indication

#### Dark Theme
- **Active Tab Text**: Use `theme.colorScheme.onSurface` (white/light color)
- **Inactive Tab Text**: Use `theme.colorScheme.onSurface.withOpacity(0.6)` for subtle appearance  
- **Indicator**: Use `theme.colorScheme.primary` for brand consistency

### AppBar Context Considerations

Since the TabBar is within an AppBar that has a colored background:
- In light theme: AppBar background is `colorScheme.primary` (colored)
- In dark theme: AppBar background is `colorScheme.surface` (dark)

This affects the optimal text colors:
- Light theme AppBar (colored background): Use `colorScheme.onPrimary` for text
- Dark theme AppBar (dark background): Use `colorScheme.onSurface` for text

### Responsive Design

The tab styling will work consistently across all screen sizes and orientations since it uses relative theme colors rather than absolute values.

### Accessibility Compliance

- Maintain minimum 4.5:1 contrast ratio for normal text
- Maintain minimum 3:1 contrast ratio for large text
- Ensure color is not the only means of conveying information (text labels remain)

## Migration Strategy

This is a low-risk change that only affects visual appearance:

1. **Backward Compatibility**: No breaking changes to functionality
2. **Immediate Effect**: Changes take effect immediately upon deployment
3. **No Data Migration**: No database or storage changes required
4. **Rollback Plan**: Simple revert to previous hardcoded colors if needed