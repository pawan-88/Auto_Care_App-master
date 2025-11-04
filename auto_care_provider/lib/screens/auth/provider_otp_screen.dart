import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ProviderOtpScreen extends StatefulWidget {
  @override
  _ProviderOtpScreenState createState() => _ProviderOtpScreenState();
}

class _ProviderOtpScreenState extends State<ProviderOtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  late String _mobileNumber;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    _mobileNumber = args['mobile_number'];
  }

  void _verifyOtp() async {
    // Validate OTP input
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter OTP')),
      );
      return;
    }

    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP must be 6 digits')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      print('🔍 Verifying OTP...');
      print('Mobile: $_mobileNumber');
      print('OTP: ${_otpController.text.trim()}');

      // ✅ Use providerVerifyOtp endpoint
      final res = await ApiService().post(
        Constants.providerVerifyOtp,
        {
          'mobile_number': _mobileNumber,
          'otp': _otpController.text.trim(),
        },
      );

      setState(() => _loading = false);

      print('Response Status: ${res.statusCode}');
      print('Response Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        print('✅ OTP Verified Successfully!');

        // Save tokens
        await AuthService().saveTokens(
          data['access_token'],
          data['refresh_token'],
        );

        // ✅ Save user data
        if (data['user'] != null) {
          await AuthService().saveUserData(data['user']);
          print('✅ User data saved');
        }

        // ✅ Save provider data
        if (data['provider'] != null) {
          await AuthService().saveProviderData(data['provider']);
          print('✅ Provider data saved');
        }

        // Show success message with provider name
        final providerName = data['provider']?['full_name'] ?? 'Provider';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $providerName!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Small delay to show the snackbar
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to home
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (_) => false,
        );
      } else {
        final errorData = jsonDecode(res.body);
        print('❌ Verification Failed: ${errorData['error']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      print('❌ Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _resendOtp() async {
    setState(() => _loading = true);

    try {
      print('📨 Resending OTP...');

      final res = await ApiService().post(
        Constants.providerLogin,
        {'mobile_number': _mobileNumber},
      );

      setState(() => _loading = false);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('✅ New OTP sent: ${data['otp']}'); // For development

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New OTP sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      print('❌ Resend error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),

            // Icon
            Icon(
              Icons.verified_user,
              size: 100,
              color: Colors.blue,
            ),

            SizedBox(height: 30),

            // Title
            Text(
              'OTP Verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12),

            // Subtitle
            Text(
              'Enter the 6-digit code sent to',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 8),

            // Mobile number
            Text(
              _mobileNumber,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            SizedBox(height: 40),

            // OTP Input Field
            CustomTextField(
              controller: _otpController,
              label: 'OTP Code',
              hintText: 'Enter 6-digit OTP',
              isNumber: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter OTP';
                }
                if (value.length != 6) {
                  return 'OTP must be 6 digits';
                }
                return null;
              },
            ),

            SizedBox(height: 30),

            // Verify Button
            _loading
                ? Center(child: CircularProgressIndicator())
                : CustomButton(
                    label: 'Verify OTP',
                    onPressed: _verifyOtp,
                  ),

            SizedBox(height: 20),

            // Resend OTP Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive OTP? ",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: _loading ? null : _resendOtp,
                  child: Text(
                    'Resend',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
