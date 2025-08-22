import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class StudentListItem extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  
  const StudentListItem({
    super.key,
    required this.student,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendancePercentage = student.attendancePercentage ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
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
              onPressed: (_) => onDelete(),
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
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              onLongPress?.call();
            },
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (student.rollNumber != null && student.rollNumber!.isNotEmpty)
                          Text(
                            'Roll: ${student.rollNumber}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildAttendanceIndicator(context, attendancePercentage),
                      const SizedBox(height: 4),
                      Text(
                        '${attendancePercentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getAttendanceColor(attendancePercentage),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAttendanceIndicator(BuildContext context, double percentage) {
    final color = _getAttendanceColor(percentage);
    
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 4,
            ),
          ),
          Icon(
            _getAttendanceIcon(percentage),
            color: color,
            size: 18,
          ),
        ],
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
  
  IconData _getAttendanceIcon(double percentage) {
    if (percentage >= 90) {
      return Icons.check_circle;
    } else if (percentage >= 75) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }
}