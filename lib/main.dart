import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/constants/app_constants.dart';
import 'package:attendance_tracker/screens/splash_screen.dart';
import 'package:attendance_tracker/services/service_locator.dart';
import 'package:attendance_tracker/utils/performance_utils.dart';
import 'package:attendance_tracker/utils/app_error_handler.dart';
import 'package:attendance_tracker/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handler
  AppErrorHandler.initialize();
  
  try {
    // Initialize service locator
    final stopwatch = Stopwatch()..start();
    final serviceLocator = ServiceLocator();
    await serviceLocator.initialize();
    stopwatch.stop();
    debugPrint('Service initialization took: ${stopwatch.elapsedMilliseconds}ms');
    
    // Allow all orientations
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
    
    // Enable performance overlay in debug mode
    if (PerformanceUtils.isDebugMode) {
      // PerformanceUtils.enablePerformanceOverlay();
    }
    
    runApp(
      MultiProvider(
        providers: serviceLocator.getProviders(),
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Log the error
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return MaterialApp(
              title: AppConstants.appName,
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              debugShowCheckedModeBanner: false,
              showPerformanceOverlay: PerformanceUtils.isDebugMode && false, // Set to true to enable performance overlay
              home: const SplashScreen(),
              builder: (context, child) {
                // Apply a responsive font scale based on screen width
                final mediaQuery = MediaQuery.of(context);
                final width = mediaQuery.size.width;
                
                // Calculate a font scale factor based on screen width
                // This ensures text is readable on all screen sizes
                double fontScale = 1.0;
                if (width < 360) {
                  fontScale = 0.8; // Small phones
                } else if (width > 1200) {
                  fontScale = 1.2; // Large tablets/desktops
                }
                
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(fontScale),
                  ),
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}