import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_tracker/models/student_model.dart';

class StudentContextMenu extends StatelessWidget {
  final Student student;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;

  const StudentContextMenu({
    super.key,
    required this.student,
    this.onEdit,
    this.onDelete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    
    // Responsive width calculation
    double maxWidth = 280;
    if (screenWidth < 400) {
      maxWidth = screenWidth * 0.85; // 85% of screen width on small devices
    } else if (screenWidth > 600) {
      maxWidth = 320; // Slightly larger on tablets
    }
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: isKeyboardVisible 
            ? mediaQuery.size.height * 0.6 // Limit height when keyboard is visible
            : mediaQuery.size.height * 0.8,
        ),
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
              child: Semantics(
                label: 'Student: ${student.name}${student.rollNumber != null && student.rollNumber!.isNotEmpty ? ', Roll number: ${student.rollNumber}' : ''}${student.attendancePercentage != null ? ', Attendance: ${student.attendancePercentage!.toStringAsFixed(0)} percent' : ''}',
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      radius: 16,
                      child: Text(
                        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        semanticsLabel: 'Student avatar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (student.rollNumber != null && student.rollNumber!.isNotEmpty)
                          Text(
                            'Roll: ${student.rollNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (student.attendancePercentage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getAttendanceColor(student.attendancePercentage!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${student.attendancePercentage!.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _getAttendanceColor(student.attendancePercentage!),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Menu items
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Edit option
                  if (onEdit != null)
                    _buildMenuItem(
                      context: context,
                      icon: Icons.edit,
                      title: 'Edit student',
                      subtitle: 'Modify student details',
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
                      title: 'Delete student',
                      subtitle: 'Remove student permanently',
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
              child: Semantics(
                button: true,
                label: 'Cancel',
                hint: 'Close menu without performing any action',
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    onCancel?.call();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48), // Minimum touch target
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
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
    
    return Semantics(
      button: true,
      label: '$title: $subtitle',
      hint: isDestructive ? 'This action cannot be undone' : null,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48), // Minimum touch target
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
                  semanticLabel: isDestructive ? 'Delete' : 'Edit',
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
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    } else if (percentage >= 75) {
      return Colors.amber.shade700;
    } else {
      return Colors.red;
    }
  }

  static Future<void> show({
    required BuildContext context,
    required Student student,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StudentContextMenu(
          student: student,
          onEdit: onEdit,
          onDelete: onDelete,
          onCancel: onCancel,
        );
      },
    );
  }
}