import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRoute<T> {
  final Widget page;
  final Duration duration;
  
  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(settings: settings, fullscreenDialog: false);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: page,
    );
  }
}

class SlidePageRoute<T> extends PageRoute<T> {
  final Widget page;
  final Duration duration;
  final SlideDirection direction;
  
  SlidePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.direction = SlideDirection.right,
    RouteSettings? settings,
  }) : super(settings: settings, fullscreenDialog: false);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    var begin = _getBeginOffset();
    const end = Offset.zero;
    
    var curve = Curves.easeInOut;
    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);
    
    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation,
        child: page,
      ),
    );
  }
  
  Offset _getBeginOffset() {
    switch (direction) {
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.top:
        return const Offset(0.0, -1.0);
      case SlideDirection.bottom:
        return const Offset(0.0, 1.0);
    }
  }
}

enum SlideDirection {
  right,
  left,
  top,
  bottom,
}

class ScalePageRoute<T> extends PageRoute<T> {
  final Widget page;
  final Duration duration;
  final Alignment alignment;
  
  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
    RouteSettings? settings,
  }) : super(settings: settings, fullscreenDialog: false);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      alignment: alignment,
      child: FadeTransition(
        opacity: animation,
        child: page,
      ),
    );
  }
}