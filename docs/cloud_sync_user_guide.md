# Cloud Sync - User Guide

## What is Cloud Sync?

Cloud Sync automatically backs up your attendance data to the cloud and restores it when you reinstall the app. Your data is always safe and accessible from any device where you log in.

## How It Works

### Automatic Backup
- Your data is automatically backed up to the cloud every 5 minutes
- Data is also backed up when you log out
- No manual action required

### Automatic Restore
- When you reinstall the app and log in, your data is automatically restored
- Works with both phone number and email login methods
- Your classes, students, and attendance records are all restored

## Login Methods

### Phone Number Login
If you log in with your phone number, your data is linked to that phone number. Always use the same phone number to access your data.

### Email Login (Google)
If you log in with your Google account, your data is linked to that email address. Always use the same Google account to access your data.

## Viewing Sync Status

1. Open the app
2. Go to **Settings** (gear icon)
3. Look for the **Cloud Sync** card at the top
4. You can see:
   - Current sync status
   - Last sync time
   - Amount of data in cloud
   - Your sync method (phone or email)

## Manual Sync

While sync happens automatically, you can also trigger a manual sync:

1. Go to **Settings**
2. Find the **Cloud Sync** card
3. Tap **Sync Now** button
4. Wait for confirmation message

## Reinstalling the App

If you need to reinstall the app:

1. Uninstall the app (your data is safe in the cloud)
2. Reinstall the app from the app store
3. Log in with the **same phone number or email** you used before
4. Your data will be automatically restored
5. Continue using the app as normal

## Important Notes

### Use the Same Login Method
- Always use the same phone number or email to access your data
- If you switch login methods, you'll start with a fresh database
- To link multiple login methods, use the account linking feature in Settings

### Internet Connection Required
- Cloud sync requires an internet connection
- If you're offline, sync will happen automatically when you're back online
- Local data is always available, even offline

### Data Privacy
- Your data is stored securely in Firebase Cloud Firestore
- Only you can access your data
- Data is encrypted in transit and at rest

### Multiple Devices
- You can use the same account on multiple devices
- Data syncs across all devices
- Changes on one device will appear on other devices after sync

## Troubleshooting

### Data Not Syncing
1. Check your internet connection
2. Make sure you're logged in
3. Try manual sync from Settings
4. Check sync status in Settings

### Data Not Restored After Reinstall
1. Make sure you're using the same phone number or email
2. Check if you had data before (look at cloud data count in Settings)
3. Try logging out and logging in again
4. Contact support if issue persists

### Sync Taking Too Long
- Large amounts of data may take longer to sync
- Check your internet connection speed
- Wait a few minutes and check sync status again

## FAQ

**Q: Is my data safe in the cloud?**
A: Yes, your data is stored securely in Firebase Cloud Firestore with encryption.

**Q: Can I disable cloud sync?**
A: Cloud sync is automatic and cannot be disabled. This ensures your data is always backed up.

**Q: How much data can I store?**
A: There's no practical limit for typical attendance tracking usage.

**Q: What happens if I change my phone number?**
A: You can link your new phone number to your existing account in Settings > Account > Link Phone Number.

**Q: Can I access my data from multiple devices?**
A: Yes, log in with the same account on any device to access your data.

**Q: What if I accidentally delete data?**
A: The most recent synced version is stored in the cloud. You can restore from the last sync.

**Q: Does sync use a lot of data?**
A: No, the data is relatively small. A typical sync uses less than 1MB of data.

## Support

If you encounter any issues with cloud sync:
1. Check the troubleshooting section above
2. Try logging out and logging in again
3. Check your internet connection
4. Contact app support with details of the issue
