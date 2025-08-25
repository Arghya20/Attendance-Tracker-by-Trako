# Requirements Document

## Introduction

This feature involves removing the refresh button from the home screen app bar since the page already supports pull-to-refresh functionality, making the button redundant and improving the UI cleanliness.

## Requirements

### Requirement 1

**User Story:** As a user, I want a cleaner app bar interface without redundant refresh functionality, so that the UI is more streamlined and I can still refresh using the pull-to-refresh gesture.

#### Acceptance Criteria

1. WHEN the home screen is displayed THEN the app bar SHALL NOT contain a refresh button
2. WHEN the user pulls down on the class list THEN the system SHALL refresh the classes as before
3. WHEN the refresh button is removed THEN the settings button SHALL remain in the app bar
4. WHEN the app bar is displayed THEN it SHALL only contain the app title and settings button