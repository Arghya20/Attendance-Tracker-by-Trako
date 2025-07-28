import 'package:flutter/material.dart';

class PinIndicator extends StatefulWidget {
  final bool isPinned;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final Duration animationDuration;
  
  const PinIndicator({
    super.key,
    required this.isPinned,
    this.onTap,
    this.size = 16.0,
    this.color,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<PinIndicator> createState() => _PinIndicatorState();
}

class _PinIndicatorState extends State<PinIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25, // 90 degrees rotation
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation if initially pinned
    if (widget.isPinned) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(PinIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isPinned != widget.isPinned) {
      if (widget.isPinned) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (_opacityAnimation.value == 0.0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159, // Convert to radians
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(widget.size / 4),
                  ),
                  child: Icon(
                    Icons.push_pin,
                    size: widget.size * 0.75,
                    color: effectiveColor,
                    semanticLabel: 'Pinned class',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}