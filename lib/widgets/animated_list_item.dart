import 'package:flutter/material.dart';

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;
  
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.animationType = AnimationType.slide,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case AnimationType.fade:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case AnimationType.scale:
        return ScaleTransition(
          scale: _animation,
          child: widget.child,
        );
      case AnimationType.slide:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _animation.value)),
              child: Opacity(
                opacity: _animation.value,
                child: child,
              ),
            );
          },
          child: widget.child,
        );
      case AnimationType.slideHorizontal:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - _animation.value), 0),
              child: Opacity(
                opacity: _animation.value,
                child: child,
              ),
            );
          },
          child: widget.child,
        );
    }
  }
}

enum AnimationType {
  fade,
  scale,
  slide,
  slideHorizontal,
}