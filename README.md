# Attendance Tracker

A Flutter application for tracking student attendance in classes.

## Features

- **Class Management**: Create, edit, and delete classes/subjects
- **Student Management**: Add, edit, and delete students in classes
- **Attendance Recording**: Take attendance for a class on a specific date
- **Attendance History**: View past attendance records by date or student
- **Statistics**: View attendance statistics and export data
- **Cloud Sync**: Automatic cloud backup and restore based on login method (phone/email)
- **Authentication**: Secure login with phone number or Google account
- **Backup & Restore**: Export all data to backup files and restore from backups
- **Themes**: Light and dark mode support with multiple color schemes
- **Responsive Design**: Works on phones and tablets in any orientation

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/attendance_tracker.git
   ```

2. Navigate to the project directory:
   ```bash
   cd attendance_tracker
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── constants/       # App constants and theme definitions
├── models/          # Data models
├── providers/       # State management providers
├── repositories/    # Data access repositories
├── screens/         # UI screens
├── services/        # Services like database
├── utils/           # Utility functions
└── widgets/         # Reusable UI components
```

## Architecture

The app follows a layered architecture pattern:

1. **Presentation Layer**: UI components, screens, and widgets
2. **Business Logic Layer**: State management using Provider pattern
3. **Data Layer**: Repository pattern for data access and models
4. **Storage Layer**: SQLite database access using sqflite package

## Dependencies

- **sqflite**: SQLite database
- **provider**: State management
- **path_provider**: File system access
- **intl**: Internationalization and formatting
- **flutter_slidable**: Swipeable list items
- **table_calendar**: Calendar widget
- **shared_preferences**: Local storage
- **csv**: CSV file generation
- **share_plus**: Sharing functionality
- **file_picker**: File selection for backup restore
- **permission_handler**: Storage permissions for backup/restore

## Testing

Run the tests with:

```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors who have helped with the project