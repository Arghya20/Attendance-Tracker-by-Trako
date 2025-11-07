import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:attendance_tracker/models/user_model.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _currentUser;
  String? _verificationId;
  
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  AuthService() {
    _init();
  }
  
  void _init() {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    } else {
      _status = AuthStatus.authenticated;
      _currentUser = UserModel.fromFirebaseUser(firebaseUser);
    }
    notifyListeners();
  }
  
  // Phone Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    Function(UserModel)? onAutoVerified,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();
      
      // For development: Check if it's a test number
      if (_isTestPhoneNumber(phoneNumber)) {
        // Simulate code sent for test numbers
        onCodeSent('test-verification-id');
        return;
      }
      
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            if (userCredential.user != null && onAutoVerified != null) {
              onAutoVerified(UserModel.fromFirebaseUser(userCredential.user!));
            }
          } catch (e) {
            onError('Auto-verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          onError(_getErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      onError('Phone verification failed: ${e.toString()}');
    }
  }
  
  Future<UserModel?> verifyOTP({
    required String otp,
    String? verificationId,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();
      
      // Handle test verification ID
      if (verificationId == 'test-verification-id') {
        // For test numbers, accept any 6-digit code
        if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
          // Create a mock user for testing
          _status = AuthStatus.authenticated;
          notifyListeners();
          // Return null to indicate success but let Firebase handle the actual user creation
          // In a real scenario, you might want to create a test user
          return null;
        } else {
          throw Exception('Invalid verification code format');
        }
      }
      
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId ?? _verificationId!,
        smsCode: otp,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return UserModel.fromFirebaseUser(userCredential.user!);
      }
      return null;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      throw Exception(_getErrorMessage(e));
    }
  }
  
  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return null; // User cancelled
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return UserModel.fromFirebaseUser(userCredential.user!);
      }
      return null;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
  
  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
        await _googleSignIn.signOut();
      }
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
  
  // Link Phone Number to existing account
  Future<void> linkPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await user.linkWithCredential(credential);
          } catch (e) {
            onError('Auto-linking failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_getErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError('Phone linking failed: ${e.toString()}');
    }
  }
  
  Future<void> confirmLinkPhoneNumber(String otp) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      await user.linkWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to link phone number: ${e.toString()}');
    }
  }
  
  // Unlink Phone Number
  Future<void> unlinkPhoneNumber() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      await user.unlink(PhoneAuthProvider.PROVIDER_ID);
    } catch (e) {
      throw Exception('Failed to unlink phone number: ${e.toString()}');
    }
  }
  
  // Unlink Google Account
  Future<void> unlinkGoogleAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      await user.unlink(GoogleAuthProvider.PROVIDER_ID);
    } catch (e) {
      throw Exception('Failed to unlink Google account: ${e.toString()}');
    }
  }
  
  // Reauthenticate with phone
  Future<void> reauthenticateWithPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final user = _firebaseAuth.currentUser;
            if (user != null) {
              await user.reauthenticateWithCredential(credential);
            }
          } catch (e) {
            onError('Auto-reauthentication failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_getErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError('Phone reauthentication failed: ${e.toString()}');
    }
  }
  
  Future<void> confirmReauthenticateWithPhone(String otp) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to reauthenticate: ${e.toString()}');
    }
  }
  
  // Get user provider data
  List<String> getUserProviders() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];
    
    return user.providerData.map((info) => info.providerId).toList();
  }
  
  bool hasPhoneProvider() {
    return getUserProviders().contains(PhoneAuthProvider.PROVIDER_ID);
  }
  
  bool hasGoogleProvider() {
    return getUserProviders().contains(GoogleAuthProvider.PROVIDER_ID);
  }
  
  // Helper method to check if phone number is for testing
  bool _isTestPhoneNumber(String phoneNumber) {
    final testNumbers = [
      '+1 650-555-3434',
      '+91 98765 43210',
      '+1234567890', // Add your test numbers here
    ];
    return testNumbers.contains(phoneNumber);
  }
  
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'The phone number format is invalid.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'invalid-verification-code':
          return 'The verification code is invalid.';
        case 'invalid-verification-id':
          return 'The verification ID is invalid.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'credential-already-in-use':
          return 'This credential is already associated with a different user account.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found with this information.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'billing-not-enabled':
          return 'Phone authentication requires billing to be enabled. Please enable billing in Firebase Console or use Google Sign-In instead.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    }
    return error.toString();
  }
}