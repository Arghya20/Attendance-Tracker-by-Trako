import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';
import 'package:attendance_tracker/widgets/error_message.dart';
import 'package:intl/intl.dart';

class MonthSelectionDialog extends StatefulWidget {
  final List<DateTime> availableMonths;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  
  const MonthSelectionDialog({
    super.key,
    required this.availableMonths,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<MonthSelectionDialog> createState() => _MonthSelectionDialogState();
}

class _MonthSelectionDialogState extends State<MonthSelectionDialog> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Select Month'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _buildContent(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _animationController.reverse().then((_) {
                Navigator.pop(context);
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: LoadingIndicator(message: 'Loading available months...'),
      );
    }
    
    if (widget.errorMessage != null) {
      return ErrorMessage(
        message: widget.errorMessage!,
        onRetry: widget.onRetry,
      );
    }
    
    if (widget.availableMonths.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return _buildMonthList(context);
  }
  
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Attendance Data Found',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'There are no attendance sessions recorded for this class yet.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Take attendance for this class to see monthly reports.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthList(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a month to view detailed attendance data:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: widget.availableMonths.length,
            itemBuilder: (context, index) {
              final month = widget.availableMonths[index];
              return _buildMonthItem(context, month);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildMonthItem(BuildContext context, DateTime month) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(month);
    final monthAbbrev = DateFormat('MMM').format(month);
    final year = DateFormat('yyyy').format(month);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                monthAbbrev,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                year,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          monthName,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          _getMonthDescription(month),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: () {
          _animationController.reverse().then((_) {
            Navigator.pop(context, month);
          });
        },
      ),
    );
  }
  
  String _getMonthDescription(DateTime month) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final selectedMonth = DateTime(month.year, month.month);
    
    if (selectedMonth.isAtSameMomentAs(currentMonth)) {
      return 'Current month';
    } else if (selectedMonth.isAfter(currentMonth)) {
      return 'Future month';
    } else {
      final difference = currentMonth.difference(selectedMonth).inDays;
      final monthsDiff = ((difference / 30).round());
      
      if (monthsDiff == 1) {
        return 'Last month';
      } else if (monthsDiff < 12) {
        return '$monthsDiff months ago';
      } else {
        final yearsDiff = (monthsDiff / 12).floor();
        if (yearsDiff == 1) {
          return '1 year ago';
        } else {
          return '$yearsDiff years ago';
        }
      }
    }
  }
}

// Helper function to show the month selection dialog
Future<DateTime?> showMonthSelectionDialog({
  required BuildContext context,
  required List<DateTime> availableMonths,
  bool isLoading = false,
  String? errorMessage,
  VoidCallback? onRetry,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: !isLoading,
    builder: (context) => MonthSelectionDialog(
      availableMonths: availableMonths,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRetry: onRetry,
    ),
  );
}