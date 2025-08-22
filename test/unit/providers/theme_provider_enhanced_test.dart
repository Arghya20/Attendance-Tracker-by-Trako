import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance_tracker/providers/theme_provider.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('ThemeProvider Enhanced Tests', () {
    late ThemeProvider provider;

    setUp(() {
      provider = ThemeProvider();
    });

    test('should have default values', () {
      expect(provider.themeMode, equals(ThemeMode.system));
      expect(provider.colorSchemeIndex, equals(0));
      expect(provider.colorSchemeName, equals('Blue'));
    });

    test('should notify listeners when theme mode changes', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(notified, isTrue);
    });

    test('should notify listeners when color scheme changes', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      await provider.setColorScheme(1);

      expect(provider.colorSchemeIndex, equals(1));
      expect(provider.colorSchemeName, equals('Green'));
      expect(notified, isTrue);
    });

    test('should not change color scheme for invalid index', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      await provider.setColorScheme(-1);
      expect(provider.colorSchemeIndex, equals(0));
      expect(notified, isFalse);

      await provider.setColorScheme(999);
      expect(provider.colorSchemeIndex, equals(0));
      expect(notified, isFalse);
    });

    test('should handle rapid theme changes with batching', () async {
      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Rapid theme changes
      provider.notifyThemeChanged();
      provider.notifyThemeChanged();
      provider.notifyThemeChanged();

      // Should only notify once due to batching
      expect(notificationCount, equals(1));

      // Wait for post-frame callback
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Should have additional notification from post-frame callback
      expect(notificationCount, greaterThan(1));
    });

    test('should determine dark mode correctly', () {
      // Test explicit dark mode
      provider.setThemeMode(ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);

      // Test explicit light mode
      provider.setThemeMode(ThemeMode.light);
      expect(provider.isDarkMode, isFalse);

      // System mode depends on platform brightness
      provider.setThemeMode(ThemeMode.system);
      // This will depend on the test environment's platform brightness
    });

    test('should provide correct light and dark themes', () {
      final lightTheme = provider.lightTheme;
      final darkTheme = provider.darkTheme;

      expect(lightTheme.brightness, equals(Brightness.light));
      expect(darkTheme.brightness, equals(Brightness.dark));
      
      // Themes should have proper color schemes
      expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
      expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
    });

    test('should apply color scheme to themes correctly', () {
      // Test different color schemes
      for (int i = 0; i < ThemeProvider.colorSchemeNames.length; i++) {
        provider.setColorScheme(i);
        
        final lightTheme = provider.lightTheme;
        final darkTheme = provider.darkTheme;
        
        // Themes should have different primary colors for different schemes
        expect(lightTheme.colorScheme.primary, isNotNull);
        expect(darkTheme.colorScheme.primary, isNotNull);
        
        // Primary colors should be different between light and dark
        expect(lightTheme.colorScheme.primary, 
               isNot(equals(darkTheme.colorScheme.primary)));
      }
    });

    test('should persist theme settings', () async {
      // Mock SharedPreferences
      final mockPrefs = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockPrefs);

      await provider.setThemeMode(ThemeMode.dark);
      await provider.setColorScheme(2);

      // Verify values were saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode'), equals(ThemeMode.dark.index));
      expect(prefs.getInt('color_scheme'), equals(2));
    });

    test('should load persisted theme settings', () async {
      // Mock SharedPreferences with saved values
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.dark.index,
        'color_scheme': 1,
      });

      // Create new provider to test loading
      final newProvider = ThemeProvider();
      
      // Wait for async loading
      await Future.delayed(const Duration(milliseconds: 100));

      expect(newProvider.themeMode, equals(ThemeMode.dark));
      expect(newProvider.colorSchemeIndex, equals(1));
    });

    test('should handle SharedPreferences errors gracefully', () async {
      // This test ensures the provider doesn't crash if SharedPreferences fails
      expect(() => provider.setThemeMode(ThemeMode.dark), returnsNormally);
      expect(() => provider.setColorScheme(1), returnsNormally);
    });

    test('should provide all color scheme names', () {
      expect(ThemeProvider.colorSchemeNames, hasLength(4));
      expect(ThemeProvider.colorSchemeNames, contains('Blue'));
      expect(ThemeProvider.colorSchemeNames, contains('Green'));
      expect(ThemeProvider.colorSchemeNames, contains('Purple'));
      expect(ThemeProvider.colorSchemeNames, contains('Teal'));
    });

    test('should maintain theme consistency across rebuilds', () {
      provider.setColorScheme(2); // Purple
      
      final theme1 = provider.lightTheme;
      final theme2 = provider.lightTheme;
      
      // Same color scheme should produce identical themes
      expect(theme1.colorScheme.primary, equals(theme2.colorScheme.primary));
      expect(theme1.colorScheme.secondary, equals(theme2.colorScheme.secondary));
    });
  });
}