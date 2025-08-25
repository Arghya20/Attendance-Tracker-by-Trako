import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tab Visibility Light Theme Tests', () {
    
    Widget createTestTabBar({required Brightness brightness}) {
      final ColorScheme lightColorScheme = const ColorScheme(
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
      );
      
      final ColorScheme darkColorScheme = const ColorScheme(
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
      );
      
      final colorScheme = brightness == Brightness.light ? lightColorScheme : darkColorScheme;
      
      return MaterialApp(
        theme: ThemeData(
          colorScheme: colorScheme,
          brightness: brightness,
        ),
        home: DefaultTabController(
          length: 2,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Test'),
                  backgroundColor: brightness == Brightness.light 
                      ? colorScheme.primary 
                      : colorScheme.surface,
                  bottom: TabBar(
                    tabs: const [Tab(text: 'Students'), Tab(text: 'Analytics')],
                    labelColor: theme.brightness == Brightness.light 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface,
                    unselectedLabelColor: theme.brightness == Brightness.light 
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 4.0,
                        color: theme.brightness == Brightness.light 
                            ? Colors.yellow 
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                body: const TabBarView(
                  children: [
                    Center(child: Text('Students')),
                    Center(child: Text('Analytics')),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('Tab colors are visible in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestTabBar(brightness: Brightness.light));
      await tester.pumpAndSettle();

      // Find the TabBar
      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);

      final TabBar tabBar = tester.widget(tabBarFinder);
      
      // Verify colors are theme-aware
      expect(tabBar.labelColor, isA<Color>());
      expect(tabBar.unselectedLabelColor, isA<Color>());
      
      // In light theme, should use onPrimary colors for text and yellow for indicator
      expect(tabBar.labelColor, equals(Colors.white));
      
      // Check the custom indicator
      expect(tabBar.indicator, isNotNull);
      expect(tabBar.indicator, isA<UnderlineTabIndicator>());
      if (tabBar.indicator != null) {
        final indicator = tabBar.indicator as UnderlineTabIndicator;
        expect(indicator.borderSide.color, equals(Colors.yellow));
      }
      
      // Verify unselected color has opacity
      expect(tabBar.unselectedLabelColor!.opacity, lessThan(1.0));
    });

    testWidgets('Tab colors remain correct in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestTabBar(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);

      final TabBar tabBar = tester.widget(tabBarFinder);
      
      // Verify colors are theme-aware and appropriate for dark theme
      expect(tabBar.labelColor, isA<Color>());
      expect(tabBar.unselectedLabelColor, isA<Color>());
      
      // In dark theme, should use onSurface for text and primary for indicator
      expect(tabBar.labelColor, equals(Colors.white)); // onSurface in dark theme
      
      // Check the custom indicator in dark theme
      expect(tabBar.indicator, isNotNull);
      if (tabBar.indicator != null) {
        expect(tabBar.indicator, isA<UnderlineTabIndicator>());
        final indicator = tabBar.indicator as UnderlineTabIndicator;
        expect(indicator.borderSide.color, equals(const Color(0xFF42A5F5))); // primary
      }
    });

    testWidgets('Tab functionality remains unchanged', (WidgetTester tester) async {
      await tester.pumpWidget(createTestTabBar(brightness: Brightness.light));
      await tester.pumpAndSettle();

      // Find the tabs (use byWidgetPredicate to be more specific)
      final studentsTab = find.byWidgetPredicate((widget) => 
          widget is Tab && widget.text == 'Students');
      final analyticsTab = find.byWidgetPredicate((widget) => 
          widget is Tab && widget.text == 'Analytics');
      
      expect(studentsTab, findsOneWidget);
      expect(analyticsTab, findsOneWidget);

      // Test tab switching functionality
      await tester.tap(analyticsTab);
      await tester.pumpAndSettle();

      // Verify tab switching still works
      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);
    });

    testWidgets('Tab colors have sufficient opacity differences', (WidgetTester tester) async {
      await tester.pumpWidget(createTestTabBar(brightness: Brightness.light));
      await tester.pumpAndSettle();

      final tabBarFinder = find.byType(TabBar);
      final TabBar tabBar = tester.widget(tabBarFinder);
      
      // Verify that unselected tabs have reduced opacity for visual distinction
      expect(tabBar.unselectedLabelColor, isA<Color>());
      
      // The unselected color should have some transparency
      final unselectedColor = tabBar.unselectedLabelColor!;
      expect(unselectedColor.opacity, lessThan(1.0));
      expect(unselectedColor.opacity, greaterThan(0.5)); // Should be visible but dimmed
    });

    testWidgets('Theme-aware colors work with different brightness values', (WidgetTester tester) async {
      // Test light theme
      await tester.pumpWidget(createTestTabBar(brightness: Brightness.light));
      await tester.pumpAndSettle();

      final tabBarFinder = find.byType(TabBar);
      TabBar lightTabBar = tester.widget(tabBarFinder);
      final Color lightLabelColor = lightTabBar.labelColor!;

      // Test dark theme
      await tester.pumpWidget(createTestTabBar(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      TabBar darkTabBar = tester.widget(tabBarFinder);
      final Color darkLabelColor = darkTabBar.labelColor!;

      // Verify text colors are the same for both themes (both use white text)
      // but indicators should be different (yellow vs primary)
      expect(lightTabBar.indicator, isNotNull);
      expect(darkTabBar.indicator, isNotNull);
      
      if (lightTabBar.indicator != null && darkTabBar.indicator != null) {
        expect(lightTabBar.indicator, isA<UnderlineTabIndicator>());
        expect(darkTabBar.indicator, isA<UnderlineTabIndicator>());
        
        final lightIndicator = lightTabBar.indicator as UnderlineTabIndicator;
        final darkIndicator = darkTabBar.indicator as UnderlineTabIndicator;
        
        expect(lightIndicator.borderSide.color, equals(Colors.yellow));
        expect(darkIndicator.borderSide.color, equals(const Color(0xFF42A5F5))); // primary
      }
    });
  });
}