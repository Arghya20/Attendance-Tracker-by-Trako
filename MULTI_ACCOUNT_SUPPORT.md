# Multi-Account Support

## How It Works

The app now properly handles multiple user accounts with automatic data isolation.

## Features

### 1. Automatic Account Switching
When you logout and login with a different account:
- ✅ Local database is automatically cleared
- ✅ New user's data is downloaded from cloud
- ✅ Each user sees only their own data

### 2. Same Account, Multiple Devices
When you login with the same account on different devices:
- ✅ All your data is automatically synced
- ✅ Changes on one device appear on other devices
- ✅ Data is consistent across all devices

### 3. Data Isolation
- Each user's data is stored separately in the cloud
- Users cannot access other users' data
- Local database is cleared when switching accounts

## User Scenarios

### Scenario 1: Switch Accounts on Same Device

**Steps:**
1. User A logs in → sees their data
2. User A logs out
3. User B logs in → local database cleared → User B's data downloaded
4. User B sees only their data (not User A's data)

### Scenario 2: Same Account on Multiple Devices

**Steps:**
1. Login on Device 1 with Account A
2. Create some data on Device 1
3. Data syncs to cloud automatically
4. Login on Device 2 with Account A
5. Device 2 downloads Account A's data
6. Both devices show the same data

### Scenario 3: Reinstall App

**Steps:**
1. User has data in the app
2. User uninstalls the app
3. User reinstalls the app
4. User logs in with same account
5. All data is automatically restored

## Technical Details

### How Account Detection Works

1. **On Login:**
   - App checks the user ID (UID) from Firebase
   - Compares with last logged-in user ID (stored in SharedPreferences)
   - If different → clears local database
   - Downloads new user's data from cloud

2. **Data Storage:**
   - Local: SQLite database (device-specific)
   - Cloud: Firestore (user-specific)
   - Each user has their own cloud storage path

3. **Storage Paths:**
   ```
   Phone Login: users_by_phone/{phone_number}/
   Email Login: users_by_email/{email}/
   Fallback:    users_by_uid/{user_id}/
   ```

### What Gets Cleared

When switching accounts, these are cleared:
- All classes
- All students
- All attendance sessions
- All attendance records

### What Gets Preserved

- App settings (theme, color scheme)
- Last user ID (for account detection)

## Testing

### Test Account Switching

1. **Login with Account A:**
   ```
   - Create a class "Math 101"
   - Add some students
   - Take attendance
   ```

2. **Logout and Login with Account B:**
   ```
   - Should NOT see "Math 101"
   - Should see empty database or Account B's data
   ```

3. **Logout and Login with Account A again:**
   ```
   - Should see "Math 101" again (restored from cloud)
   ```

### Test Multi-Device Sync

1. **Device 1:**
   ```
   - Login with Account A
   - Create class "Physics"
   - Wait for sync or click "Sync Now"
   ```

2. **Device 2:**
   ```
   - Login with Account A
   - Should see "Physics" class
   ```

3. **Device 2:**
   ```
   - Add students to "Physics"
   - Wait for sync
   ```

4. **Device 1:**
   ```
   - Wait for sync
   - Should see the new students
   ```

## Troubleshooting

### Issue: Seeing wrong user's data

**Cause:** Account switching detection failed

**Solution:**
1. Logout completely
2. Clear app data (Settings → Apps → Attendance Tracker → Clear Data)
3. Login again

### Issue: Data not syncing between devices

**Cause:** Sync not triggered or internet issue

**Solution:**
1. Check internet connection
2. Go to Settings → Cloud Sync → Sync Now
3. Wait a few seconds
4. Check other device

### Issue: Data lost after switching accounts

**Cause:** This is expected behavior - local data is cleared

**Solution:**
- Data is safe in the cloud
- Login with original account to restore data

## Best Practices

1. **Always Sync Before Logout:**
   - App automatically syncs on logout
   - Or manually sync from Settings

2. **Use Same Login Method:**
   - Always use the same phone number or email
   - Don't switch between phone and email for same account

3. **Wait for Sync:**
   - After making changes, wait for sync to complete
   - Or manually trigger sync before switching devices

4. **Check Sync Status:**
   - Go to Settings → Cloud Sync
   - Verify "Last Sync" time is recent

## Security

- Each user can only access their own data
- Firestore security rules enforce data isolation
- Authentication required for all operations
- Local database cleared when switching accounts

## Limitations

- Sync happens every 5 minutes (not real-time)
- Large datasets may take longer to sync
- Requires internet connection for sync
- Local data is cleared when switching accounts (by design)

## Future Enhancements

1. **Real-time Sync:** Instant sync across devices
2. **Selective Sync:** Choose what to sync
3. **Conflict Resolution:** Handle simultaneous edits
4. **Offline Queue:** Queue changes when offline
5. **Data Merge:** Option to merge data instead of clearing

---

**Implementation Date:** November 8, 2024
**Status:** ✅ Complete and Working
