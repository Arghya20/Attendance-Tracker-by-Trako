# Quick Start: Cloud Sync Setup

## 5-Minute Setup Guide

### Step 1: Install Dependencies (Already Done ✅)
```bash
flutter pub get
```

### Step 2: Enable Firestore in Firebase Console

1. Go to https://console.firebase.google.com/
2. Select your project
3. Click **Firestore Database** in left sidebar
4. Click **Create database**
5. Choose **Start in production mode**
6. Select your preferred location
7. Click **Enable**

### Step 3: Deploy Security Rules

#### Option A: Copy-Paste (Easiest)

1. In Firebase Console, go to **Firestore Database** > **Rules** tab
2. Copy the content from `firestore.rules` file in your project
3. Paste it into the rules editor
4. Click **Publish**

#### Option B: Firebase CLI

```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login
firebase login

# Initialize (if not done)
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

### Step 4: Test It!

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Login** with phone or email

3. **Create some data**:
   - Add a class
   - Add some students
   - Take attendance

4. **Check Firebase Console**:
   - Go to Firestore Database > Data
   - You should see `users_by_phone` or `users_by_email` collection
   - Your data should be there!

5. **Test Auto-Restore**:
   - Uninstall the app
   - Reinstall and run again
   - Login with same credentials
   - Your data should be restored automatically!

### Step 5: View Sync Status

1. Open the app
2. Go to **Settings** (gear icon)
3. See the **Cloud Sync** card at the top
4. Click **Sync Now** to manually trigger sync

## That's It! 🎉

Your app now has automatic cloud sync. Data will:
- ✅ Sync automatically every 5 minutes
- ✅ Sync when user logs out
- ✅ Restore automatically on reinstall

## Troubleshooting

### "Permission Denied" Error
- Make sure you deployed the security rules
- Check that user is logged in
- Verify rules in Firebase Console

### Data Not Appearing in Firestore
- Check internet connection
- Wait a few minutes for first sync
- Try manual sync from Settings
- Check app logs for errors

### Data Not Restoring
- Make sure using same phone/email to login
- Check if data exists in Firebase Console
- Try logging out and in again

## Need Help?

- **Technical Details**: See `CLOUD_SYNC_IMPLEMENTATION.md`
- **User Guide**: See `docs/cloud_sync_user_guide.md`
- **Full Setup**: See `FIRESTORE_SETUP_GUIDE.md`
- **Summary**: See `CLOUD_SYNC_SUMMARY.md`

## What's Next?

- Monitor usage in Firebase Console
- Test on multiple devices
- Share with users
- Gather feedback
- Optimize based on usage patterns

---

**Estimated Setup Time**: 5-10 minutes
**Difficulty**: Easy
**Cost**: Free (for typical usage)
