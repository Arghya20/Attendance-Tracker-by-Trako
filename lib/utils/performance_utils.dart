import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A utility class for performance optimization
class PerformanceUtils {
  /// Enables performance overlay in debug mode
  static void enablePerformanceOverlay() {
    if (kDebugMode) {
      debugPrintBuildScope = true;
      debugPrintScheduleBuildForStacks = true;
      // Note: Performance overlay must be enabled in the MaterialApp widget
    }
  }
  
  /// Disables performance overlay in debug mode
  static void disablePerformanceOverlay() {
    if (kDebugMode) {
      debugPrintBuildScope = false;
      debugPrintScheduleBuildForStacks = false;
      // Note: Performance overlay must be disabled in the MaterialApp widget
    }
  }
  
  /// Checks if the app is running in debug mode
  static bool get isDebugMode => kDebugMode;
  
  /// Checks if the app is running in profile mode
  static bool get isProfileMode => kProfileMode;
  
  /// Checks if the app is running in release mode
  static bool get isReleaseMode => kReleaseMode;
  
  /// Logs a performance event
  static void logPerformance(String tag, Function() function) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      function();
      stopwatch.stop();
      debugPrint('$tag: ${stopwatch.elapsedMilliseconds}ms');
    } else {
      function();
    }
  }
}

/// A widget that measures the build time of its child
class PerformanceMeasureWidget extends StatelessWidget {
  final Widget child;
  final String tag;
  
  const PerformanceMeasureWidget({
    super.key,
    required this.child,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      final result = child;
      stopwatch.stop();
      debugPrint('Build $tag: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } else {
      return child;
    }
  }
}

/// A widget that caches its child to avoid rebuilding
class CachedWidget extends StatefulWidget {
  final Widget child;
  final Object? cacheKey;
  
  const CachedWidget({
    super.key,
    required this.child,
    this.cacheKey,
  });

  @override
  State<CachedWidget> createState() => _CachedWidgetState();
}

class _CachedWidgetState extends State<CachedWidget> {
  late Widget _cachedChild;
  Object? _cacheKey;
  
  @override
  void initState() {
    super.initState();
    _cachedChild = widget.child;
    _cacheKey = widget.cacheKey;
  }
  
  @override
  void didUpdateWidget(CachedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cacheKey != _cacheKey) {
      _cachedChild = widget.child;
      _cacheKey = widget.cacheKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _cachedChild;
  }
}