import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracker/providers/auth_provider.dart';

class LinkPhoneDialog extends StatefulWidget {
  const LinkPhoneDialog({super.key});

  @override
  State<LinkPhoneDialog> createState() => _LinkPhoneDialogState();
}

class _LinkPhoneDialogState extends State<LinkPhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      digits = '+91$digits';
    } else if (digits.length == 11 && digits.startsWith('91')) {
      digits = '+$digits';
    } else if (!digits.startsWith('+')) {
      digits = '+$digits';
    }
    return digits;
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final phoneNumber = _formatPhoneNumber(_phoneController.text.trim());

    try {
      await authProvider.linkPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          setState(() {
            _isLoading = false;
            _otpSent = true;
            _verificationId = verificationId;
          });
        },
        onError: (error) {
          setState(() => _isLoading = false);
          _showErrorSnackBar(error);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      _showErrorSnackBar('Please enter the complete 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.confirmLinkPhoneNumber(_otpCode);

      setState(() => _isLoading = false);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number linked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_otpCode.length == 6) {
      _verifyOTP();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_otpSent ? 'Enter Verification Code' : 'Link Phone Number'),
      content: SizedBox(
        width: double.maxFinite,
        child: _otpSent ? _buildOTPForm() : _buildPhoneForm(),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!_otpSent)
          ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send OTP'),
          ),
        if (_otpSent)
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your phone number to link it to your account',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone),
              prefixText: '+91 ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length != 10) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOTPForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'We sent a 6-digit code to\n${_formatPhoneNumber(_phoneController.text)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 40,
              height: 50,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => _onOTPChanged(value, index),
              ),
            );
          }),
        ),
      ],
    );
  }
}