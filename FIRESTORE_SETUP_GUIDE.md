# Firestore Setup Guide for Cloud Sync

## Prerequisites

- Firebase project already set up (from previous authentication setup)
- Firebase CLI installed (optional, for deploying rules via command line)

## Step 1: Enable Cloud Firestore

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on **Firestore Database** in the left sidebar
4. Click **Create database**
5. Choose **Start in production mode** (we'll add custom rules)
6. Select a Cloud Firestore location (choose closest to your users)
7. Click **Enable**

## Step 2: Set Up Security Rules

### Option A: Using Firebase Console (Recommended for beginners)

1. In Firebase Console, go to **Firestore Database**
2. Click on the **Rules** tab
3. Replace the existing rules with the content from `firestore.rules` file
4. Click **Publish**

### Option B: Using Firebase CLI

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```bash
   firebase init firestore
   ```
   - Select your Firebase project
   - Accept default file names (firestore.rules and firestore.indexes.json)

4. The `firestore.rules` file is already created in your project root

5. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Step 3: Verify Security Rules

1. Go to Firebase Console > Firestore Database > Rules
2. Verify the rules are deployed correctly
3. Check the rules match the content in `firestore.rules`

## Step 4: Test the Setup

### Test 1: Create Data
1. Run your app
2. Log in with phone or email
3. Create some test data (classes, students)
4. Go to Firebase Console > Firestore Database > Data
5. You should see a collection named `users_by_phone` or `users_by_email`
6. Click on the collection to see your data

### Test 2: Auto-Restore
1. Clear app data or uninstall the app
2. Reinstall and log in with the same credentials
3. Your data should be automatically restored

### Test 3: Manual Sync
1. Go to Settings in the app
2. Find the Cloud Sync card
3. Click "Sync Now"
4. Check Firebase Console to see updated timestamp

## Understanding the Security Rules

The security rules ensure that:

1. **Phone Number Users**: Can only access data stored under their phone number
   ```
   users_by_phone/+1234567890/
   ```

2. **Email Users**: Can only access data stored under their email
   ```
   users_by_email/user@example_com/
   ```

3. **Fallback**: Users without phone or email use their UID
   ```
   users_by_uid/firebase_uid/
   ```

4. **No Cross-Access**: Users cannot access other users' data

## Data Structure in Firestore

```
Firestore Database
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

## Monitoring and Maintenance

### View Usage
1. Go to Firebase Console > Firestore Database > Usage
2. Monitor:
   - Document reads/writes
   - Storage usage
   - Network egress

### View Logs
1. Go to Firebase Console > Firestore Database > Logs
2. Check for any errors or security rule violations

### Backup Data
Firebase automatically backs up Firestore data, but you can also:
1. Export data manually from Firebase Console
2. Set up automated exports (requires Blaze plan)

## Pricing

### Free Tier (Spark Plan)
- 50,000 document reads per day
- 20,000 document writes per day
- 20,000 document deletes per day
- 1 GiB storage

This is sufficient for:
- ~100 users with moderate usage
- ~500 syncs per day
- Several months of data

### Paid Tier (Blaze Plan)
Only pay for what you use beyond free tier:
- $0.06 per 100,000 document reads
- $0.18 per 100,000 document writes
- $0.02 per 100,000 document deletes
- $0.18 per GiB storage

## Troubleshooting

### Error: Permission Denied
**Cause**: Security rules not properly configured or user not authenticated

**Solution**:
1. Check security rules in Firebase Console
2. Verify user is logged in
3. Check console logs for authentication token

### Error: Quota Exceeded
**Cause**: Exceeded free tier limits

**Solution**:
1. Check usage in Firebase Console
2. Optimize sync frequency
3. Upgrade to Blaze plan if needed

### Data Not Syncing
**Cause**: Network issues or Firestore not enabled

**Solution**:
1. Check internet connection
2. Verify Firestore is enabled in Firebase Console
3. Check app logs for errors

### Old Data Appearing
**Cause**: Cached data or sync conflict

**Solution**:
1. Clear app cache
2. Force manual sync
3. Check last_sync timestamp in Firestore

## Best Practices

1. **Monitor Usage**: Regularly check Firebase Console for usage patterns
2. **Test Rules**: Test security rules thoroughly before production
3. **Backup Important Data**: Use the backup/restore feature for critical data
4. **Optimize Sync**: Adjust sync frequency based on user needs
5. **Handle Errors**: Implement proper error handling in the app
6. **User Education**: Inform users about cloud sync feature

## Security Considerations

1. **Never Store Sensitive Data**: Don't store passwords or payment info
2. **Validate Data**: Implement data validation in security rules
3. **Monitor Access**: Regularly check Firestore logs for suspicious activity
4. **Keep Rules Updated**: Update security rules as app evolves
5. **Use HTTPS**: Always use secure connections (handled by Firebase)

## Support

For issues with Firestore setup:
1. Check [Firebase Documentation](https://firebase.google.com/docs/firestore)
2. Visit [Firebase Support](https://firebase.google.com/support)
3. Check [Stack Overflow](https://stackoverflow.com/questions/tagged/google-cloud-firestore)

## Next Steps

After setting up Firestore:
1. Test all sync scenarios
2. Monitor usage for a few days
3. Gather user feedback
4. Optimize based on usage patterns
5. Consider implementing incremental sync for large datasets
