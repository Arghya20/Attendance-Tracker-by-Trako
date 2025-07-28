import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/utils/responsive_layout.dart';
import 'package:neopop/neopop.dart';

class BottomActionBar extends StatelessWidget {
  /// Height of the action buttons within the bottom action bar
  static const double buttonHeight = 48.0;
  
  /// Total padding applied to the action bar (top + bottom, excluding safe area)
  static const double actionBarPadding = AppConstants.smallPadding * 2; // 8 * 2 = 16
  
  /// Calculates the total height of the bottom action bar including safe area
  static double getTotalHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    
    if (isKeyboardVisible) {
      // When keyboard is visible, use reduced padding
      final double keyboardModePadding = ResponsiveLayout.isDesktop(context) 
          ? AppConstants.smallPadding 
          : AppConstants.smallPadding / 2;
      return buttonHeight + keyboardModePadding * 2 + mediaQuery.padding.bottom;
    } else {
      // Normal height calculation
      return buttonHeight + actionBarPadding + mediaQuery.padding.bottom;
    }
  }
  
  /// Calculates the minimum height of the bottom action bar (without safe area)
  static double getMinimumHeight() {
    return buttonHeight + actionBarPadding;
  }
  
  /// Gets responsive horizontal padding for static calculations
  static double getResponsiveHorizontalPadding(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return AppConstants.largePadding * 2; // 48px
    } else if (ResponsiveLayout.isTablet(context)) {
      return AppConstants.largePadding; // 24px
    } else {
      return AppConstants.defaultPadding; // 16px
    }
  }
  
  /// Checks if the keyboard is currently visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
  
  /// Gets the current keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  final VoidCallback onAddStudent;
  final VoidCallback? onTakeAttendance;
  final bool canTakeAttendance;
  final bool isLoading;
  
  const BottomActionBar({
    super.key,
    required this.onAddStudent,
    this.onTakeAttendance,
    this.canTakeAttendance = true,
    this.isLoading = false,
  });

  /// Gets responsive horizontal padding for the action bar
  double _getResponsiveHorizontalPadding(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      // Desktop: More generous padding to match content area
      return AppConstants.largePadding * 2; // 48px
    } else if (ResponsiveLayout.isTablet(context)) {
      // Tablet: Increased padding for better visual balance
      return AppConstants.largePadding; // 24px
    } else {
      // Mobile: Standard padding
      return AppConstants.defaultPadding; // 16px
    }
  }
  
  /// Gets responsive spacing between action buttons
  double _getResponsiveButtonSpacing(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      // Desktop: More generous spacing between buttons
      return AppConstants.largePadding; // 24px
    } else if (ResponsiveLayout.isTablet(context)) {
      // Tablet: Slightly increased spacing
      return AppConstants.defaultPadding + AppConstants.smallPadding; // 24px
    } else {
      // Mobile: Standard spacing
      return AppConstants.defaultPadding; // 16px
    }
  }
  
  /// Gets keyboard-aware bottom padding for the action bar
  double _getKeyboardAwareBottomPadding(BuildContext context, bool isKeyboardVisible) {
    final mediaQuery = MediaQuery.of(context);
    
    if (isKeyboardVisible) {
      // When keyboard is visible, use minimal padding since keyboard handles spacing
      // and we want to maximize content area
      if (ResponsiveLayout.isDesktop(context)) {
        // Desktop: Standard padding even with keyboard
        return AppConstants.smallPadding + mediaQuery.padding.bottom;
      } else {
        // Mobile/Tablet: Minimal padding with keyboard
        return AppConstants.smallPadding / 2 + mediaQuery.padding.bottom; // 4px + safe area
      }
    } else {
      // Normal padding when keyboard is not visible
      return AppConstants.smallPadding + mediaQuery.padding.bottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Check if keyboard is visible and adjust padding accordingly
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final double bottomPadding = _getKeyboardAwareBottomPadding(context, isKeyboardVisible);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: _getResponsiveHorizontalPadding(context),
        right: _getResponsiveHorizontalPadding(context),
        top: AppConstants.smallPadding,
        bottom: bottomPadding,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Add Student',
                icon: Icons.person_add,
                onPressed: isLoading ? null : onAddStudent,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                isLoading: false,
              ),
            ),
            SizedBox(width: _getResponsiveButtonSpacing(context)),
            Expanded(
              child: _ActionButton(
                label: 'Take Attendance',
                icon: Icons.how_to_reg,
                onPressed: canTakeAttendance && !isLoading ? onTakeAttendance : null,
                backgroundColor: canTakeAttendance 
                    ? theme.colorScheme.secondary 
                    : theme.colorScheme.surfaceVariant,
                foregroundColor: canTakeAttendance 
                    ? theme.colorScheme.onSecondary 
                    : theme.colorScheme.onSurfaceVariant,
                isLoading: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  
  const _ActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BottomActionBar.buttonHeight,
      child: NeoPopButton(
        color: backgroundColor,
        onTapUp: onPressed != null && !isLoading 
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: foregroundColor,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}