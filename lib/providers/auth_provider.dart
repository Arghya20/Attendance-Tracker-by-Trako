import 'package:flutter/material.dart';
import 'package:attendance_tracker/models/user_model.dart';
import 'package:attendance_tracker/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  // Expose auth service for callback setup
  AuthService get authService => _authService;
  
  AuthStatus get status => _authService.status;
  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _authService.status == AuthStatus.authenticating;
  
  AuthProvider() {
    _authService.addListener(_onAuthServiceChanged);
  }
  
  void _onAuthServiceChanged() {
    notifyListeners();
  }
  
  // Phone Authentication
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    Function(UserModel)? onAutoVerified,
  }) async {
    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: onAutoVerified,
    );
  }
  
  Future<UserModel?> verifyOTP({
    required String otp,
    String? verificationId,
  }) async {
    try {
      return await _authService.verifyOTP(
        otp: otp,
        verificationId: verificationId,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    try {
      return await _authService.signInWithGoogle();
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    await _authService.signOut();
  }
  
  // Delete Account
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
  }
  
  // Link Phone Number
  Future<void> linkPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    await _authService.linkPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }
  
  Future<void> confirmLinkPhoneNumber(String otp) async {
    await _authService.confirmLinkPhoneNumber(otp);
  }
  
  // Link Google Account
  Future<void> linkGoogleAccount() async {
    await _authService.linkGoogleAccount();
  }
  
  // Unlink providers
  Future<void> unlinkPhoneNumber() async {
    await _authService.unlinkPhoneNumber();
  }
  
  Future<void> unlinkGoogleAccount() async {
    await _authService.unlinkGoogleAccount();
  }
  
  // Reauthenticate
  Future<void> reauthenticateWithPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    await _authService.reauthenticateWithPhone(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }
  
  Future<void> confirmReauthenticateWithPhone(String otp) async {
    await _authService.confirmReauthenticateWithPhone(otp);
  }
  
  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    await _authService.updateDisplayName(displayName);
  }
  
  // Provider info
  List<String> getUserProviders() {
    return _authService.getUserProviders();
  }
  
  bool hasPhoneProvider() {
    return _authService.hasPhoneProvider();
  }
  
  bool hasGoogleProvider() {
    return _authService.hasGoogleProvider();
  }
  
  @override
  void dispose() {
    _authService.removeListener(_onAuthServiceChanged);
    super.dispose();
  }
}