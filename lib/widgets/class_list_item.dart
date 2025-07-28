import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/pin_indicator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ClassListItem extends StatefulWidget {
  final Class classItem;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onUnpin;
  final VoidCallback? onLongPress;
  
  const ClassListItem({
    super.key,
    required this.classItem,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onPin,
    this.onUnpin,
    this.onLongPress,
  });

  @override
  State<ClassListItem> createState() => _ClassListItemState();
}

class _ClassListItemState extends State<ClassListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _backgroundOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: AppConstants.defaultAnimationDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Initialize animations based on initial pin state
    if (widget.classItem.isPinned) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ClassListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.classItem.isPinned != widget.classItem.isPinned) {
      if (widget.classItem.isPinned) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final theme = Theme.of(context);
    
    _borderColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: theme.colorScheme.primary.withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _backgroundOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentCount = widget.classItem.studentCount ?? 0;
    final sessionCount = widget.classItem.sessionCount ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Slidable(
            startActionPane: _buildStartActionPane(theme),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => widget.onEdit(),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  icon: Icons.edit,
                  label: 'Edit',
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.defaultBorderRadius),
                    bottomLeft: Radius.circular(AppConstants.defaultBorderRadius),
                  ),
                ),
                SlidableAction(
                  onPressed: (_) => widget.onDelete(),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  icon: Icons.delete,
                  label: 'Delete',
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppConstants.defaultBorderRadius),
                    bottomRight: Radius.circular(AppConstants.defaultBorderRadius),
                  ),
                ),
              ],
            ),
            child: Hero(
              tag: 'class-${widget.classItem.id}',
              child: Card(
                elevation: _elevationAnimation.value,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  side: BorderSide(
                    color: _borderColorAnimation.value ?? Colors.transparent,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    widget.onLongPress?.call();
                  },
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  child: AnimatedContainer(
                    duration: AppConstants.defaultAnimationDuration,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      gradient: _backgroundOpacityAnimation.value > 0
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(_backgroundOpacityAnimation.value),
                              theme.colorScheme.primary.withOpacity(_backgroundOpacityAnimation.value * 0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: AppConstants.defaultAnimationDuration,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: widget.classItem.isPinned 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                  ) ?? const TextStyle(),
                                  child: Text(
                                    widget.classItem.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PinIndicator(
                                    isPinned: widget.classItem.isPinned,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      widget.onUnpin?.call();
                                    },
                                  ),
                                  AnimatedContainer(
                                    duration: AppConstants.defaultAnimationDuration,
                                    margin: EdgeInsets.only(
                                      left: widget.classItem.isPinned ? 8 : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      studentCount > 0 ? 'Active' : 'Empty',
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoChip(
                                context,
                                Icons.people,
                                '$studentCount ${studentCount == 1 ? 'Student' : 'Students'}',
                                theme.colorScheme.secondary,
                              ),
                              _buildInfoChip(
                                context,
                                Icons.calendar_today,
                                '$sessionCount ${sessionCount == 1 ? 'Session' : 'Sessions'}',
                                theme.colorScheme.tertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ActionPane? _buildStartActionPane(ThemeData theme) {
    if (widget.classItem.isPinned && widget.onUnpin != null) {
      return ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              widget.onUnpin!();
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.push_pin_outlined,
            label: 'Unpin',
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
        ],
      );
    } else if (!widget.classItem.isPinned && widget.onPin != null) {
      return ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              widget.onPin!();
            },
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onTertiary,
            icon: Icons.push_pin,
            label: 'Pin',
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
        ],
      );
    }
    return null;
  }
  
  Widget _buildInfoChip(BuildContext context, IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}