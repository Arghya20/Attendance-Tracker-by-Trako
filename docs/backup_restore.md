# Backup & Restore Feature

## Overview

The Attendance Tracker app now includes a comprehensive backup and restore system that allows users to:

- **Export all data** to a JSON backup file
- **Import data** from a backup file
- **Preserve data** when switching devices or reinstalling the app
- **Share backups** via any sharing method (email, cloud storage, etc.)

## How to Use

### Creating a Backup

1. Open the app and navigate to **Settings**
2. Tap on **"Backup & Restore"**
3. In the dialog, tap **"Create & Download Backup"**
4. The app will generate a backup file and open the share dialog
5. Choose where to save or share your backup file (email, Google Drive, etc.)

### Restoring from Backup

1. Open the app and navigate to **Settings**
2. Tap on **"Backup & Restore"**
3. Tap **"Select & Restore Backup"**
4. **Important**: Confirm that you want to replace all current data
5. Select your backup file from your device storage
6. Review the backup details (creation date, data counts)
7. Confirm the restore operation
8. **Restart the app** to see the restored data

## What's Included in Backups

The backup file contains all your attendance data:

- **Classes**: All class information including names and settings
- **Students**: All student records with names and roll numbers
- **Attendance Sessions**: All attendance session records
- **Attendance Records**: Individual attendance marks for each student

## Backup File Format

- **Format**: JSON (JavaScript Object Notation)
- **Extension**: `.json`
- **Structure**: Human-readable text format
- **Size**: Typically small (few KB to few MB depending on data)

## Important Notes

### ⚠️ Data Replacement Warning
- Restoring a backup **completely replaces** all current data
- This action **cannot be undone**
- Always create a current backup before restoring an old one

### 📱 Cross-Device Compatibility
- Backups work across different devices (Android to Android, etc.)
- Backup files are platform-independent
- No account or internet connection required

### 🔒 Privacy & Security
- Backup files are stored locally on your device
- No data is sent to external servers
- You control where backup files are stored and shared

## Troubleshooting

### "Permission Denied" Error
- Grant storage permissions when prompted
- On Android 11+, you may need to enable "All files access" in app settings

### "Invalid Backup File" Error
- Ensure the file is a valid JSON backup created by this app
- Check that the file hasn't been corrupted or modified

### "Failed to Create Backup" Error
- Ensure you have sufficient storage space
- Check that the app has necessary permissions

### App Doesn't Show Restored Data
- **Restart the app completely** after restoring
- Force-close and reopen the app

## Best Practices

1. **Regular Backups**: Create backups regularly, especially before major changes
2. **Safe Storage**: Store backup files in multiple locations (cloud storage, email, etc.)
3. **Test Restores**: Occasionally test that your backups can be restored successfully
4. **Clear Naming**: Use descriptive names for backup files (e.g., "attendance_backup_2024_01_15.json")

## Technical Details

- **Backup Format Version**: 1.0
- **Database Version Compatibility**: Automatically handled
- **File Size**: Varies based on data (typically 1KB - 10MB)
- **Compression**: None (human-readable JSON)

## Support

If you encounter issues with backup/restore functionality:

1. Check that you're using the latest version of the app
2. Ensure you have sufficient storage space and permissions
3. Try creating a new backup to test the export functionality
4. For persistent issues, check the app logs or contact support

---

*This feature ensures your attendance data is never lost, giving you peace of mind when switching devices or reinstalling the app.*