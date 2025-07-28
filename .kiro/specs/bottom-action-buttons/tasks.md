# Implementation Plan

- [x] 1. Create BottomActionBar widget component
  - Create new widget file for reusable bottom action bar
  - Implement responsive layout with two buttons side by side
  - Add proper styling and theming support
  - _Requirements: 1.1, 2.1, 2.2, 2.3, 3.1_

- [x] 2. Implement ActionButton widget enhancements
  - Enhance existing ActionButton or create new variant for bottom bar
  - Add loading state support with indicators
  - Implement disabled state styling
  - Add proper accessibility labels and semantics
  - _Requirements: 2.1, 2.2, 4.3, 4.4_

- [x] 3. Modify ClassDetailScreen layout structure
  - Remove floating action button from Students tab
  - Integrate BottomActionBar into Students tab layout
  - Implement Stack layout to overlay buttons at bottom
  - Add proper safe area handling for different devices
  - _Requirements: 1.1, 1.2, 3.3, 3.4_

- [x] 4. Update Students tab UI layout
  - Modify ListView to add bottom padding for button clearance
  - Ensure proper scroll behavior with bottom action bar
  - Implement responsive design for different screen sizes
  - Handle keyboard visibility and button positioning
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 5. Implement button functionality and state management
  - Connect Add Student button to existing dialog functionality
  - Connect Take Attendance button to navigation logic
  - Implement button state management (enabled/disabled based on student count)
  - Add loading states during operations
  - _Requirements: 1.3, 1.4, 1.5, 4.1, 4.2, 4.4_

- [ ] 6. Add user feedback and error handling
  - Implement disabled state tooltip for Take Attendance when no students
  - Add proper error handling for button actions
  - Ensure consistent success/error messages with existing functionality
  - Add visual feedback for button interactions
  - _Requirements: 1.5, 4.5_

- [ ] 7. Implement accessibility features
  - Add proper semantic labels for screen readers
  - Implement focus management for keyboard navigation
  - Add high contrast mode support
  - Test with accessibility tools and screen readers
  - _Requirements: 2.1, 2.2_

- [ ] 8. Create comprehensive tests
  - Write unit tests for BottomActionBar widget
  - Create widget tests for button interactions and states
  - Implement integration tests for complete user flows
  - Add accessibility tests for screen reader compatibility
  - _Requirements: All requirements validation_

- [ ] 9. Performance optimization and polish
  - Add RepaintBoundary widgets for efficient rendering
  - Implement smooth animations for button state changes
  - Optimize layout calculations for different screen sizes
  - Add proper widget keys for efficient rebuilds
  - _Requirements: 3.1, 3.2, 3.4_

- [ ] 10. Final integration and testing
  - Test complete user flows from Students tab
  - Verify consistency with Actions tab functionality
  - Test on different device sizes and orientations
  - Validate all requirements are met
  - _Requirements: 4.1, 4.2, 4.3, 4.5_