# Fix reCAPTCHA Redirect Issue for Phone Authentication

## Problem
Firebase Phone Authentication shows a reCAPTCHA verification screen before allowing users to authenticate. This happens because Firebase needs to verify the request isn't from a bot.

## Solution: Enable App Verification

To skip the reCAPTCHA screen, you need to add your app's SHA-256 certificate fingerprint to Firebase Console.

### Step 1: Get Your SHA-256 Certificate Fingerprint

#### For Debug Build (Development):
```bash
# On macOS/Linux:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# On Windows:
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### For Release Build (Production):
```bash
keytool -list -v -keystore /path/to/your/release-keystore.jks -alias your-key-alias
```

Look for the **SHA-256** fingerprint in the output. It looks like:
```
SHA256: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99
```

### Step 2: Add SHA-256 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Click on your Android app
6. Scroll to **SHA certificate fingerprints**
7. Click **Add fingerprint**
8. Paste your SHA-256 fingerprint
9. Click **Save**

### Step 3: Download Updated google-services.json

After adding the SHA-256 fingerprint:
1. Download the updated `google-services.json` file from Firebase Console
2. Replace the existing file at `android/app/google-services.json`

### Step 4: Rebuild Your App

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: Use Google Sign-In (No reCAPTCHA)

Google Sign-In doesn't require reCAPTCHA verification and provides a better user experience. You already have this implemented in your app.

## For Testing Only: Disable App Verification

**⚠️ WARNING: Only use this for testing, NEVER in production!**

You can disable app verification for testing by adding this to your `auth_service.dart`:

```dart
// In _init() method, add:
_firebaseAuth.setSettings(appVerificationDisabledForTesting: true);
```

This will skip reCAPTCHA but is **NOT secure** for production use.

## Recommended Approach

1. **For Development**: Add your debug SHA-256 fingerprint to Firebase
2. **For Production**: Add your release SHA-256 fingerprint to Firebase
3. **Best UX**: Prioritize Google Sign-In as the primary authentication method, with phone auth as a secondary option

## Why This Happens

Firebase Phone Authentication uses SafetyNet (now Play Integrity API) on Android to verify that requests come from your legitimate app. Without the SHA-256 fingerprint registered, Firebase falls back to reCAPTCHA verification to prevent abuse.
