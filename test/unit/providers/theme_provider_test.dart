import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;
    
    setUp(() {
      // Set up shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
    });
    
    test('initial theme mode should be system', () {
      // Assert
      expect(themeProvider.themeMode, equals(ThemeMode.system));
    });
    
    test('initial color scheme index should be 0', () {
      // Assert
      expect(themeProvider.colorSchemeIndex, equals(0));
    });
    
    test('setThemeMode should update theme mode', () async {
      // Act
      await themeProvider.setThemeMode(ThemeMode.dark);
      
      // Assert
      expect(themeProvider.themeMode, equals(ThemeMode.dark));
    });
    
    test('setColorScheme should update color scheme index', () async {
      // Act
      await themeProvider.setColorScheme(2);
      
      // Assert
      expect(themeProvider.colorSchemeIndex, equals(2));
    });
    
    test('setColorScheme should not update if index is out of range', () async {
      // Act
      await themeProvider.setColorScheme(-1);
      await themeProvider.setColorScheme(10);
      
      // Assert
      expect(themeProvider.colorSchemeIndex, equals(0));
    });
    
    test('colorSchemeName should return correct name', () {
      // Arrange
      final expectedNames = ThemeProvider.colorSchemeNames;
      
      // Act & Assert
      expect(themeProvider.colorSchemeName, equals(expectedNames[0]));
    });
    
    test('lightTheme and darkTheme should return ThemeData', () {
      // Act & Assert
      expect(themeProvider.lightTheme, isA<ThemeData>());
      expect(themeProvider.darkTheme, isA<ThemeData>());
    });
  });
}