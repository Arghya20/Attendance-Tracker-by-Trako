# Cloud Sync Implementation Guide

## Overview

This implementation provides automatic cloud synchronization of local SQLite data with Firebase Firestore. Data is automatically synced based on the user's login method (phone number or email) and restored when the user reinstalls the app.

## Features

### 1. Automatic Data Sync
- **On Login**: Automatically checks if local database is empty and restores from cloud if available
- **Periodic Sync**: Automatically syncs local data to cloud every 5 minutes (configurable)
- **On Data Change**: Can be triggered manually after important data changes

### 2. Login Method Based Storage
- **Phone Login**: Data stored under `users_by_phone/{sanitized_phone_number}`
- **Email Login**: Data stored under `users_by_email/{sanitized_email}`
- **Fallback**: Uses user UID if neither phone nor email is available

### 3. Data Restoration
- **Automatic**: When user logs in after reinstalling app, data is automatically restored
- **Smart Detection**: Only restores if local database is empty
- **Conflict Resolution**: Cloud data takes precedence on fresh install

## How It Works

### User Flow

1. **First Time User**
   - User signs up with phone or email
   - Creates classes, students, and attendance records
   - Data automatically syncs to cloud every 5 minutes
   - Data is also synced when user logs out

2. **Returning User (Same Device)**
   - User logs in
   - Local data already exists
   - System syncs local data to cloud to ensure cloud has latest version
   - Continues with periodic sync

3. **User Reinstalls App**
   - User logs in with same phone/email
   - System detects local database is empty
   - Automatically downloads and restores data from cloud
   - User sees all their previous data
   - Periodic sync continues

### Technical Implementation

#### CloudSyncService

The `CloudSyncService` handles all cloud synchronization operations:

```dart
// Upload local data to cloud
await cloudSyncService.uploadToCloud(user);

// Download and restore from cloud
await cloudSyncService.downloadFromCloud(user);

// Auto-restore on login (checks if local DB is empty)
await cloudSyncService.autoRestoreOnLogin(user);

// Enable automatic periodic sync (every 5 minutes)
cloudSyncService.enableAutoSync(user);

// Disable automatic sync
cloudSyncService.disableAutoSync();
```

#### Integration with AuthService

The `AuthService` automatically triggers sync operations:

```dart
Future<void> _onAuthStateChanged(User? firebaseUser) async {
  if (firebaseUser == null) {
    // User logged out - disable sync
    _cloudSyncService.disableAutoSync();
  } else {
    // User logged in
    _currentUser = UserModel.fromFirebaseUser(firebaseUser);
    
    // Auto-restore data from cloud if local database is empty
    await _cloudSyncService.autoRestoreOnLogin(_currentUser!);
    
    // Enable automatic periodic sync
    _cloudSyncService.enableAutoSync(_currentUser!);
  }
}
```

## Data Structure in Firestore

```
Firestore Collection Structure:
├── users_by_phone/
│   └── {sanitized_phone}/
│       ├── user_id: "firebase_uid"
│       ├── phone_number: "+1234567890"
│       ├── email: null
│       ├── last_sync: Timestamp
│       ├── app_version: 2
│       ├── data/
│       │   ├── classes: [...]
│       │   ├── students: [...]
│       │   ├── attendance_sessions: [...]
│       │   └── attendance_records: [...]
│       └── metadata/
│           ├── total_classes: 5
│           ├── total_students: 150
│           ├── total_sessions: 45
│           └── total_records: 6750
│
└── users_by_email/
    └── {sanitized_email}/
        └── (same structure as above)
```

## Security Considerations

### Firestore Security Rules

Add these rules to your Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data by phone
    match /users_by_phone/{phoneNumber} {
      allow read, write: if request.auth != null && 
                           request.auth.token.phone_number == phoneNumber.replaceAll('_', '');
    }
    
    // Allow users to read/write their own data by email
    match /users_by_email/{email} {
      allow read, write: if request.auth != null && 
                           request.auth.token.email == email.replaceAll('_', '');
    }
    
    // Allow users to read/write their own data by UID (fallback)
    match /users_by_uid/{userId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId;
    }
  }
}
```

## Manual Sync Operations

### Trigger Manual Sync

You can trigger manual sync from anywhere in your app:

```dart
final cloudSyncService = CloudSyncService();
final authProvider = Provider.of<AuthProvider>(context, listen: false);

if (authProvider.currentUser != null) {
  try {
    await cloudSyncService.syncToCloud(authProvider.currentUser!);
    // Show success message
  } catch (e) {
    // Show error message
  }
}
```

### Check Cloud Data Status

```dart
// Check if cloud data exists
bool hasData = await cloudSyncService.hasCloudData(user);

// Get cloud data metadata
Map<String, dynamic>? metadata = await cloudSyncService.getCloudDataMetadata(user);
print('Last sync: ${metadata?['last_sync']}');
print('Total classes: ${metadata?['metadata']['total_classes']}');
```

## Configuration

### Change Sync Interval

To change the automatic sync interval, modify the `enableAutoSync` call:

```dart
// Sync every 10 minutes instead of 5
cloudSyncService.enableAutoSync(
  user, 
  interval: Duration(minutes: 10)
);
```

### Disable Auto-Sync

If you want to disable automatic sync and only sync manually:

```dart
// In auth_service.dart, comment out or remove:
// _cloudSyncService.enableAutoSync(_currentUser!);
```

## Testing

### Test Scenarios

1. **Fresh Install with Cloud Data**
   - Install app
   - Login with existing account
   - Verify data is restored

2. **Fresh Install without Cloud Data**
   - Install app
   - Login with new account
   - Create some data
   - Verify data syncs to cloud

3. **Existing Installation**
   - Login with existing account
   - Verify local data is preserved
   - Verify data syncs to cloud

4. **Multiple Devices**
   - Login on Device A
   - Create data on Device A
   - Wait for sync (or trigger manual sync)
   - Login on Device B
   - Verify data appears on Device B

## Troubleshooting

### Data Not Syncing

1. Check internet connection
2. Verify Firebase is properly configured
3. Check Firestore security rules
4. Check console logs for errors

### Data Not Restoring

1. Verify user is logging in with same phone/email
2. Check if cloud data exists in Firestore console
3. Verify local database is actually empty
4. Check console logs for errors

### Sync Conflicts

Currently, the system uses a "last write wins" approach:
- On fresh install: Cloud data overwrites local (empty) data
- On existing install: Local data overwrites cloud data

For more sophisticated conflict resolution, you would need to implement:
- Timestamp-based merging
- Field-level conflict detection
- User-prompted conflict resolution

## Future Enhancements

1. **Incremental Sync**: Only sync changed records instead of full database
2. **Conflict Resolution**: Better handling of data conflicts between devices
3. **Offline Queue**: Queue sync operations when offline and execute when online
4. **Compression**: Compress data before uploading to reduce bandwidth
5. **Selective Sync**: Allow users to choose what data to sync
6. **Sync History**: Keep track of sync history and allow rollback

## Dependencies

```yaml
dependencies:
  cloud_firestore: ^5.4.4
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
```

## Files Modified/Created

- `lib/services/cloud_sync_service.dart` - New service for cloud sync
- `lib/services/auth_service.dart` - Modified to integrate auto-sync
- `pubspec.yaml` - Added cloud_firestore dependency
- `CLOUD_SYNC_IMPLEMENTATION.md` - This documentation

## Support

For issues or questions, check:
1. Firebase Console for Firestore data
2. Flutter console logs for error messages
3. Firestore security rules in Firebase Console
