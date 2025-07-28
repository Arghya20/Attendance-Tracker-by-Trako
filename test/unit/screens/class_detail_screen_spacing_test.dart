import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/screens/class_detail_screen.dart';
import 'package:attendance_tracker/widgets/bottom_action_bar.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/utils/responsive_layout.dart';

/// Test helper class to expose private methods for testing
class ClassDetailScreenTestHelper {
  /// Calculates bottom spacing using the same logic as ClassDetailScreen
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
  
  /// Gets responsive spacing adjustment based on screen size
  static double _getResponsiveSpacing(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return AppConstants.largePadding; // 24px
    } else if (ResponsiveLayout.isTablet(context)) {
      return AppConstants.defaultPadding; // 16px
    } else {
      return AppConstants.smallPadding; // 8px
    }
  }
  
  /// Gets minimum spacing based on screen size and constraints
  static double _getMinimumSpacing(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    
    // Base minimum from BottomActionBar
    double baseMinimum = BottomActionBar.getMinimumHeight() + AppConstants.smallPadding;
    
    if (ResponsiveLayout.isDesktop(context)) {
      return baseMinimum + AppConstants.largePadding; // +24px
    } else if (ResponsiveLayout.isTablet(context)) {
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
  group('ClassDetailScreen Spacing Calculation Tests', () {
    testWidgets('calculateBottomSpacing returns correct spacing for mobile device', (WidgetTester tester) async {
      // Create a mobile-sized MediaQuery
      const Size mobileSize = Size(400, 800);
      const EdgeInsets safeAreaInsets = EdgeInsets.only(bottom: 20);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: mobileSize,
              padding: safeAreaInsets,
            ),
            child: Builder(
              builder: (context) {
                final spacing = ClassDetailScreenTestHelper.calculateBottomSpacing(context);
                
                // Expected calculation:
                // BottomActionBar.getTotalHeight = buttonHeight (48) + actionBarPadding (16) + safeArea (20) = 84
                // Responsive spacing (mobile) = 8
                // Total = 84 + 8 = 92
                // Minimum (mobile, height 800) = baseMinimum (48+16+8=72) + 16 = 88
                // Result should be max(92, 88) = 92
                
                expect(spacing, equals(92.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('calculateBottomSpacing returns correct spacing for tablet device', (WidgetTester tester) async {
      // Create a tablet-sized MediaQuery
      const Size tabletSize = Size(800, 1024);
      const EdgeInsets safeAreaInsets = EdgeInsets.only(bottom: 15);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: tabletSize,
              padding: safeAreaInsets,
            ),
            child: Builder(
              builder: (context) {
                final spacing = ClassDetailScreenTestHelper.calculateBottomSpacing(context);
                
                // Expected calculation:
                // BottomActionBar.getTotalHeight = buttonHeight (48) + actionBarPadding (16) + safeArea (15) = 79
                // Responsive spacing (tablet) = 16
                // Total = 79 + 16 = 95
                // Minimum (tablet) = baseMinimum (48+16+8=72) + 16 = 88
                // Result should be max(95, 88) = 95
                
                expect(spacing, equals(95.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('calculateBottomSpacing returns correct spacing for desktop device', (WidgetTester tester) async {
      // Create a desktop-sized MediaQuery
      const Size desktopSize = Size(1200, 800);
      const EdgeInsets safeAreaInsets = EdgeInsets.only(bottom: 0);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: desktopSize,
              padding: safeAreaInsets,
            ),
            child: Builder(
              builder: (context) {
                final spacing = ClassDetailScreenTestHelper.calculateBottomSpacing(context);
                
                // Expected calculation:
                // BottomActionBar.getTotalHeight = buttonHeight (48) + actionBarPadding (16) + safeArea (0) = 64
                // Responsive spacing (desktop) = 24
                // Total = 64 + 24 = 88
                // Minimum (desktop) = baseMinimum (48+16+8=72) + 24 = 96
                // Result should be max(88, 96) = 96
                
                expect(spacing, equals(96.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('calculateBottomSpacing enforces minimum spacing for very small mobile screens', (WidgetTester tester) async {
      // Create a very small mobile screen
      const Size smallMobileSize = Size(320, 500);
      const EdgeInsets safeAreaInsets = EdgeInsets.only(bottom: 0);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: smallMobileSize,
              padding: safeAreaInsets,
            ),
            child: Builder(
              builder: (context) {
                final spacing = ClassDetailScreenTestHelper.calculateBottomSpacing(context);
                
                // Expected calculation:
                // BottomActionBar.getTotalHeight = buttonHeight (48) + actionBarPadding (16) + safeArea (0) = 64
                // Responsive spacing (mobile) = 8
                // Total = 64 + 8 = 72
                // Minimum (mobile, height < 600) = baseMinimum (48+16+8=72) = 72
                // Result should be max(72, 72) = 72
                
                expect(spacing, equals(72.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('calculateBottomSpacing handles large safe area insets correctly', (WidgetTester tester) async {
      // Create a mobile device with large safe area (like iPhone with home indicator)
      const Size mobileSize = Size(400, 800);
      const EdgeInsets largeSafeAreaInsets = EdgeInsets.only(bottom: 40);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: mobileSize,
              padding: largeSafeAreaInsets,
            ),
            child: Builder(
              builder: (context) {
                final spacing = ClassDetailScreenTestHelper.calculateBottomSpacing(context);
                
                // Expected calculation:
                // BottomActionBar.getTotalHeight = buttonHeight (48) + actionBarPadding (16) + safeArea (40) = 104
                // Responsive spacing (mobile) = 8
                // Total = 104 + 8 = 112
                // Minimum (mobile, height 800) = baseMinimum (48+16+8=72) + 16 = 88
                // Result should be max(112, 88) = 112
                
                expect(spacing, equals(112.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('calculateBottomSpacing handles zero safe area correctly', (WidgetTester tester) async {
      // Create a device with no safe area insets
      const Size mobileSize = Size(400, 700);
      const EdgeInsets noSafeAreaInsets = EdgeInsets.zero;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: mobileSize,
              padding: noSafeAreaInsets,
            ),
            child: Builder(
              builder: (context) {
                final spacing = ClassDetailScreenTestHelper.calculateBottomSpacing(context);
                
                // Expected calculation:
                // BottomActionBar.getTotalHeight = buttonHeight (48) + actionBarPadding (16) + safeArea (0) = 64
                // Responsive spacing (mobile) = 8
                // Total = 64 + 8 = 72
                // Minimum (mobile, height 700) = baseMinimum (48+16+8=72) + 8 = 80
                // Result should be max(72, 80) = 80
                
                expect(spacing, equals(80.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('calculateBottomSpacing adapts to different mobile screen heights', (WidgetTester tester) async {
      // Test different mobile screen heights
      final List<Map<String, dynamic>> testCases = [
        {
          'height': 500.0,
          'expectedMinimum': 72.0, // baseMinimum (48+16+8=72) only
          'description': 'very small screen (< 600px)',
        },
        {
          'height': 700.0,
          'expectedMinimum': 80.0, // baseMinimum (72) + 8
          'description': 'small screen (600-800px)',
        },
        {
          'height': 900.0,
          'expectedMinimum': 88.0, // baseMinimum (72) + 16
          'description': 'large mobile screen (> 800px)',
        },
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(400, testCase['height']),
                padding: EdgeInsets.zero,
              ),
              child: Builder(
                builder: (context) {
                  final spacing = ClassDetailScreenTestHelper.calculateBottomSpacing(context);
                  
                  // All should have total spacing of 72 (64 + 8)
                  // But minimum varies based on height
                  final expectedSpacing = 72.0 > testCase['expectedMinimum'] 
                      ? 72.0 
                      : testCase['expectedMinimum'] as double;
                  
                  expect(
                    spacing, 
                    equals(expectedSpacing),
                    reason: 'Failed for ${testCase['description']}',
                  );
                  return Container();
                },
              ),
            ),
          ),
        );
      }
    });
  });

  group('BottomActionBar Height Calculation Tests', () {
    testWidgets('getTotalHeight includes safe area correctly', (WidgetTester tester) async {
      const Size screenSize = Size(400, 800);
      const EdgeInsets safeAreaInsets = EdgeInsets.only(bottom: 25);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: screenSize,
              padding: safeAreaInsets,
            ),
            child: Builder(
              builder: (context) {
                final totalHeight = BottomActionBar.getTotalHeight(context);
                
                // Expected: buttonHeight (48) + actionBarPadding (16) + safeArea (25) = 89
                expect(totalHeight, equals(89.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getMinimumHeight excludes safe area', (WidgetTester tester) async {
      final minimumHeight = BottomActionBar.getMinimumHeight();
      
      // Expected: buttonHeight (48) + actionBarPadding (16) = 64
      expect(minimumHeight, equals(64.0));
    });
  });
}