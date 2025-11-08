# Account Switching Bug Fix

## The Problem

When switching between Google accounts, the first user's data was being lost:

### Scenario:
1. User A logs in with Gmail A
2. User A adds classes and data
3. Data syncs to cloud ✓
4. User A logs out
5. User B logs in with Gmail B
6. User B sees User A's data (wrong!) ❌
7. Local database gets cleared
8. User B adds their own data
9. User B logs out
10. User A logs back in with Gmail A
11. **User A's data is gone!** ❌

## Root Cause

The bug was in the `autoRestoreOnLogin` method in `cloud_sync_service.dart`:

```dart
if (localClassCount > 0) {
  debugPrint('Local data exists, skipping auto-restore');
  // But still sync to cloud to ensure cloud has latest data
  await uploadToCloud(user);  // ← BUG HERE!
  return false;
}
```

### What Was Happening:

1. User B logs in
2. Local DB still has User A's data (not cleared yet)
3. `autoRestoreOnLogin` runs
4. Sees local data exists (User A's data)
5. **Uploads User A's data to User B's cloud storage!** ❌
6. User A's cloud data gets overwritten
7. When User A logs back in, their data is gone

## The Fix

### 1. Removed Problematic Sync

In `cloud_sync_service.dart`:

**Before:**
```dart
if (localClassCount > 0) {
  debugPrint('Local data exists, skipping auto-restore');
  await uploadToCloud(user);  // ← Removed this!
  return false;
}
```

**After:**
```dart
if (localClassCount > 0) {
  debugPrint('Local data exists ($localClassCount classes), skipping auto-restore');
  // Don't sync here - data will be synced by periodic sync or after changes
  // Syncing here could overwrite cloud data with wrong user's data
  return false;
}
```

### 2. Improved Logging

In `auth_service.dart`:

Added better logging to track account switches:

```dart
bool isDifferentUser = _lastUserId != null && _lastUserId != newUser.uid;

if (isDifferentUser) {
  debugPrint('Different user detected (old: $_lastUserId, new: ${newUser.uid})');
  debugPrint('Clearing local database for account switch...');
  await _clearLocalDatabase();
}
```

## How It Works Now

### Correct Flow:

1. **User A logs in:**
   - No previous user → No clearing
   - Check cloud data → Restore if exists
   - Enable sync
   - User A adds data → Syncs to User A's cloud

2. **User A logs out:**
   - Sync data to cloud (final backup)
   - Disable sync

3. **User B logs in:**
   - Different user detected!
   - **Clear local database first** ✓
   - Check User B's cloud data → Restore if exists
   - Enable sync
   - User B adds data → Syncs to User B's cloud

4. **User B logs out:**
   - Sync data to cloud (final backup)
   - Disable sync

5. **User A logs back in:**
   - Different user detected!
   - **Clear local database first** ✓
   - Check User A's cloud data → **Restore User A's data** ✓
   - Enable sync
   - User A sees their data! ✓

## Key Changes

### 1. No Sync on Login with Existing Data

- Removed automatic sync when local data exists on login
- Prevents uploading wrong user's data to cloud
- Data will sync naturally after user makes changes

### 2. Clear Database Before Restore

- Database is cleared BEFORE checking cloud data
- Ensures clean slate for new user
- Prevents data mixing

### 3. Better Logging

- Track which user is logging in
- Log when database is cleared
- Log when data is restored

## Testing

### Test Account Switching:

1. **Login with Gmail A:**
   ```
   - Add class "Math A"
   - Wait for sync (check Settings)
   - Verify data in Firebase Console
   ```

2. **Logout and Login with Gmail B:**
   ```
   - Should NOT see "Math A"
   - Add class "Physics B"
   - Wait for sync
   - Verify data in Firebase Console (separate from Gmail A)
   ```

3. **Logout and Login with Gmail A again:**
   ```
   - Should see "Math A" (restored from cloud)
   - Should NOT see "Physics B"
   - Data is intact! ✓
   ```

4. **Check Firebase Console:**
   ```
   - users_by_email/gmail_a_com/ → has "Math A"
   - users_by_email/gmail_b_com/ → has "Physics B"
   - Data is properly isolated ✓
   ```

## Verification

### Check App Logs:

When switching accounts, you should see:

```
Different user detected (old: user_a_id, new: user_b_id)
Clearing local database for account switch...
Local database cleared successfully
Checking for auto-restore on login...
Local database is empty, restoring from cloud...
Cloud download completed successfully
Data restored from cloud for user: user_b_id
```

### Check Firebase Console:

Each user should have their own data:
- `users_by_email/user1_gmail_com/` → User 1's data
- `users_by_email/user2_gmail_com/` → User 2's data

## Edge Cases Handled

### 1. First Time User
- No cloud data exists
- Empty local database
- Starts fresh ✓

### 2. Returning User
- Cloud data exists
- Empty local database (after clearing)
- Data restored ✓

### 3. Same User, Multiple Devices
- Login on Device 2
- Same user ID → No clearing
- Data restored from cloud ✓

### 4. Rapid Account Switching
- Each switch clears database
- Each switch restores correct user's data
- No data mixing ✓

## Performance Impact

- **Minimal:** Only affects login flow
- **No extra syncs:** Removed problematic sync on login
- **Faster:** No unnecessary uploads

## Security

- ✅ Each user's data is isolated
- ✅ Users cannot access other users' data
- ✅ Firestore security rules enforce isolation
- ✅ Local database cleared on account switch

## Summary

The fix ensures:
- ✅ Each user's data is properly isolated
- ✅ Data is not lost when switching accounts
- ✅ Data is correctly restored when logging back in
- ✅ No data mixing between users
- ✅ Better logging for debugging

---

**Bug Fixed:** November 8, 2024
**Status:** ✅ Resolved
**Severity:** High (Data Loss)
**Impact:** All users switching between accounts
