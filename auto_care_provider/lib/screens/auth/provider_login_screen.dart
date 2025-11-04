import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../config/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ProviderLoginScreen extends StatefulWidget {
  @override
  _ProviderLoginScreenState createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  bool _isValidMobile(String s) => RegExp(r'^\d{10}$').hasMatch(s);

  Future<void> _sendOtp() async {
    final mobile = _mobileController.text.trim();
    if (!_isValidMobile(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService().post(
      Constants.providerLogin,
      {'mobile_number': mobile},
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res.statusCode == 200) {
      Navigator.pushNamed(context, '/otp',
          arguments: {'mobile_number': mobile});
    } else {
      String error = 'Failed to send OTP';
      try {
        final body = jsonDecode(res.body);
        error = body['error'] ?? error;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              controller: _mobileController,
              hintText: 'Mobile Number',
              isNumber: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : CustomButton(
                    label: 'Send OTP',
                    onPressed: _sendOtp,
                  ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Register as Provider'),
            ),
          ],
        ),
      ),
    );
  }
}
