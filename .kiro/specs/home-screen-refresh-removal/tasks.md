# Implementation Plan

- [x] 1. Remove refresh button from home screen app bar
  - Modify the HomeScreen widget's AppBar actions array to remove the refresh IconButton
  - Keep only the settings IconButton in the actions array
  - Ensure the tooltip and onPressed functionality for settings remains intact
  - _Requirements: 1.1, 1.3, 1.4_

- [ ] 2. Update and verify existing tests
  - Update any widget tests that expect the refresh button to be present
  - Verify that pull-to-refresh functionality tests still pass
  - Ensure app bar layout tests reflect the new button configuration
  - _Requirements: 1.1, 1.2, 1.4_