import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/providers.dart';
import 'package:attendance_tracker/models/models.dart';
import 'package:attendance_tracker/widgets/class_list_item.dart';
import 'package:attendance_tracker/widgets/loading_indicator.dart';
import 'package:attendance_tracker/widgets/error_message.dart';
import 'package:attendance_tracker/screens/class_detail_screen.dart';
import 'package:attendance_tracker/widgets/add_class_dialog.dart';
import 'package:attendance_tracker/widgets/confirmation_dialog.dart';
import 'package:attendance_tracker/widgets/custom_snackbar.dart';
import 'package:attendance_tracker/widgets/animated_list_item.dart';
import 'package:attendance_tracker/widgets/pin_context_menu.dart';
import 'package:attendance_tracker/screens/settings_screen.dart';
import 'package:attendance_tracker/providers/auth_provider.dart';
import 'package:attendance_tracker/services/navigation_service.dart';
import 'package:attendance_tracker/utils/page_transitions.dart';
import 'package:attendance_tracker/widgets/name_input_dialog.dart';
import 'package:neopop/neopop.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // Bottom navigation bar removed as settings is available in the top app bar
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.defaultAnimationDuration,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    
    // Load classes when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClassProvider>(context, listen: false).loadClasses();
      _checkAndShowNameDialog();
    });
  }

  Future<void> _checkAndShowNameDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    // Check if user has a display name and is authenticated via phone
    if (user != null && 
        (user.displayName == null || user.displayName!.isEmpty) &&
        authProvider.hasPhoneProvider()) {
      // Show name input dialog for phone authentication
      final name = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const NameInputDialog(),
      );

      if (name != null && name.isNotEmpty) {
        // Update the display name
        try {
          await authProvider.updateDisplayName(name);
        } catch (e) {
          // If updating name fails, show error
          if (mounted) {
            CustomSnackBar.show(
              context: context,
              message: 'Failed to update name: ${e.toString()}',
              type: SnackBarType.error,
            );
          }
        }
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        elevation: 2,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              return GestureDetector(
                onTap: () => _navigateToSettings(context),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: user?.photoURL == null
                        ? Text(
                            _getUserInitials(user),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // AppDrawer removed as it's not needed
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(classProvider),
      ),
      floatingActionButton: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: NeoPopTiltedButton(
                color: Theme.of(context).colorScheme.primary,
                onTapUp: () {
                  HapticFeedback.lightImpact();
                  _showAddClassDialog(context);
                },
                child: child!,
              ),
            ),
          );
        },
        child: _buildAddClassButtonContent(),
      ),
      // Bottom navigation bar removed as settings is available in the top app bar
    );
  }
  
  Widget _buildBody(ClassProvider classProvider) {
    if (classProvider.isLoading) {
      return const LoadingIndicator();
    }
    
    if (classProvider.error != null) {
      return ErrorMessage(
        message: classProvider.error!,
        onRetry: () => classProvider.loadClasses(),
      );
    }
    
    if (classProvider.classes.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Welcome to Attendance Tracker',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'No classes yet',
                style: AppConstants.subheadingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start by adding your first class or subject',
                style: AppConstants.bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showAddClassDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Class'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
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
                        'Tip: You can create multiple classes for different subjects or groups',
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
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => classProvider.loadClasses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: classProvider.classes.length + 1, // +1 for the header
        // Use cacheExtent to improve scrolling performance
        cacheExtent: 500,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header section - use RepaintBoundary to optimize rendering
            return RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: AppConstants.defaultPadding,
                  left: AppConstants.smallPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Classes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${classProvider.classes.length} ${classProvider.classes.length == 1 ? 'class' : 'classes'} available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final classItem = classProvider.classes[index - 1];
          // Use RepaintBoundary to optimize rendering
          return RepaintBoundary(
            child: AnimatedListItem(
              index: index - 1,
              child: ClassListItem(
                classItem: classItem,
                onTap: () => _navigateToClassDetail(context, classItem),
                onEdit: () => _showEditClassDialog(context, classItem),
                onDelete: () => _showDeleteConfirmation(context, classItem),
                onPin: () => _pinClass(context, classItem),
                onUnpin: () => _unpinClass(context, classItem),
                onLongPress: () => _showPinContextMenu(context, classItem),
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _navigateToClassDetail(BuildContext context, Class classItem) async {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    await classProvider.selectClass(classItem.id!);
    
    if (!mounted) return;
    
    NavigationService.navigateTo(
      context,
      const ClassDetailScreen(),
      transitionType: TransitionType.slide,
    ).then((_) {
      // Refresh the class list when returning from the detail screen
      classProvider.loadClasses();
    });
  }
  
  void _showAddClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddClassDialog(),
    );
  }
  
  void _showEditClassDialog(BuildContext context, Class classItem) {
    showDialog(
      context: context,
      builder: (context) => AddClassDialog(classToEdit: classItem),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, Class classItem) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Class',
        message: 'Are you sure you want to delete "${classItem.name}"? '
          'This will also delete all students and attendance records for this class.',
        confirmText: 'Delete',
        onConfirm: () => _deleteClass(context, classItem.id!),
        icon: Icons.delete_forever,
      ),
    );
  }
  
  void _deleteClass(BuildContext context, int classId) async {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final success = await classProvider.deleteClass(classId);
    
    if (!mounted) return;
    
    if (success) {
      CustomSnackBar.show(
        context: context,
        message: 'Class deleted successfully',
        type: SnackBarType.success,
      );
    } else {
      CustomSnackBar.show(
        context: context,
        message: classProvider.error ?? 'Failed to delete class',
        type: SnackBarType.error,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _deleteClass(context, classId),
          textColor: Colors.white,
        ),
      );
    }
  }
  
  void _navigateToSettings(BuildContext context) {
    NavigationService.navigateTo(
      context,
      const SettingsScreen(),
      transitionType: TransitionType.fade,
    );
  }

  String _getUserInitials(user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final names = user.displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0][0].toUpperCase();
      }
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    } else if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      return 'U';
    }
    return 'U';
  }

  // Pin operations
  void _pinClass(BuildContext context, Class classItem) async {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final success = await classProvider.pinClass(classItem.id!);
    
    if (!mounted) return;
    
    if (success) {
      CustomSnackBar.show(
        context: context,
        message: '${classItem.name} pinned to top',
        type: SnackBarType.success,
        duration: const Duration(seconds: 2),
      );
    } else {
      CustomSnackBar.show(
        context: context,
        message: classProvider.error ?? 'Failed to pin class',
        type: SnackBarType.error,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _pinClass(context, classItem),
          textColor: Colors.white,
        ),
      );
    }
  }

  void _unpinClass(BuildContext context, Class classItem) async {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final success = await classProvider.unpinClass(classItem.id!);
    
    if (!mounted) return;
    
    if (success) {
      CustomSnackBar.show(
        context: context,
        message: '${classItem.name} unpinned',
        type: SnackBarType.info,
        duration: const Duration(seconds: 2),
      );
    } else {
      CustomSnackBar.show(
        context: context,
        message: classProvider.error ?? 'Failed to unpin class',
        type: SnackBarType.error,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _unpinClass(context, classItem),
          textColor: Colors.white,
        ),
      );
    }
  }

  void _showPinContextMenu(BuildContext context, Class classItem) {
    PinContextMenu.show(
      context: context,
      classItem: classItem,
      onPin: classItem.isPinned ? null : () => _pinClass(context, classItem),
      onUnpin: classItem.isPinned ? () => _unpinClass(context, classItem) : null,
      onEdit: () => _showEditClassDialog(context, classItem),
      onDelete: () => _showDeleteConfirmation(context, classItem),
    );
  }

  Widget _buildAddClassButtonContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'Add Class',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}