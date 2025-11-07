import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/auth_provider.dart';
import 'package:attendance_tracker/screens/auth/login_screen.dart';
import 'package:attendance_tracker/screens/home_screen.dart';
import 'package:attendance_tracker/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.uninitialized:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          case AuthStatus.authenticated:
            return const HomeScreen();
          case AuthStatus.unauthenticated:
          case AuthStatus.authenticating:
            return const LoginScreen();
        }
      },
    );
  }
}