import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';
  
  ThemeMode _themeMode = ThemeMode.system;
  int _colorSchemeIndex = 0;
  
  // Available color schemes
  static const List<ColorScheme> _lightColorSchemes = [
    // Blue (default)
    ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1565C0),
      onPrimary: Colors.white,
      secondary: Color(0xFFFFA000),
      onSecondary: Colors.black,
      error: Color(0xFFC62828),
      onError: Colors.white,
      background: Color(0xFFF4F5FF),
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    // Green
    ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2E7D32),
      onPrimary: Colors.white,
      secondary: Color(0xFFFF6F00),
      onSecondary: Colors.black,
      error: Color(0xFFC62828),
      onError: Colors.white,
      background: Color(0xFFF4F5FF),
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    // Purple
    ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF6A1B9A),
      onPrimary: Colors.white,
      secondary: Color(0xFFFF6D00),
      onSecondary: Colors.black,
      error: Color(0xFFC62828),
      onError: Colors.white,
      background: Color(0xFFF4F5FF),
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    // Teal
    ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF00695C),
      onPrimary: Colors.white,
      secondary: Color(0xFFFF5722),
      onSecondary: Colors.black,
      error: Color(0xFFC62828),
      onError: Colors.white,
      background: Color(0xFFF4F5FF),
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
  ];
  
  static const List<ColorScheme> _darkColorSchemes = [
    // Blue (default)
    ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF42A5F5),
      onPrimary: Colors.black,
      secondary: Color(0xFFFFD54F),
      onSecondary: Colors.black,
      error: Color(0xFFEF5350),
      onError: Colors.black,
      background: Color(0xFF0D0D0D),
      onBackground: Colors.white,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
    ),
    // Green
    ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF66BB6A),
      onPrimary: Colors.black,
      secondary: Color(0xFFFFB74D),
      onSecondary: Colors.black,
      error: Color(0xFFEF5350),
      onError: Colors.black,
      background: Color(0xFF0D0D0D),
      onBackground: Colors.white,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
    ),
    // Purple
    ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFAB47BC),
      onPrimary: Colors.black,
      secondary: Color(0xFFFFB74D),
      onSecondary: Colors.black,
      error: Color(0xFFEF5350),
      onError: Colors.black,
      background: Color(0xFF0D0D0D),
      onBackground: Colors.white,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
    ),
    // Teal
    ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF26A69A),
      onPrimary: Colors.black,
      secondary: Color(0xFFFF8A65),
      onSecondary: Colors.black,
      error: Color(0xFFEF5350),
      onError: Colors.black,
      background: Color(0xFF0D0D0D),
      onBackground: Colors.white,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
    ),
  ];
  
  // Theme names
  static const List<String> colorSchemeNames = [
    'Blue',
    'Green',
    'Purple',
    'Teal',
  ];
  
  ThemeMode get themeMode => _themeMode;
  int get colorSchemeIndex => _colorSchemeIndex;
  String get colorSchemeName => colorSchemeNames[_colorSchemeIndex];
  
  ThemeProvider() {
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final colorSchemeIndex = prefs.getInt(_colorSchemeKey) ?? 0;
    
    _themeMode = ThemeMode.values[themeModeIndex];
    _colorSchemeIndex = colorSchemeIndex;
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyThemeChanged();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }
  
  Future<void> setColorScheme(int index) async {
    if (index >= 0 && index < _lightColorSchemes.length) {
      _colorSchemeIndex = index;
      notifyThemeChanged();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_colorSchemeKey, index);
    }
  }
  
  // Enhanced theme change notification with batching
  bool _isNotifying = false;
  
  void notifyThemeChanged() {
    if (_isNotifying) return; // Prevent rapid successive notifications
    
    _isNotifying = true;
    notifyListeners();
    
    // Force a frame rebuild to ensure all widgets update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
      _isNotifying = false;
    });
  }
  
  bool get isDarkMode => 
      _themeMode == ThemeMode.dark || 
      (_themeMode == ThemeMode.system && 
       WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
  
  ThemeData get lightTheme {
    return _applyColorScheme(AppConstants.getLightTheme(), _lightColorSchemes[_colorSchemeIndex]);
  }
  
  ThemeData get darkTheme {
    return _applyColorScheme(AppConstants.getDarkTheme(), _darkColorSchemes[_colorSchemeIndex]);
  }
  
  ThemeData _applyColorScheme(ThemeData baseTheme, ColorScheme colorScheme) {
    return baseTheme.copyWith(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.primary,
        foregroundColor: isDarkMode ? colorScheme.onSurface : colorScheme.onPrimary,
      ),
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      tabBarTheme: baseTheme.tabBarTheme.copyWith(
        labelColor: colorScheme.primary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}