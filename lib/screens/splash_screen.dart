import 'package:flutter/material.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/screens/home_screen.dart';
import 'package:attendance_tracker/services/service_locator.dart';
import 'package:attendance_tracker/utils/page_transitions.dart';
import 'package:attendance_tracker/utils/connectivity_checker.dart';
import 'package:attendance_tracker/utils/app_error_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  bool _showRetryButton = false;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
    
    // Initialize services
    _initializeServices();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeServices() async {
    try {
      setState(() {
        _statusMessage = 'Checking connectivity...';
      });
      
      // Check if the app is ready to use
      final isAppReady = await ConnectivityChecker.isAppReady();
      
      if (!isAppReady) {
        setState(() {
          _statusMessage = 'Database not available. Please try again.';
        });
        return;
      }
      
      setState(() {
        _statusMessage = 'Initializing services...';
      });
      
      // Initialize service locator
      final serviceLocator = ServiceLocator();
      await serviceLocator.initialize();
      
      setState(() {
        _statusMessage = 'Loading data...';
      });
      
      // Preload some data
      await serviceLocator.classProvider.loadClasses();
      
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready!';
      });
      
      // Navigate to home screen after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            FadePageRoute(
              page: const HomeScreen(),
              duration: const Duration(milliseconds: 300),
            ),
          );
        }
      });
    } catch (e, stackTrace) {
      // Log the error
      debugPrint('Error initializing services: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _statusMessage = 'Error initializing app. Please try again.';
      });
      
      // Show retry button
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showRetryButton = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.people,
                    size: 60,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App name
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                AppConstants.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      value: _isInitialized ? 1.0 : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_showRetryButton) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeServices,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}