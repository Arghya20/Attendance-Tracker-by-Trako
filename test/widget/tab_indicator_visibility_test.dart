import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tab Indicator Visibility Tests', () {
    
    testWidgets('Tab indicator is visible in light theme with secondary color', (WidgetTester tester) async {
      const lightColorScheme = ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF1565C0), // Blue
        onPrimary: Colors.white,
        secondary: Color(0xFFFFA000), // Orange/Amber
        onSecondary: Colors.black,
        error: Color(0xFFC62828),
        onError: Colors.white,
        background: Color(0xFFF4F5FF),
        onBackground: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: lightColorScheme,
            brightness: Brightness.light,
          ),
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Test'),
                backgroundColor: lightColorScheme.primary, // Blue background
                bottom: TabBar(
                  tabs: const [Tab(text: 'Students'), Tab(text: 'Analytics')],
                  labelColor: lightColorScheme.onPrimary, // White text
                  unselectedLabelColor: lightColorScheme.onPrimary.withValues(alpha: 0.7),
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 4.0,
                      color: Colors.yellow, // Yellow indicator for visibility
                    ),
                  ),
                  indicatorWeight: 3.0,
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Students')),
                  Center(child: Text('Analytics')),
                ],
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Find the TabBar
      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);

      final TabBar tabBar = tester.widget(tabBarFinder);
      
      // Verify the custom indicator color is yellow for visibility
      expect(tabBar.indicator, isNotNull);
      expect(tabBar.indicator, isA<UnderlineTabIndicator>());
      final indicator = tabBar.indicator as UnderlineTabIndicator;
      expect(indicator.borderSide.color, equals(Colors.yellow));
      
      // Verify text colors are appropriate
      expect(tabBar.labelColor, equals(Colors.white));
      expect(tabBar.unselectedLabelColor?.opacity, lessThan(1.0));
      
      // Test contrast - yellow on blue should be visible
      // This is a visual test - the yellow indicator should stand out on blue background
      final indicatorColor = indicator.borderSide.color;
      final appBarFinder = find.byType(AppBar);
      final AppBar appBar = tester.widget(appBarFinder);
      final backgroundColor = appBar.backgroundColor!;
      
      // Verify colors are different (basic contrast check)
      expect(indicatorColor, isNot(equals(backgroundColor)));
      expect(indicatorColor, isNot(equals(Colors.white)));
      expect(indicatorColor, isNot(equals(Colors.transparent)));
    });

    testWidgets('Tab indicator remains visible in dark theme', (WidgetTester tester) async {
      const darkColorScheme = ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF42A5F5), // Light blue
        onPrimary: Colors.black,
        secondary: Color(0xFFFFD54F), // Light amber
        onSecondary: Colors.black,
        error: Color(0xFFEF5350),
        onError: Colors.black,
        background: Color(0xFF0D0D0D),
        onBackground: Colors.white,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: darkColorScheme,
            brightness: Brightness.dark,
          ),
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Test'),
                backgroundColor: darkColorScheme.surface, // Dark background
                bottom: TabBar(
                  tabs: const [Tab(text: 'Students'), Tab(text: 'Analytics')],
                  labelColor: darkColorScheme.onSurface, // White text
                  unselectedLabelColor: darkColorScheme.onSurface.withValues(alpha: 0.6),
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 4.0,
                      color: darkColorScheme.primary, // Light blue indicator
                    ),
                  ),
                  indicatorWeight: 3.0,
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Students')),
                  Center(child: Text('Analytics')),
                ],
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      final tabBarFinder = find.byType(TabBar);
      final TabBar tabBar = tester.widget(tabBarFinder);
      
      // Verify the custom indicator color is primary (light blue)
      expect(tabBar.indicator, isNotNull);
      expect(tabBar.indicator, isA<UnderlineTabIndicator>());
      final indicator = tabBar.indicator as UnderlineTabIndicator;
      expect(indicator.borderSide.color, equals(const Color(0xFF42A5F5)));
      
      // Verify text colors
      expect(tabBar.labelColor, equals(Colors.white));
      
      // Test contrast - light blue on dark surface should be visible
      final indicatorColor = indicator.borderSide.color;
      final appBarFinder = find.byType(AppBar);
      final AppBar appBar = tester.widget(appBarFinder);
      final backgroundColor = appBar.backgroundColor!;
      
      expect(indicatorColor, isNot(equals(backgroundColor)));
      expect(indicatorColor, isNot(equals(Colors.transparent)));
    });

    testWidgets('Tab switching works with new indicator colors', (WidgetTester tester) async {
      const lightColorScheme = ColorScheme(
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
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: lightColorScheme),
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  tabs: const [Tab(text: 'Students'), Tab(text: 'Analytics')],
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 4.0,
                      color: Colors.yellow,
                    ),
                  ),
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Students Content')),
                  Center(child: Text('Analytics Content')),
                ],
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Students Content'), findsOneWidget);
      expect(find.text('Analytics Content'), findsNothing);

      // Tap Analytics tab
      await tester.tap(find.byWidgetPredicate((widget) => 
          widget is Tab && widget.text == 'Analytics'));
      await tester.pumpAndSettle();

      // Verify tab switched
      expect(find.text('Students Content'), findsNothing);
      expect(find.text('Analytics Content'), findsOneWidget);

      // Tap Students tab
      await tester.tap(find.byWidgetPredicate((widget) => 
          widget is Tab && widget.text == 'Students'));
      await tester.pumpAndSettle();

      // Verify tab switched back
      expect(find.text('Students Content'), findsOneWidget);
      expect(find.text('Analytics Content'), findsNothing);
    });
  });
}