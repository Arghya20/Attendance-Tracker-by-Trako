import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/widgets/bottom_action_bar.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/utils/responsive_layout.dart';

/// Test helper class to expose keyboard-aware spacing logic
class KeyboardSpacingTestHelper {
  /// Calculates bottom spacing with keyboard awareness
  static double calculateBottomSpacing(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // Check if keyboard is visible
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final double keyboardHeight = mediaQuery.viewInsets.bottom;
    
    if (isKeyboardVisible) {
      // When keyboard is visible, adjust spacing to account for it
      return _calculateKeyboardAwareSpacing(context, keyboardHeight);
    } else {
      // Normal spacing calculation when keyboard is not visible
      return _calculateNormalSpacing(context);
    }
  }
  
  /// Calculates spacing when keyboard is visible
  static double _calculateKeyboardAwareSpacing(BuildContext context, double keyboardHeight) {
    // Base action bar height without safe area (since keyboard handles that)
    double baseSpacing = BottomActionBar.getMinimumHeight();
    
    // Add minimal responsive spacing for keyboard mode
    double keyboardModeSpacing = _getKeyboardModeSpacing(context);
    baseSpacing += keyboardModeSpacing;
    
    // Ensure minimum spacing even with keyboard
    final double minimumKeyboardSpacing = _getMinimumKeyboardSpacing(context);
    
    return baseSpacing < minimumKeyboardSpacing ? minimumKeyboardSpacing : baseSpacing;
  }
  
  /// Calculates normal spacing when keyboard is not visible
  static double _calculateNormalSpacing(BuildContext context) {
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
    if (ResponsiveLayout.isDesktop(context)) {
      return AppConstants.largePadding; // 24px
    } else if (ResponsiveLayout.isTablet(context)) {
      return AppConstants.defaultPadding; // 16px
    } else {
      return AppConstants.smallPadding; // 8px
    }
  }
  
  static double _getKeyboardModeSpacing(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return AppConstants.defaultPadding; // 16px
    } else if (ResponsiveLayout.isTablet(context)) {
      return AppConstants.smallPadding; // 8px
    } else {
      return AppConstants.smallPadding / 2; // 4px
    }
  }
  
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
  
  static double _getMinimumKeyboardSpacing(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;
    
    // Base minimum from BottomActionBar without safe area
    double baseMinimum = BottomActionBar.getMinimumHeight();
    
    if (ResponsiveLayout.isDesktop(context)) {
      return baseMinimum + AppConstants.smallPadding; // +8px
    } else if (ResponsiveLayout.isTablet(context)) {
      return baseMinimum + AppConstants.smallPadding / 2; // +4px
    } else {
      // Mobile: Adaptive minimum based on available height with keyboard
      if (availableHeight < 400) {
        return baseMinimum;
      } else if (availableHeight < 600) {
        return baseMinimum + AppConstants.smallPadding / 2; // +4px
      } else {
        return baseMinimum + AppConstants.smallPadding; // +8px
      }
    }
  }
}

void main() {
  group('Keyboard-Aware Spacing Tests', () {
    testWidgets('spacing adjusts correctly when keyboard appears on mobile', (WidgetTester tester) async {
      // Test mobile device without keyboard
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 20),
              viewInsets: EdgeInsets.zero, // No keyboard
            ),
            child: Builder(
              builder: (context) {
                final spacing = KeyboardSpacingTestHelper.calculateBottomSpacing(context);
                
                // Normal spacing calculation: 84 + 8 = 92, min = 88, result = 92
                expect(spacing, equals(92.0));
                return Container();
              },
            ),
          ),
        ),
      );

      // Test same device with keyboard visible
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 20),
              viewInsets: EdgeInsets.only(bottom: 300), // Keyboard visible
            ),
            child: Builder(
              builder: (context) {
                final spacing = KeyboardSpacingTestHelper.calculateBottomSpacing(context);
                
                // Keyboard mode: baseMinimum (64) + keyboardModeSpacing (4) = 68
                // Available height: 800 - 300 = 500, so minimum = 64 + 4 = 68
                // Result should be max(68, 68) = 68
                expect(spacing, equals(68.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('spacing adjusts correctly when keyboard appears on tablet', (WidgetTester tester) async {
      // Test tablet device without keyboard
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1024),
              padding: EdgeInsets.only(bottom: 15),
              viewInsets: EdgeInsets.zero, // No keyboard
            ),
            child: Builder(
              builder: (context) {
                final spacing = KeyboardSpacingTestHelper.calculateBottomSpacing(context);
                
                // Normal spacing: 79 + 16 = 95, min = 88, result = 95
                expect(spacing, equals(95.0));
                return Container();
              },
            ),
          ),
        ),
      );

      // Test same device with keyboard visible
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1024),
              padding: EdgeInsets.only(bottom: 15),
              viewInsets: EdgeInsets.only(bottom: 350), // Keyboard visible
            ),
            child: Builder(
              builder: (context) {
                final spacing = KeyboardSpacingTestHelper.calculateBottomSpacing(context);
                
                // Keyboard mode: baseMinimum (64) + keyboardModeSpacing (8) = 72
                // Available height: 1024 - 350 = 674, so minimum = 64 + 4 = 68
                // Result should be max(72, 68) = 72
                expect(spacing, equals(72.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('spacing adjusts correctly when keyboard appears on desktop', (WidgetTester tester) async {
      // Test desktop device without keyboard
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1200, 800),
              padding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero, // No keyboard
            ),
            child: Builder(
              builder: (context) {
                final spacing = KeyboardSpacingTestHelper.calculateBottomSpacing(context);
                
                // Normal spacing: 64 + 24 = 88, min = 96, result = 96
                expect(spacing, equals(96.0));
                return Container();
              },
            ),
          ),
        ),
      );

      // Test same device with keyboard visible
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1200, 800),
              padding: EdgeInsets.zero,
              viewInsets: EdgeInsets.only(bottom: 200), // Keyboard visible
            ),
            child: Builder(
              builder: (context) {
                final spacing = KeyboardSpacingTestHelper.calculateBottomSpacing(context);
                
                // Keyboard mode: baseMinimum (64) + keyboardModeSpacing (16) = 80
                // Minimum = 64 + 8 = 72
                // Result should be max(80, 72) = 80
                expect(spacing, equals(80.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('BottomActionBar height adjusts for keyboard visibility', (WidgetTester tester) async {
      // Test without keyboard
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 20),
              viewInsets: EdgeInsets.zero,
            ),
            child: Builder(
              builder: (context) {
                final height = BottomActionBar.getTotalHeight(context);
                expect(height, equals(84.0)); // 48 + 16 + 20
                
                final isKeyboardVisible = BottomActionBar.isKeyboardVisible(context);
                expect(isKeyboardVisible, isFalse);
                
                final keyboardHeight = BottomActionBar.getKeyboardHeight(context);
                expect(keyboardHeight, equals(0.0));
                
                return Container();
              },
            ),
          ),
        ),
      );

      // Test with keyboard
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 20),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: Builder(
              builder: (context) {
                final height = BottomActionBar.getTotalHeight(context);
                expect(height, equals(76.0)); // 48 + (4 * 2) + 20 (keyboard mode)
                
                final isKeyboardVisible = BottomActionBar.isKeyboardVisible(context);
                expect(isKeyboardVisible, isTrue);
                
                final keyboardHeight = BottomActionBar.getKeyboardHeight(context);
                expect(keyboardHeight, equals(300.0));
                
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('keyboard spacing handles very constrained space correctly', (WidgetTester tester) async {
      // Test mobile device with large keyboard (very constrained space)
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 600), // Smaller screen
              padding: EdgeInsets.only(bottom: 10),
              viewInsets: EdgeInsets.only(bottom: 350), // Large keyboard
            ),
            child: Builder(
              builder: (context) {
                final spacing = KeyboardSpacingTestHelper.calculateBottomSpacing(context);
                
                // Available height: 600 - 350 = 250 (< 400)
                // Minimum should be baseMinimum (64) only
                // Keyboard mode: 64 + 4 = 68, min = 64, result = 68
                expect(spacing, equals(68.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });
}