# Firebase Authentication Implementation

This document describes the Firebase Authentication implementation for the Attendance Tracker app.

## Features Implemented

### 🔐 Authentication Methods
- **Phone Number Authentication**: SMS-based OTP verification
- **Google Sign-In**: OAuth authentication with Google accounts
- **Multi-provider Support**: Users can link multiple sign-in methods

### 📱 User Interface
- **Login Screen**: Clean interface with phone and Google sign-in options
- **OTP Verification**: 6-digit code input with auto-verification
- **Profile Management**: View and manage linked authentication methods
- **Account Actions**: Sign out and delete account functionality

### 🔧 Technical Implementation

#### Core Components

1. **AuthService** (`lib/services/auth_service.dart`)
   - Handles Firebase Authentication operations
   - Manages phone verification and Google sign-in
   - Provides account linking/unlinking functionality
   - Error handling with user-friendly messages

2. **AuthProvider** (`lib/providers/auth_provider.dart`)
   - State management for authentication
   - Exposes authentication methods to UI
   - Listens to auth state changes

3. **UserModel** (`lib/models/user_model.dart`)
   - Represents authenticated user data
   - Converts Firebase User to app-specific model
   - Serialization support for local storage

#### Authentication Screens

1. **LoginScreen** (`lib/screens/auth/login_screen.dart`)
   - Phone number input with validation
   - Google sign-in button
   - Automatic navigation to OTP screen

2. **OTPVerificationScreen** (`lib/screens/auth/otp_verification_screen.dart`)
   - 6-digit OTP input fields
   - Auto-verification when complete
   - Resend OTP functionality
   - Option to change phone number

3. **AuthWrapper** (`lib/screens/auth/auth_wrapper.dart`)
   - Routes users based on authentication state
   - Shows loading during initialization
   - Handles authentication state changes

4. **ProfileScreen** (`lib/screens/auth/profile_screen.dart`)
   - Display user information
   - Manage linked authentication methods
   - Account actions (sign out, delete)
   - Link/unlink phone number and Google account

#### Widgets

1. **LinkPhoneDialog** (`lib/widgets/link_phone_dialog.dart`)
   - Modal dialog for linking phone numbers
   - Two-step process: phone input → OTP verification
   - Integrated with existing authentication flow

## Authentication Flow

### Phone Authentication
1. User enters phone number
2. Firebase sends SMS with verification code
3. User enters 6-digit code
4. Firebase verifies code and signs in user
5. User is redirected to home screen

### Google Authentication
1. User taps "Continue with Google"
2. Google sign-in flow opens
3. User selects Google account
4. Firebase creates/signs in user
5. User is redirected to home screen

### Account Linking
1. Authenticated user can link additional methods
2. Phone linking requires OTP verification
3. Google linking uses standard OAuth flow
4. Users can unlink methods (minimum one required)

## Security Features

### Input Validation
- Phone number format validation
- OTP length and digit-only validation
- Proper error handling for all inputs

### Authentication State Management
- Automatic state synchronization
- Secure token handling by Firebase
- Session persistence across app restarts

### Error Handling
- User-friendly error messages
- Network error handling
- Firebase-specific error code translation

## Configuration Required

### Firebase Project Setup
1. Create Firebase project
2. Enable Phone and Google authentication
3. Add Android/iOS apps to project
4. Download configuration files

### Android Configuration
- Add `google-services.json` to `android/app/`
- Configure SHA-1 fingerprints for Google Sign-In
- Required permissions already added

### iOS Configuration (if needed)
- Add `GoogleService-Info.plist` to iOS project
- Configure URL schemes for Google Sign-In

### Firebase Options
- Update `lib/firebase_options.dart` with actual project values
- Replace placeholder API keys and project IDs

## Usage Examples

### Check Authentication State
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (authProvider.isAuthenticated) {
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  },
)
```

### Sign In with Phone
```dart
final authProvider = context.read<AuthProvider>();
await authProvider.signInWithPhone(
  phoneNumber: '+1234567890',
  onCodeSent: (verificationId) {
    // Navigate to OTP screen
  },
  onError: (error) {
    // Show error message
  },
);
```

### Sign In with Google
```dart
final authProvider = context.read<AuthProvider>();
try {
  final user = await authProvider.signInWithGoogle();
  if (user != null) {
    // Navigate to home screen
  }
} catch (e) {
  // Handle error
}
```

### Access Current User
```dart
final authProvider = context.watch<AuthProvider>();
final user = authProvider.currentUser;
if (user != null) {
  print('User: ${user.displayName ?? user.phoneNumber}');
}
```

## Testing

### Test Phone Numbers (Development)
Firebase allows adding test phone numbers that don't require SMS:
1. Go to Firebase Console → Authentication → Settings
2. Add test phone numbers with verification codes
3. Use these for development testing

### Google Sign-In Testing
- Ensure SHA-1 fingerprints are correctly configured
- Test with different Google accounts
- Verify account linking works properly

## Troubleshooting

### Common Issues
1. **Google Sign-In fails**: Check SHA-1 fingerprints
2. **SMS not received**: Verify phone number format and Firebase quotas
3. **Build errors**: Ensure all configuration files are properly placed
4. **Authentication state not updating**: Check provider setup in main.dart

### Debug Tips
- Enable Firebase debug logging
- Check device logs for detailed error messages
- Verify Firebase project configuration
- Test with different devices and network conditions

## Future Enhancements

### Possible Additions
1. **Email Authentication**: Add email/password sign-in
2. **Social Logins**: Facebook, Twitter, Apple Sign-In
3. **Biometric Authentication**: Fingerprint/Face ID
4. **Two-Factor Authentication**: Additional security layer
5. **Account Recovery**: Password reset and account recovery flows
6. **User Profiles**: Extended user information and preferences

### Security Improvements
1. **App Check**: Additional security for Firebase services
2. **Security Rules**: If using other Firebase services
3. **Rate Limiting**: Prevent abuse of authentication endpoints
4. **Audit Logging**: Track authentication events

## Dependencies Added

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  google_sign_in: ^6.1.6
```

## Files Created/Modified

### New Files
- `lib/models/user_model.dart`
- `lib/services/auth_service.dart`
- `lib/providers/auth_provider.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/otp_verification_screen.dart`
- `lib/screens/auth/auth_wrapper.dart`
- `lib/screens/auth/profile_screen.dart`
- `lib/widgets/link_phone_dialog.dart`
- `lib/firebase_options.dart`
- `FIREBASE_SETUP.md`

### Modified Files
- `pubspec.yaml` - Added Firebase dependencies
- `lib/main.dart` - Firebase initialization and AuthWrapper
- `lib/services/service_locator.dart` - Added AuthProvider
- `lib/screens/home_screen.dart` - Added profile access
- `android/app/build.gradle.kts` - Google Services plugin
- `android/build.gradle.kts` - Google Services classpath
- `android/app/src/main/AndroidManifest.xml` - Permissions

The authentication system is now fully implemented and ready for use after Firebase project configuration!