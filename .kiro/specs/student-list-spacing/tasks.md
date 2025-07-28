# Implementation Plan

- [x] 1. Add bottom spacing calculation method to ClassDetailScreen
  - Create `_calculateBottomSpacing()` method that computes proper bottom padding
  - Account for action bar height, safe area insets, and additional spacing buffer
  - Handle edge cases for minimum spacing requirements
  - _Requirements: 1.1, 1.2, 2.1_

- [x] 2. Update BottomActionBar to provide consistent height measurement
  - Add static constant for action bar height
  - Ensure height calculation includes all padding and safe area handling
  - Update existing height usage to use the constant value
  - _Requirements: 1.1, 2.1_

- [x] 3. Implement dynamic bottom padding in student ListView
  - Replace hardcoded bottom padding (80) with calculated spacing
  - Apply the new spacing calculation to both empty state and student list
  - Ensure padding updates when MediaQuery changes (orientation, keyboard)
  - _Requirements: 1.1, 1.2, 2.2_

- [x] 4. Enhance ListView scroll behavior for better user experience
  - Configure AlwaysScrollableScrollPhysics for consistent scroll behavior
  - Maintain existing performance optimizations (RepaintBoundary, cacheExtent)
  - Ensure smooth scrolling to bottom when needed
  - _Requirements: 1.4, 3.2_

- [x] 5. Add responsive spacing for different screen sizes
  - Implement screen size detection for spacing adjustments
  - Add minimum spacing enforcement for very small screens
  - Test spacing behavior across mobile, tablet, and desktop layouts
  - _Requirements: 2.1, 2.3_

- [x] 6. Create unit tests for spacing calculation logic
  - Test `_calculateBottomSpacing()` with various MediaQuery scenarios
  - Test minimum spacing enforcement
  - Test safe area handling edge cases
  - _Requirements: 1.1, 2.1_

- [x] 7. Add widget tests for ListView padding and scroll behavior
  - Test that ListView receives correct bottom padding
  - Test scroll behavior with new spacing
  - Test that last student item is fully visible and tappable
  - _Requirements: 1.3, 3.1, 3.2_

- [x] 8. Implement keyboard-aware spacing adjustments
  - Detect keyboard visibility changes
  - Adjust bottom spacing when keyboard appears/disappears
  - Ensure student list remains accessible with keyboard open
  - _Requirements: 2.2_

- [ ] 9. Test and validate spacing across different devices and orientations
  - Test on various screen sizes and aspect ratios
  - Verify spacing works correctly in portrait and landscape
  - Ensure no overlap between content and action buttons
  - _Requirements: 2.1, 2.3_