import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_tracker/models/class_model.dart';

class PinContextMenu extends StatelessWidget {
  final Class classItem;
  final VoidCallback? onPin;
  final VoidCallback? onUnpin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;

  const PinContextMenu({
    super.key,
    required this.classItem,
    this.onPin,
    this.onUnpin,
    this.onEdit,
    this.onDelete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      classItem.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (classItem.isPinned)
                    Icon(
                      Icons.push_pin,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                ],
              ),
            ),
            
            // Menu items
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Pin/Unpin option
                  if (classItem.isPinned && onUnpin != null)
                    _buildMenuItem(
                      context: context,
                      icon: Icons.push_pin_outlined,
                      title: 'Unpin from top',
                      subtitle: 'Remove from pinned classes',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        onUnpin!();
                      },
                    )
                  else if (!classItem.isPinned && onPin != null)
                    _buildMenuItem(
                      context: context,
                      icon: Icons.push_pin,
                      title: 'Pin to top',
                      subtitle: 'Keep at the top of the list',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        onPin!();
                      },
                    ),
                  
                  // Edit option
                  if (onEdit != null)
                    _buildMenuItem(
                      context: context,
                      icon: Icons.edit,
                      title: 'Edit class',
                      subtitle: 'Modify class details',
                      onTap: () {
                        Navigator.of(context).pop();
                        onEdit!();
                      },
                    ),
                  
                  // Delete option
                  if (onDelete != null)
                    _buildMenuItem(
                      context: context,
                      icon: Icons.delete,
                      title: 'Delete class',
                      subtitle: 'Remove class permanently',
                      isDestructive: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        onDelete!();
                      },
                    ),
                ],
              ),
            ),
            
            // Cancel button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive 
        ? theme.colorScheme.error 
        : theme.colorScheme.onSurface;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isDestructive 
                    ? theme.colorScheme.error 
                    : theme.colorScheme.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required Class classItem,
    VoidCallback? onPin,
    VoidCallback? onUnpin,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PinContextMenu(
          classItem: classItem,
          onPin: onPin,
          onUnpin: onUnpin,
          onEdit: onEdit,
          onDelete: onDelete,
          onCancel: onCancel,
        );
      },
    );
  }
}