# Firebase Authentication Setup Guide

This guide will help you set up Firebase Authentication for your Flutter attendance tracker app with phone number and Google sign-in.

## Prerequisites

1. A Google account
2. Flutter development environment set up
3. Android Studio (for Android development)
4. Xcode (for iOS development, if targeting iOS)

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter your project name (e.g., "attendance-tracker")
4. Choose whether to enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Enable Authentication Methods

1. In your Firebase project, go to **Authentication** > **Sign-in method**
2. Enable the following sign-in providers:
   - **Phone**: Click on Phone, toggle "Enable", and save
   - **Google**: Click on Google, toggle "Enable", add your support email, and save

## Step 3: Configure Android App

### Add Android App to Firebase Project

1. In Firebase Console, click the Android icon to add an Android app
2. Enter the Android package name: `com.example.attendance_tracker`
3. Enter app nickname (optional): "Attendance Tracker Android"
4. Enter SHA-1 certificate fingerprint (required for Google Sign-In):
   
   **For Debug Certificate:**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   
   **For Release Certificate (when publishing):**
   ```bash
   keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias-name
   ```

5. Click "Register app"
6. Download the `google-services.json` file
7. Place the `google-services.json` file in `android/app/` directory

### Update Android Configuration

The necessary Android configuration has already been added to your project:
- Google Services plugin in `android/build.gradle.kts`
- Google Services plugin applied in `android/app/build.gradle.kts`
- Required permissions in `android/app/src/main/AndroidManifest.xml`

## Step 4: Configure iOS App (Optional)

### Add iOS App to Firebase Project

1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter the iOS bundle ID: `com.example.attendanceTracker`
3. Enter app nickname (optional): "Attendance Tracker iOS"
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Add the `GoogleService-Info.plist` file to your iOS project in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Right-click on "Runner" in the project navigator
   - Select "Add Files to Runner"
   - Choose the `GoogleService-Info.plist` file
   - Make sure "Copy items if needed" is checked
   - Select "Runner" target
   - Click "Add"

### Update iOS Configuration

Add the following to `ios/Runner/Info.plist` inside the `<dict>` tag:

```xml
<!-- Google Sign-In URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the value from your `GoogleService-Info.plist` file.

## Step 5: Update Firebase Options

1. Open `lib/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase configuration:
   - Get these values from your Firebase project settings
   - Go to Project Settings > General > Your apps
   - Click on the config icon for each platform

### For Android:
- Copy values from `google-services.json`

### For iOS:
- Copy values from `GoogleService-Info.plist`

### For Web:
- Copy values from Firebase project settings > Web app config

## Step 6: Test the Setup

1. Run `flutter pub get` to install dependencies
2. Run the app on your device/emulator:
   ```bash
   flutter run
   ```
3. Try signing in with:
   - Phone number (you'll receive an SMS with verification code)
   - Google account

## Step 7: Configure Phone Authentication (Additional Setup)

### For Production Use:

1. **Add your domain to authorized domains:**
   - Go to Authentication > Settings > Authorized domains
   - Add your domain if using web

2. **Set up reCAPTCHA (Web only):**
   - Phone authentication on web requires reCAPTCHA verification
   - This is handled automatically by Firebase

3. **Configure SMS quota:**
   - Firebase has daily SMS limits
   - For production apps, you may need to enable billing

## Troubleshooting

### Common Issues:

1. **Google Sign-In not working on Android:**
   - Ensure SHA-1 fingerprint is correctly added to Firebase project
   - Check that `google-services.json` is in the correct location

2. **Phone authentication not working:**
   - Ensure phone authentication is enabled in Firebase Console
   - Check that you're using a valid phone number format
   - For testing, you can add test phone numbers in Firebase Console

3. **Build errors:**
   - Run `flutter clean` and `flutter pub get`
   - Ensure all dependencies are properly installed

4. **iOS build issues:**
   - Ensure `GoogleService-Info.plist` is properly added to Xcode project
   - Check that URL schemes are correctly configured

## Security Considerations

1. **Never commit sensitive keys to version control**
2. **Use different Firebase projects for development and production**
3. **Enable App Check for additional security (recommended for production)**
4. **Set up proper security rules if using other Firebase services**

## Next Steps

After setting up authentication, you can:
1. Customize the authentication UI
2. Add user profile management
3. Implement role-based access control
4. Add social login providers (Facebook, Twitter, etc.)
5. Set up Firebase Analytics to track user engagement

## Support

If you encounter issues:
1. Check the [Firebase Documentation](https://firebase.google.com/docs)
2. Review the [FlutterFire Documentation](https://firebase.flutter.dev/)
3. Check the console logs for error messages
4. Ensure all configuration files are properly placed and configured