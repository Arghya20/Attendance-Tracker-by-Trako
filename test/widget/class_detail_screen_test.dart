import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/bottom_action_bar.dart';
import 'package:attendance_tracker/constants/app_constants.dart';

/// Test helper to create a ListView with specific padding for testing
class TestListView extends StatelessWidget {
  final double bottomPadding;
  final List<Widget> children;
  
  const TestListView({
    super.key,
    required this.bottomPadding,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        left: AppConstants.defaultPadding,
        right: AppConstants.defaultPadding,
        top: AppConstants.defaultPadding,
        bottom: bottomPadding,
      ),
      children: children,
    );
  }
}

/// Test helper to calculate bottom spacing using the same logic as ClassDetailScreen
class SpacingTestHelper {
  static double calculateBottomSpacing(BuildContext context) {
    // Use BottomActionBar's total height calculation as base
    double totalSpacing = BottomActionBar.getTotalHeight(context);
    
    // Add responsive spacing adjustments based on screen size
    double responsiveSpacing = _getResponsiveSpacing(context);
    totalSpacing += responsiveSpacing;
    
    // Enforce minimum spacing for edge cases
    final double minimumSpacing = _getMinimumSpacing(context);
    
    return totalSpacing < minimumSpacing ? minimumSpacing : totalSpacing;
  }
  
  static double _getResponsiveSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1100) {
      return AppConstants.largePadding; // 24px
    } else if (screenWidth >= 650) {
      return AppConstants.defaultPadding; // 16px
    } else {
      return AppConstants.smallPadding; // 8px
    }
  }
  
  static double _getMinimumSpacing(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    
    // Base minimum from BottomActionBar
    double baseMinimum = BottomActionBar.getMinimumHeight() + AppConstants.smallPadding;
    
    if (screenWidth >= 1100) {
      return baseMinimum + AppConstants.largePadding; // +24px
    } else if (screenWidth >= 650) {
      return baseMinimum + AppConstants.defaultPadding; // +16px
    } else {
      // Mobile: Adaptive minimum based on screen height
      if (screenHeight < 600) {
        return baseMinimum;
      } else if (screenHeight < 800) {
        return baseMinimum + AppConstants.smallPadding; // +8px
      } else {
        return baseMinimum + AppConstants.defaultPadding; // +16px
      }
    }
  }
}

void main() {
  group('ListView Padding and Scroll Behavior Tests', () {
    Widget createTestWidget({
      Size screenSize = const Size(400, 800),
      EdgeInsets safeArea = const EdgeInsets.only(bottom: 20),
      required List<Widget> children,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            padding: safeArea,
          ),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final bottomPadding = SpacingTestHelper.calculateBottomSpacing(context);
                return Stack(
                  children: [
                    TestListView(
                      bottomPadding: bottomPadding,
                      children: children,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BottomActionBar(
                        onAddStudent: () {},
                        onTakeAttendance: () {},
                        canTakeAttendance: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('ListView receives correct bottom padding for mobile device', (WidgetTester tester) async {
      // Create test content
      final children = List.generate(5, (index) => ListTile(
        title: Text('Student ${index + 1}'),
      ));

      await tester.pumpWidget(createTestWidget(children: children));
      await tester.pumpAndSettle();

      // Find the ListView
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final ListView listView = tester.widget(listViewFinder);
      
      // Expected bottom padding calculation for mobile (400x800) with 20px safe area:
      // BottomActionBar.getTotalHeight = 48 + 16 + 20 = 84
      // Responsive spacing (mobile) = 8
      // Total = 84 + 8 = 92
      // Minimum (mobile, height 800) = 72 + 16 = 88
      // Result should be max(92, 88) = 92
      
      final EdgeInsets padding = listView.padding as EdgeInsets;
      expect(padding.bottom, equals(92.0));
    });

    testWidgets('ListView receives correct bottom padding for tablet device', (WidgetTester tester) async {
      // Create test content
      final children = List.generate(3, (index) => ListTile(
        title: Text('Student ${index + 1}'),
      ));

      await tester.pumpWidget(createTestWidget(
        screenSize: const Size(800, 1024),
        safeArea: const EdgeInsets.only(bottom: 15),
        children: children,
      ));
      await tester.pumpAndSettle();

      final ListView listView = tester.widget(find.byType(ListView));
      
      // Expected bottom padding calculation for tablet (800x1024) with 15px safe area:
      // BottomActionBar.getTotalHeight = 48 + 16 + 15 = 79
      // Responsive spacing (tablet) = 16
      // Total = 79 + 16 = 95
      // Minimum (tablet) = 72 + 16 = 88
      // Result should be max(95, 88) = 95
      
      final EdgeInsets padding = listView.padding as EdgeInsets;
      expect(padding.bottom, equals(95.0));
    });

    testWidgets('ListView receives correct bottom padding for desktop device', (WidgetTester tester) async {
      // Create test content
      final children = List.generate(2, (index) => ListTile(
        title: Text('Student ${index + 1}'),
      ));

      await tester.pumpWidget(createTestWidget(
        screenSize: const Size(1200, 800),
        safeArea: EdgeInsets.zero,
        children: children,
      ));
      await tester.pumpAndSettle();

      final ListView listView = tester.widget(find.byType(ListView));
      
      // Expected bottom padding calculation for desktop (1200x800) with 0px safe area:
      // BottomActionBar.getTotalHeight = 48 + 16 + 0 = 64
      // Responsive spacing (desktop) = 24
      // Total = 64 + 24 = 88
      // Minimum (desktop) = 72 + 24 = 96
      // Result should be max(88, 96) = 96
      
      final EdgeInsets padding = listView.padding as EdgeInsets;
      expect(padding.bottom, equals(96.0));
    });

    testWidgets('last list item is fully visible and tappable', (WidgetTester tester) async {
      // Create enough content to require scrolling
      final children = List.generate(20, (index) => ListTile(
        title: Text('Student ${index + 1}'),
        onTap: () {},
      ));

      await tester.pumpWidget(createTestWidget(children: children));
      await tester.pumpAndSettle();

      // Scroll to the bottom to find the last item
      await tester.scrollUntilVisible(
        find.text('Student 20'),
        500.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      // Verify the last item is visible
      final lastItemFinder = find.text('Student 20');
      expect(lastItemFinder, findsOneWidget);

      // Get the position of the last item
      final RenderBox lastItemBox = tester.renderObject(lastItemFinder);
      final Offset lastItemPosition = lastItemBox.localToGlobal(Offset.zero);
      final Size lastItemSize = lastItemBox.size;

      // Get the position of the bottom action bar
      final bottomActionBarFinder = find.byType(BottomActionBar);
      expect(bottomActionBarFinder, findsOneWidget);
      
      final RenderBox actionBarBox = tester.renderObject(bottomActionBarFinder);
      final Offset actionBarPosition = actionBarBox.localToGlobal(Offset.zero);

      // Verify that the last item doesn't overlap with the action bar
      final double lastItemBottom = lastItemPosition.dy + lastItemSize.height;
      final double actionBarTop = actionBarPosition.dy;
      
      expect(lastItemBottom, lessThanOrEqualTo(actionBarTop),
        reason: 'Last list item should not overlap with bottom action bar');

      // Verify the last item is tappable
      await tester.tap(find.byType(ListTile).last);
      await tester.pumpAndSettle();
      
      // The tap should work without throwing an exception
    });

    testWidgets('scroll behavior works correctly with new spacing', (WidgetTester tester) async {
      // Create enough content to require scrolling
      final children = List.generate(15, (index) => ListTile(
        title: Text('Student ${index + 1}'),
      ));

      await tester.pumpWidget(createTestWidget(children: children));
      await tester.pumpAndSettle();

      // Find the scrollable ListView
      final scrollableFinder = find.byType(Scrollable);
      expect(scrollableFinder, findsOneWidget);

      // Get initial scroll position
      final ScrollableState scrollableState = tester.state(scrollableFinder);
      final ScrollController? scrollController = scrollableState.widget.controller;
      final double initialPosition = scrollController?.position.pixels ?? 0;

      // Scroll down
      await tester.drag(scrollableFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify scroll position changed
      final double afterScrollPosition = scrollController?.position.pixels ?? 0;
      expect(afterScrollPosition, greaterThan(initialPosition));

      // Scroll to the very bottom
      await tester.scrollUntilVisible(
        find.text('Student 15'),
        500.0,
        scrollable: scrollableFinder,
      );
      await tester.pumpAndSettle();

      // Verify we can scroll to the maximum extent
      if (scrollController != null) {
        final double maxScrollExtent = scrollController.position.maxScrollExtent;
        final double currentPosition = scrollController.position.pixels;
        
        // Should be able to scroll close to the maximum extent
        expect(currentPosition, greaterThan(maxScrollExtent * 0.8),
          reason: 'Should be able to scroll close to the bottom');
      }

      // Verify the last item is still accessible
      expect(find.text('Student 15'), findsOneWidget);
    });

    testWidgets('spacing calculation helper works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 20),
            ),
            child: Builder(
              builder: (context) {
                final spacing = SpacingTestHelper.calculateBottomSpacing(context);
                expect(spacing, equals(92.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('BottomActionBar height calculation is consistent', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 25),
            ),
            child: Builder(
              builder: (context) {
                final totalHeight = BottomActionBar.getTotalHeight(context);
                expect(totalHeight, equals(89.0)); // 48 + 16 + 25
                
                final minimumHeight = BottomActionBar.getMinimumHeight();
                expect(minimumHeight, equals(64.0)); // 48 + 16
                
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });
}