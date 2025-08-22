import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/main.dart';
import 'package:attendance_tracker/providers/theme_provider.dart';
import 'package:attendance_tracker/screens/home_screen.dart';
import 'package:attendance_tracker/screens/settings_screen.dart';
import 'package:neopop/neopop.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Integration Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should change Add Class button color when theme changes in settings', (tester) async {
      // Arrange - Start the app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MyApp(),
        ),
      );

      // Wait for splash screen and navigate to home
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash screen if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Should be on home screen now
      expect(find.byType(HomeScreen), findsOneWidget);

      // Find the initial Add Class button and get its color
      expect(find.byType(NeoPopTiltedButton), findsOneWidget);
      final initialButton = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      final initialColor = initialButton.color;

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should be on settings screen
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Find and tap a different color scheme (Green - index 1)
      final colorSchemeOptions = find.text('Green');
      expect(colorSchemeOptions, findsOneWidget);
      await tester.tap(colorSchemeOptions);
      await tester.pumpAndSettle();

      // Navigate back to home screen
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should be back on home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Check that the Add Class button color has changed
      final updatedButton = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      final updatedColor = updatedButton.color;

      // Colors should be different
      expect(updatedColor, isNot(equals(initialColor)));
    });

    testWidgets('should persist theme changes across app restarts', (tester) async {
      // First app session - change theme
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate to settings and change color scheme
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Purple'));
      await tester.pumpAndSettle();

      // Go back to home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Get the button color after theme change
      final buttonAfterChange = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      final colorAfterChange = buttonAfterChange.color;

      // Simulate app restart by creating new app instance
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Check that the theme persisted
      final buttonAfterRestart = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      final colorAfterRestart = buttonAfterRestart.color;

      // Color should be the same as before restart
      expect(colorAfterRestart, equals(colorAfterChange));
    });

    testWidgets('should handle theme mode changes (light/dark)', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Find and tap Dark mode
      final darkModeButton = find.text('Dark');
      expect(darkModeButton, findsOneWidget);
      await tester.tap(darkModeButton);
      await tester.pumpAndSettle();

      // Go back to home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify the app is in dark mode by checking scaffold background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      
      // In dark mode, the theme brightness should be dark
      expect(theme.brightness, equals(Brightness.dark));
    });

    testWidgets('should maintain theme consistency across navigation', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Change theme in settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Teal'));
      await tester.pumpAndSettle();

      // Get the theme color in settings
      final settingsTheme = Theme.of(tester.element(find.byType(SettingsScreen)));
      final settingsPrimaryColor = settingsTheme.colorScheme.primary;

      // Navigate back to home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Get the theme color in home screen
      final homeTheme = Theme.of(tester.element(find.byType(HomeScreen)));
      final homePrimaryColor = homeTheme.colorScheme.primary;

      // Colors should be consistent across screens
      expect(homePrimaryColor, equals(settingsPrimaryColor));

      // Button should also use the same color
      final button = tester.widget<NeoPopTiltedButton>(
        find.byType(NeoPopTiltedButton),
      );
      expect(button.color, equals(homePrimaryColor));
    });

    testWidgets('should handle rapid theme changes without errors', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Rapidly change color schemes
      final colorSchemes = ['Green', 'Purple', 'Teal', 'Blue'];
      
      for (final colorScheme in colorSchemes) {
        await tester.tap(find.text(colorScheme));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // Should not have any errors and should end up with Blue theme
      expect(tester.takeException(), isNull);

      // Navigate back to home to verify everything still works
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Button should still be functional
      expect(find.byType(NeoPopTiltedButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should show visual feedback when theme changes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash if present
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Change color scheme
      await tester.tap(find.text('Green'));
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Color scheme changed to Green'), findsOneWidget);

      // Wait for snackbar to disappear
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Change theme mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Should show success snackbar for theme mode change
      expect(find.text('Theme mode changed to Dark'), findsOneWidget);
    });
  });
}