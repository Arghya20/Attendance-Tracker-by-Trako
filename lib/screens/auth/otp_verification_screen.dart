import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:attendance_tracker/providers/auth_provider.dart';
import 'package:attendance_tracker/screens/home_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> with CodeAutoFill {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _requestSmsPermissionAndListen();
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      // Auto-fill the OTP fields
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = code![i];
      }
      // Auto-verify
      _verifyOTP();
    }
  }

  Future<void> _requestSmsPermissionAndListen() async {
    try {
      // Request SMS permission
      final status = await Permission.sms.request();
      
      if (status.isGranted) {
        // Permission granted, start listening for SMS
        await SmsAutoFill().listenForCode();
      } else if (status.isDenied) {
        // Permission denied, show info
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS permission denied. Please enter OTP manually.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, show settings option
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('SMS permission is required for auto-fill'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // If permission request fails, just continue without auto-fill
      debugPrint('SMS permission error: $e');
    }
  }

  @override
  void dispose() {
    cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      _showErrorDialog('Please enter the complete 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = await authProvider.verifyOTP(
        otp: _otpCode,
        verificationId: widget.verificationId,
      );

      setState(() => _isLoading = false);

      if (user != null) {
        _navigateToHome();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithPhone(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId) {
          setState(() => _isResending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (error) {
          setState(() => _isResending = false);
          _showErrorDialog(error);
        },
      );
    } catch (e) {
      setState(() => _isResending = false);
      _showErrorDialog(e.toString());
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all digits are entered
    if (_otpCode.length == 6) {
      _verifyOTP();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Icon
              const Icon(
                Icons.sms,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Enter Verification Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'We sent a 6-digit code to\n${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // OTP Input Fields with Auto-fill
              PinFieldAutoFill(
                codeLength: 6,
                decoration: BoxLooseDecoration(
                  strokeColorBuilder: FixedColorBuilder(Colors.grey),
                  bgColorBuilder: FixedColorBuilder(Colors.white),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  gapSpace: 10,
                  radius: const Radius.circular(8),
                  strokeWidth: 2,
                ),
                currentCode: _otpCode,
                onCodeSubmitted: (code) {
                  // Update controllers when code is submitted
                  for (int i = 0; i < 6 && i < code.length; i++) {
                    _otpControllers[i].text = code[i];
                  }
                },
                onCodeChanged: (code) {
                  if (code?.length == 6) {
                    // Update controllers
                    for (int i = 0; i < 6; i++) {
                      _otpControllers[i].text = code![i];
                    }
                    // Auto-verify
                    _verifyOTP();
                  }
                },
              ),

              const SizedBox(height: 32),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Verify Code',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

              const SizedBox(height: 24),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code? "),
                  TextButton(
                    onPressed: _isResending ? null : _resendOTP,
                    child: _isResending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend'),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),

              // Change Phone Number
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Change Phone Number'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}