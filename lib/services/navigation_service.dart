import 'package:flutter/material.dart';
import 'package:attendance_tracker/utils/page_transitions.dart';

class NavigationService {
  static Future<T?> navigateTo<T>(
    BuildContext context,
    Widget page, {
    TransitionType transitionType = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    SlideDirection slideDirection = SlideDirection.right,
    Alignment scaleAlignment = Alignment.center,
  }) {
    switch (transitionType) {
      case TransitionType.fade:
        return Navigator.push<T>(
          context,
          FadePageRoute<T>(
            page: page,
            duration: duration,
          ),
        );
      case TransitionType.slide:
        return Navigator.push<T>(
          context,
          SlidePageRoute<T>(
            page: page,
            duration: duration,
            direction: slideDirection,
          ),
        );
      case TransitionType.scale:
        return Navigator.push<T>(
          context,
          ScalePageRoute<T>(
            page: page,
            duration: duration,
            alignment: scaleAlignment,
          ),
        );
      case TransitionType.material:
      default:
        return Navigator.push<T>(
          context,
          MaterialPageRoute<T>(
            builder: (context) => page,
          ),
        );
    }
  }
  
  static Future<T?> navigateToReplacement<T>(
    BuildContext context,
    Widget page, {
    TransitionType transitionType = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    SlideDirection slideDirection = SlideDirection.right,
    Alignment scaleAlignment = Alignment.center,
  }) {
    switch (transitionType) {
      case TransitionType.fade:
        return Navigator.pushReplacement<T, dynamic>(
          context,
          FadePageRoute<T>(
            page: page,
            duration: duration,
          ),
        );
      case TransitionType.slide:
        return Navigator.pushReplacement<T, dynamic>(
          context,
          SlidePageRoute<T>(
            page: page,
            duration: duration,
            direction: slideDirection,
          ),
        );
      case TransitionType.scale:
        return Navigator.pushReplacement<T, dynamic>(
          context,
          ScalePageRoute<T>(
            page: page,
            duration: duration,
            alignment: scaleAlignment,
          ),
        );
      case TransitionType.material:
      default:
        return Navigator.pushReplacement<T, dynamic>(
          context,
          MaterialPageRoute<T>(
            builder: (context) => page,
          ),
        );
    }
  }
}

enum TransitionType {
  fade,
  slide,
  scale,
  material,
}