import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';
import 'package:attendance_tracker/widgets/error_message.dart';
import 'package:attendance_tracker/widgets/student_list_item.dart';
import 'package:attendance_tracker/widgets/add_student_dialog.dart';
import 'package:attendance_tracker/widgets/add_class_dialog.dart';
import 'package:attendance_tracker/widgets/bottom_action_bar.dart';
import 'package:attendance_tracker/widgets/confirmation_dialog.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/widgets/action_button.dart';
import 'package:attendance_tracker/widgets/student_details_dialog.dart';
import 'package:attendance_tracker/widgets/animated_list_item.dart';
import 'package:attendance_tracker/widgets/student_context_menu.dart';
import 'package:attendance_tracker/screens/take_attendance_screen.dart';
import 'package:attendance_tracker/screens/attendance_history_screen.dart';

import 'package:attendance_tracker/services/navigation_service.dart';
import 'package:attendance_tracker/utils/page_transitions.dart';
import 'package:attendance_tracker/utils/responsive_layout.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({super.key});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showScrollToBottomButton = false;

  /// Calculates the appropriate bottom spacing for the ListView to ensure
  /// the last student item is fully visible above the bottom action bar.
  ///
  /// This method accounts for:
  /// - BottomActionBar total height (button + padding + safe area)
  /// - Keyboard visibility and height adjustments
  /// - Responsive spacing adjustments based on screen size
  /// - Additional spacing buffer for better UX
  /// - Minimum spacing requirements for edge cases
  ///
  /// The spacing automatically updates when MediaQuery changes (orientation,
  /// keyboard appearance, safe area changes) since it uses MediaQuery.of(context).
  double _calculateBottomSpacing(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Check if keyboard is visible
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final double keyboardHeight = mediaQuery.viewInsets.bottom;

    if (isKeyboardVisible) {
      // When keyboard is visible, adjust spacing to account for it
      return _calculateKeyboardAwareSpacing(context, keyboardHeight);
    } else {
      // Normal spacing calculation when keyboard is not visible
      return _calculateNormalSpacing(context);
    }
  }

  /// Calculates spacing when keyboard is visible
  double _calculateKeyboardAwareSpacing(
    BuildContext context,
    double keyboardHeight,
  ) {
    // When keyboard is visible, we need less bottom spacing since the keyboard
    // pushes the action bar up and reduces available screen space

    // Base action bar height without safe area (since keyboard handles that)
    double baseSpacing = BottomActionBar.getMinimumHeight();

    // Add minimal responsive spacing for keyboard mode
    double keyboardModeSpacing = _getKeyboardModeSpacing(context);
    baseSpacing += keyboardModeSpacing;

    // Ensure minimum spacing even with keyboard
    final double minimumKeyboardSpacing = _getMinimumKeyboardSpacing(context);

    return baseSpacing < minimumKeyboardSpacing
        ? minimumKeyboardSpacing
        : baseSpacing;
  }

  /// Calculates normal spacing when keyboard is not visible
  double _calculateNormalSpacing(BuildContext context) {
    // Use BottomActionBar's total height calculation as base
    double totalSpacing = BottomActionBar.getTotalHeight(context);

    // Add responsive spacing adjustments based on screen size
    double responsiveSpacing = _getResponsiveSpacing(context);
    totalSpacing += responsiveSpacing;

    // Enforce minimum spacing for edge cases (very small screens, etc.)
    final double minimumSpacing = _getMinimumSpacing(context);

    return totalSpacing < minimumSpacing ? minimumSpacing : totalSpacing;
  }

  /// Gets responsive spacing adjustment based on screen size
  double _getResponsiveSpacing(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      // Desktop: More generous spacing for better visual hierarchy
      return AppConstants.largePadding; // 24px
    } else if (ResponsiveLayout.isTablet(context)) {
      // Tablet: Medium spacing for balanced layout
      return AppConstants.defaultPadding; // 16px
    } else {
      // Mobile: Minimal additional spacing to maximize content area
      return AppConstants.smallPadding; // 8px
    }
  }

  /// Gets minimum spacing based on screen size and constraints
  double _getMinimumSpacing(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    // Base minimum from BottomActionBar
    double baseMinimum =
        BottomActionBar.getMinimumHeight() + AppConstants.smallPadding;

    if (ResponsiveLayout.isDesktop(context)) {
      // Desktop: Higher minimum for better visual balance
      return baseMinimum + AppConstants.largePadding; // +24px
    } else if (ResponsiveLayout.isTablet(context)) {
      // Tablet: Medium minimum spacing
      return baseMinimum + AppConstants.defaultPadding; // +16px
    } else {
      // Mobile: Adaptive minimum based on screen height
      if (screenHeight < 600) {
        // Very small screens: Use absolute minimum
        return baseMinimum;
      } else if (screenHeight < 800) {
        // Small screens: Small additional spacing
        return baseMinimum + AppConstants.smallPadding; // +8px
      } else {
        // Larger mobile screens: Standard additional spacing
        return baseMinimum + AppConstants.defaultPadding; // +16px
      }
    }
  }

  /// Gets responsive horizontal padding based on screen size
  double _getResponsiveHorizontalPadding(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      // Desktop: More generous horizontal padding for better content width
      return AppConstants.largePadding * 2; // 48px
    } else if (ResponsiveLayout.isTablet(context)) {
      // Tablet: Increased padding for better readability
      return AppConstants.largePadding; // 24px
    } else {
      // Mobile: Standard padding to maximize content area
      return AppConstants.defaultPadding; // 16px
    }
  }

  /// Gets responsive header padding for visual consistency
  double _getResponsiveHeaderPadding(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      // Desktop: Minimal additional padding since horizontal padding is already generous
      return AppConstants.smallPadding; // 8px
    } else if (ResponsiveLayout.isTablet(context)) {
      // Tablet: Small additional padding
      return AppConstants.smallPadding; // 8px
    } else {
      // Mobile: Standard small padding
      return AppConstants.smallPadding; // 8px
    }
  }

  /// Gets spacing adjustment for keyboard mode (reduced spacing)
  double _getKeyboardModeSpacing(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      // Desktop: Standard spacing even with keyboard
      return AppConstants.defaultPadding; // 16px
    } else if (ResponsiveLayout.isTablet(context)) {
      // Tablet: Reduced spacing for keyboard mode
      return AppConstants.smallPadding; // 8px
    } else {
      // Mobile: Minimal spacing to maximize content area with keyboard
      return AppConstants.smallPadding / 2; // 4px
    }
  }

  /// Gets minimum spacing when keyboard is visible
  double _getMinimumKeyboardSpacing(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;

    // Base minimum from BottomActionBar without safe area
    double baseMinimum = BottomActionBar.getMinimumHeight();

    if (ResponsiveLayout.isDesktop(context)) {
      // Desktop: Standard minimum even with keyboard
      return baseMinimum + AppConstants.smallPadding; // +8px
    } else if (ResponsiveLayout.isTablet(context)) {
      // Tablet: Reduced minimum for keyboard mode
      return baseMinimum + AppConstants.smallPadding / 2; // +4px
    } else {
      // Mobile: Adaptive minimum based on available height with keyboard
      if (availableHeight < 400) {
        // Very constrained space: absolute minimum
        return baseMinimum;
      } else if (availableHeight < 600) {
        // Constrained space: minimal additional spacing
        return baseMinimum + AppConstants.smallPadding / 2; // +4px
      } else {
        // Adequate space: small additional spacing
        return baseMinimum + AppConstants.smallPadding; // +8px
      }
    }
  }



  /// Smoothly scrolls to the top of the student list
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Handles scroll events to show/hide scroll-to-bottom button
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Show button if user has scrolled up significantly and there's content below
    final shouldShow = maxScroll > 200 && currentScroll < maxScroll - 100;

    if (shouldShow != _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = shouldShow;
      });
    }
  }

  /// Handles attendance updates by refreshing student data
  void _onAttendanceUpdated(int classId) {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    // Only refresh if this is the current class to avoid unnecessary work
    if (studentProvider.currentClassId == classId) {
      studentProvider.invalidateAttendanceCache(classId);
      studentProvider.refreshAttendanceStats(classId).then((_) {
        // Check for errors after refresh
        if (studentProvider.error != null && mounted) {
          _handleRefreshError(studentProvider.error!);
        }
      });
    }
  }

  /// Handles refresh errors with user-friendly messages and retry options
  void _handleRefreshError(String error) {
    CustomSnackBar.show(
      context: context,
      message: 'Failed to refresh attendance data: $error',
      type: SnackBarType.error,
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () => _refreshStudentData(),
        textColor: Colors.white,
      ),
    );
  }

  /// Manually refresh student data
  void _refreshStudentData() {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    if (classProvider.selectedClass != null) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      studentProvider.invalidateAttendanceCache(classProvider.selectedClass!.id!);
      studentProvider.refreshAttendanceStats(classProvider.selectedClass!.id!);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();

    // Add scroll listener to show/hide scroll-to-bottom button
    _scrollController.addListener(_onScroll);

    // Load students when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      if (classProvider.selectedClass != null) {
        Provider.of<StudentProvider>(
          context,
          listen: false,
        ).loadStudents(classProvider.selectedClass!.id!);
      }
      
      // Set up attendance update listener
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      attendanceProvider.onAttendanceUpdated = _onAttendanceUpdated;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = Provider.of<ClassProvider>(context);
    final theme = Theme.of(context);

    if (classProvider.selectedClass == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Class Details')),
        body: const Center(child: Text('No class selected')),
      );
    }

    final classItem = classProvider.selectedClass!;

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'class-title-${classItem.id}',
          child: Text(classItem.name),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditClassDialog(context, classItem),
            tooltip: 'Edit Class',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final studentProvider = Provider.of<StudentProvider>(
                context,
                listen: false,
              );
              studentProvider.loadStudents(classItem.id!);
            },
            tooltip: 'Refresh',
          ),
        ],
        // Drawer is now added in the home screen
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Students'), Tab(text: 'Analytics')],
          labelColor: theme.brightness == Brightness.light 
              ? theme.colorScheme.onPrimary 
              : theme.colorScheme.onSurface,
          unselectedLabelColor: theme.brightness == Brightness.light 
              ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 3.0,
              color: theme.brightness == Brightness.light 
                  ? Colors.white 
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStudentsTab(classItem), _buildActionsTab(classItem)],
      ),
      floatingActionButton: _buildFloatingActionButton(classItem),
    );
  }

  Widget? _buildFloatingActionButton(Class classItem) {
    if (_tabController.index == 0) {
      // Students tab - no floating action button
      return null;
    } else {
      // Analytics tab - show add student button
      return FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context, classItem.id!),
        tooltip: 'Add Student',
        child: const Icon(Icons.person_add),
      );
    }
  }

  Widget _buildStudentsTab(Class classItem) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Main content
        _buildStudentsContent(classItem, studentProvider, theme),
        // Bottom action bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomActionBar(
            onAddStudent: () => _showAddStudentDialog(context, classItem.id!),
            onTakeAttendance:
                studentProvider.students.isNotEmpty
                    ? () => _takeAttendance(context, classItem)
                    : null,
            canTakeAttendance: studentProvider.students.isNotEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsContent(
    Class classItem,
    StudentProvider studentProvider,
    ThemeData theme,
  ) {
    if (studentProvider.isLoading) {
      return const LoadingIndicator();
    }

    if (studentProvider.error != null) {
      return ErrorMessage(
        message: studentProvider.error!,
        onRetry: () {
          studentProvider.loadStudents(classItem.id!);
        },
      );
    }

    if (studentProvider.students.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: _calculateBottomSpacing(context),
        ), // Dynamic spacing that updates with MediaQuery changes
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(_getResponsiveHorizontalPadding(context)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'No Students Yet',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Add students to this class to start taking attendance',
                  style: AppConstants.bodyStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.amber),
                        SizedBox(height: 8),
                        Text(
                          'Tip: Use the "Add Student" button below to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => studentProvider.loadStudents(classItem.id!),
      child: ListView.builder(
        controller: _scrollController,
        // Configure scroll physics for consistent behavior
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: _getResponsiveHorizontalPadding(context),
          right: _getResponsiveHorizontalPadding(context),
          top: AppConstants.defaultPadding,
          bottom: _calculateBottomSpacing(
            context,
          ), // Dynamic spacing that updates with MediaQuery changes
        ),
        itemCount: studentProvider.students.length + 1, // +1 for the header
        // Use cacheExtent to improve scrolling performance
        cacheExtent: 500,
        // Optimize memory usage by not keeping alive off-screen items
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header section - use RepaintBoundary to optimize rendering
            return RepaintBoundary(
              child: GestureDetector(
                onTap: _scrollToTop,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: AppConstants.defaultPadding,
                    left: _getResponsiveHeaderPadding(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Students',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(width: 8),
                          if (studentProvider.students.length > 5)
                            Icon(
                              Icons.keyboard_arrow_up,
                              size: 16,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.5),
                            ),
                        ],
                      ),
                      Text(
                        '${studentProvider.students.length} ${studentProvider.students.length == 1 ? 'student' : 'students'} in this class',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final student = studentProvider.students[index - 1];
          // Use RepaintBoundary to optimize rendering
          return RepaintBoundary(
            child: AnimatedListItem(
              index: index,
              child: StudentListItem(
                student: student,
                onTap: () => _showStudentDetails(context, student),
                onEdit:
                    () =>
                        _showEditStudentDialog(context, classItem.id!, student),
                onDelete:
                    () => _showDeleteStudentConfirmation(context, student),
                onLongPress: () => _showStudentContextMenu(context, student),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionsTab(Class classItem) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage attendance for ${classItem.name}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ResponsiveBuilder(
              builder: (context, constraints, screenSize) {
                int crossAxisCount;

                switch (screenSize) {
                  case ScreenSize.mobile:
                    crossAxisCount = 2;
                    break;
                  case ScreenSize.tablet:
                    crossAxisCount = 3;
                    break;
                  case ScreenSize.desktop:
                    crossAxisCount = 4;
                    break;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    ActionButton(
                      label: 'View History',
                      icon: Icons.history,
                      onPressed:
                          () => _viewAttendanceHistory(context, classItem),
                      color: Colors.blue,
                    ),
                    ActionButton(
                      label: 'Export Data',
                      icon: Icons.download,
                      onPressed: () => _exportData(context, classItem),
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => StudentDetailsDialog(student: student),
    );
  }

  void _showStudentContextMenu(BuildContext context, Student student) {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    if (classProvider.selectedClass != null) {
      StudentContextMenu.show(
        context: context,
        student: student,
        onEdit: () => _showEditStudentDialog(context, classProvider.selectedClass!.id!, student),
        onDelete: () => _showDeleteStudentConfirmation(context, student),
      );
    }
  }

  void _showAddStudentDialog(BuildContext context, int classId) {
    showDialog(
      context: context,
      builder: (context) => AddStudentDialog(classId: classId),
    );
  }

  void _showEditStudentDialog(
    BuildContext context,
    int classId,
    Student student,
  ) {
    showDialog(
      context: context,
      builder:
          (context) =>
              AddStudentDialog(classId: classId, studentToEdit: student),
    );
  }

  void _showDeleteStudentConfirmation(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Delete Student',
            message:
                'Are you sure you want to delete "${student.name}"? '
                'This will also delete all attendance records for this student.',
            confirmText: 'Delete',
            onConfirm: () => _deleteStudent(context, student.id!),
            icon: Icons.delete_forever,
          ),
    );
  }

  void _deleteStudent(BuildContext context, int studentId) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final success = await studentProvider.deleteStudent(studentId);

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(
        context: context,
        message: 'Student deleted successfully',
        type: SnackBarType.success,
      );
    } else {
      CustomSnackBar.show(
        context: context,
        message: studentProvider.error ?? 'Failed to delete student',
        type: SnackBarType.error,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _deleteStudent(context, studentId),
          textColor: Colors.white,
        ),
      );
    }
  }

  void _showEditClassDialog(BuildContext context, Class classItem) {
    showDialog(
      context: context,
      builder: (context) => AddClassDialog(classToEdit: classItem),
    ).then((_) {
      // Refresh the class data after editing
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      classProvider.loadClasses();

      // Update the selected class if it was edited
      if (classProvider.classes.isNotEmpty) {
        final updatedClass = classProvider.classes.firstWhere(
          (c) => c.id == classItem.id,
          orElse: () => classItem,
        );
        classProvider.selectClass(updatedClass.id!);
      }
    });
  }

  void _takeAttendance(BuildContext context, Class classItem) async {
    final result = await NavigationService.navigateTo(
      context,
      TakeAttendanceScreen(classItem: classItem),
      transitionType: TransitionType.slide,
    );
    
    // Refresh data when returning from attendance screen
    if (result == true) {
      _onAttendanceUpdated(classItem.id!);
    }
  }

  void _viewAttendanceHistory(BuildContext context, Class classItem) {
    NavigationService.navigateTo(
      context,
      AttendanceHistoryScreen(classItem: classItem),
      transitionType: TransitionType.slide,
    );
  }

  void _exportData(BuildContext context, Class classItem) {
    CustomSnackBar.show(
      context: context,
      message: 'Export functionality will be available in a future update',
      type: SnackBarType.info,
    );
  }
}
