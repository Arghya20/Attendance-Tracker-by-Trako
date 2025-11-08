# Name Input Implementation

## Overview
Added a name input prompt for users who sign in via phone number authentication. Users who sign in via Google do not see this prompt as Google already provides the display name.

## Changes Made

### 1. New Widget: `lib/widgets/name_input_dialog.dart`
- Created a dialog that prompts users to enter their name
- Includes validation (minimum 2 characters, non-empty)
- Has "Skip" and "Continue" buttons
- Auto-capitalizes words for proper name formatting

### 2. Updated `lib/services/auth_service.dart`
- Added `updateDisplayName(String displayName)` method
- Updates the Firebase user's display name
- Reloads user data and notifies listeners

### 3. Updated `lib/providers/auth_provider.dart`
- Exposed `updateDisplayName()` method from auth service
- Allows UI components to update user display name

### 4. Updated `lib/screens/auth/otp_verification_screen.dart`
- Modified `_verifyOTP()` to check if user has a display name after successful verification
- If no display name exists (phone auth), shows the name input dialog
- If display name exists (Google auth or previously set), navigates directly to home
- Added `_showNameInputDialog()` method to handle the name input flow

## User Flow

### Phone Authentication
1. User enters phone number
2. User receives and enters OTP
3. OTP is verified successfully
4. **Name input dialog appears** (new step)
5. User enters name or skips
6. Navigate to home screen

### Google Authentication
1. User clicks "Continue with Google"
2. Google authentication completes
3. Navigate directly to home screen (no name prompt - Google provides display name)

## Technical Details

- The name dialog is shown only when `user.displayName` is null or empty
- Google sign-in automatically provides a display name, so the dialog is skipped
- Users can skip the name input if they prefer
- The display name is stored in Firebase Authentication
- If updating the name fails, the error is logged but doesn't block navigation

## Edit Name Feature

### New Widget: `lib/widgets/edit_name_dialog.dart`
- Dialog for editing existing user name
- Pre-fills with current name
- Same validation as name input dialog

### Updated `lib/screens/settings_screen.dart`
- Added edit icon button next to user's display name in profile section
- Added `_editName()` method to handle name updates
- Shows success/error feedback via snackbar
- Only updates if the new name is different from current name

## Account Linking Feature

### Updated `lib/services/auth_service.dart`
- Added `linkGoogleAccount()` method to properly link Google account to existing user
- Uses Firebase's `linkWithCredential()` instead of creating new sign-in
- Updates user model after successful linking

### Updated `lib/providers/auth_provider.dart`
- Exposed `linkGoogleAccount()` method from auth service

### Updated `lib/screens/settings_screen.dart`
- Fixed `_linkGoogleAccount()` to use proper linking method
- Now correctly links Google account to phone-authenticated users
- Phone linking already worked correctly via `LinkPhoneDialog`

## Name Input Location Change

### Updated `lib/screens/home_screen.dart`
- Name input dialog now appears on home screen instead of OTP verification screen
- Added `_checkAndShowNameDialog()` method
- Only shows for phone-authenticated users without display name
- Better user experience as users see the app before being asked for name

### Updated `lib/screens/auth/otp_verification_screen.dart`
- Removed name input dialog logic
- Now directly navigates to home screen after OTP verification
