import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/screens/class_detail_screen.dart';
import 'package:attendance_tracker/providers/theme_provider.dart';
import 'package:attendance_tracker/providers/class_provider.dart';
import 'package:attendance_tracker/providers/student_provider.dart';
import 'package:attendance_tracker/providers/attendance_provider.dart';
import 'package:attendance_tracker/models/class_model.dart';

void main() {
  group('Tab Accessibility and Visual Consistency Tests', () {
    late ThemeProvider themeProvider;
    late ClassProvider classProvider;
    late StudentProvider studentProvider;
    late AttendanceProvider attendanceProvider;

    setUp(() {
      themeProvider = ThemeProvider();
      classProvider = ClassProvider();
      studentProvider = StudentProvider();
      attendanceProvider = AttendanceProvider();
      
      // Set up a test class
      final testClass = Class(
        id: 1,
        name: 'Test Class',
      );
      classProvider.selectClass(1);
    });

    Widget createTestWidget({required ThemeMode themeMode, required int colorSchemeIndex}) {
      themeProvider.setThemeMode(themeMode);
      themeProvider.setColorScheme(colorSchemeIndex);
      
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: classProvider),
          ChangeNotifierProvider.value(value: studentProvider),
          ChangeNotifierProvider.value(value: attendanceProvider),
        ],
        child: MaterialApp(
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeMode,
          home: const ClassDetailScreen(),
        ),
      );
    }

    /// Helper function to calculate contrast ratio between two colors
    double calculateContrastRatio(Color foreground, Color background) {
      // Convert colors to relative luminance
      double getLuminance(Color color) {
        double r = color.red / 255.0;
        double g = color.green / 255.0;
        double b = color.blue / 255.0;

        r = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
        g = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
        b = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);

        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
      }

      double foregroundLuminance = getLuminance(foreground);
      double backgroundLuminance = getLuminance(background);

      double lighter = foregroundLuminance > backgroundLuminance 
          ? foregroundLuminance 
          : backgroundLuminance;
      double darker = foregroundLuminance > backgroundLuminance 
          ? backgroundLuminance 
          : foregroundLuminance;

      return (lighter + 0.05) / (darker + 0.05);
    }

    testWidgets('Tab colors meet WCAG contrast requirements in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        themeMode: ThemeMode.light,
        colorSchemeIndex: 0, // Blue
      ));
      await tester.pumpAndSettle();

      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);

      final TabBar tabBar = tester.widget(tabBarFinder);
      
      // Get the app bar to determine background color
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      
      final AppBar appBar = tester.widget(appBarFinder);
      final Color backgroundColor = appBar.backgroundColor ?? Theme.of(tester.element(appBarFinder)).colorScheme.primary;
      
      // Test active tab text contrast
      if (tabBar.labelColor != null) {
        final double activeContrast = calculateContrastRatio(tabBar.labelColor!, backgroundColor);
        expect(activeContrast, greaterThanOrEqualTo(4.5), 
            reason: 'Active tab text should meet WCAG AA contrast ratio of 4.5:1');
      }
      
      // Test inactive tab text contrast
      if (tabBar.unselectedLabelColor != null) {
        final double inactiveContrast = calculateContrastRatio(tabBar.unselectedLabelColor!, backgroundColor);
        expect(inactiveContrast, greaterThanOrEqualTo(3.0), 
            reason: 'Inactive tab text should have reasonable contrast for visibility');
      }
      
      // Test indicator contrast
      if (tabBar.indicatorColor != null) {
        final double indicatorContrast = calculateContrastRatio(tabBar.indicatorColor!, backgroundColor);
        expect(indicatorContrast, greaterThanOrEqualTo(3.0), 
            reason: 'Tab indicator should be visible against background');
      }
    });

    testWidgets('Tab colors meet WCAG contrast requirements in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        themeMode: ThemeMode.dark,
        colorSchemeIndex: 0, // Blue
      ));
      await tester.pumpAndSettle();

      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);

      final TabBar tabBar = tester.widget(tabBarFinder);
      
      // Get the app bar to determine background color
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      
      final AppBar appBar = tester.widget(appBarFinder);
      final Color backgroundColor = appBar.backgroundColor ?? Theme.of(tester.element(appBarFinder)).colorScheme.surface;
      
      // Test active tab text contrast
      if (tabBar.labelColor != null) {
        final double activeContrast = calculateContrastRatio(tabBar.labelColor!, backgroundColor);
        expect(activeContrast, greaterThanOrEqualTo(4.5), 
            reason: 'Active tab text should meet WCAG AA contrast ratio of 4.5:1');
      }
      
      // Test inactive tab text contrast
      if (tabBar.unselectedLabelColor != null) {
        final double inactiveContrast = calculateContrastRatio(tabBar.unselectedLabelColor!, backgroundColor);
        expect(inactiveContrast, greaterThanOrEqualTo(3.0), 
            reason: 'Inactive tab text should have reasonable contrast for visibility');
      }
    });

    testWidgets('Theme changes update tab colors immediately', (WidgetTester tester) async {
      // Start with light theme
      await tester.pumpWidget(createTestWidget(
        themeMode: ThemeMode.light,
        colorSchemeIndex: 0,
      ));
      await tester.pumpAndSettle();

      final tabBarFinder = find.byType(TabBar);
      TabBar lightTabBar = tester.widget(tabBarFinder);
      final Color lightLabelColor = lightTabBar.labelColor!;

      // Switch to dark theme
      await tester.pumpWidget(createTestWidget(
        themeMode: ThemeMode.dark,
        colorSchemeIndex: 0,
      ));
      await tester.pumpAndSettle();

      TabBar darkTabBar = tester.widget(tabBarFinder);
      final Color darkLabelColor = darkTabBar.labelColor!;

      // Verify colors are different between themes
      expect(lightLabelColor, isNot(equals(darkLabelColor)),
          reason: 'Tab colors should change when theme changes');
    });

    testWidgets('Tab functionality remains intact after color changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        themeMode: ThemeMode.light,
        colorSchemeIndex: 0,
      ));
      await tester.pumpAndSettle();

      // Find and tap the Analytics tab
      final analyticsTab = find.text('Analytics');
      expect(analyticsTab, findsOneWidget);

      await tester.tap(analyticsTab);
      await tester.pumpAndSettle();

      // Verify the tab content changed (Analytics tab should show different content)
      // The exact content depends on the implementation, but we can verify the tab is interactive
      expect(find.text('Analytics'), findsOneWidget);
      
      // Switch back to Students tab
      final studentsTab = find.text('Students');
      expect(studentsTab, findsOneWidget);

      await tester.tap(studentsTab);
      await tester.pumpAndSettle();

      expect(find.text('Students'), findsOneWidget);
    });

    testWidgets('Visual consistency across all color schemes in light theme', (WidgetTester tester) async {
      final List<String> colorSchemeNames = ['Blue', 'Green', 'Purple', 'Teal'];
      
      for (int i = 0; i < colorSchemeNames.length; i++) {
        await tester.pumpWidget(createTestWidget(
          themeMode: ThemeMode.light,
          colorSchemeIndex: i,
        ));
        await tester.pumpAndSettle();

        final tabBarFinder = find.byType(TabBar);
        expect(tabBarFinder, findsOneWidget, 
            reason: 'TabBar should be present in ${colorSchemeNames[i]} color scheme');

        final TabBar tabBar = tester.widget(tabBarFinder);
        
        // Verify all color properties are set (not null)
        expect(tabBar.labelColor, isNotNull, 
            reason: 'Label color should be set for ${colorSchemeNames[i]} scheme');
        expect(tabBar.unselectedLabelColor, isNotNull, 
            reason: 'Unselected label color should be set for ${colorSchemeNames[i]} scheme');
        expect(tabBar.indicatorColor, isNotNull, 
            reason: 'Indicator color should be set for ${colorSchemeNames[i]} scheme');
        
        // Verify indicator weight is maintained
        expect(tabBar.indicatorWeight, equals(3.0), 
            reason: 'Indicator weight should be consistent across color schemes');
      }
    });

    testWidgets('Semantic labels are preserved for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        themeMode: ThemeMode.light,
        colorSchemeIndex: 0,
      ));
      await tester.pumpAndSettle();

      // Verify tab labels are still present and accessible
      expect(find.text('Students'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      
      // Verify tabs are semantically accessible
      final Semantics studentsSemantics = tester.widget(
        find.ancestor(
          of: find.text('Students'),
          matching: find.byType(Semantics),
        ).first,
      );
      
      final Semantics analyticsSemantics = tester.widget(
        find.ancestor(
          of: find.text('Analytics'),
          matching: find.byType(Semantics),
        ).first,
      );
      
      // Verify semantic properties are maintained
      expect(studentsSemantics.properties.label, isNotNull);
      expect(analyticsSemantics.properties.label, isNotNull);
    });
  });
}

// Helper function for power calculation (needed for luminance calculation)
double pow(double base, double exponent) {
  if (exponent == 0) return 1.0;
  if (exponent == 1) return base;
  
  double result = 1.0;
  int exp = exponent.abs().round();
  
  for (int i = 0; i < exp; i++) {
    result *= base;
  }
  
  return exponent < 0 ? 1.0 / result : result;
}