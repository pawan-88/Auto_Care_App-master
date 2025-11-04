import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../config/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  @override
  _ProviderRegistrationScreenState createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _loading = false;

  void _register() async {
    setState(() => _loading = true);
    final body = {
      'full_name': _nameController.text,
      'mobile_number': _mobileController.text,
      'email': _emailController.text,
      'specialization': _specializationController.text,
      'experience_years': int.tryParse(_experienceController.text) ?? 0,
    };
    final res = await ApiService().post(Constants.providerRegister, body);
    setState(() => _loading = false);
    if (res.statusCode == 201) {
      Navigator.pushNamed(
        context,
        '/otp',
        arguments: {'mobile_number': _mobileController.text},
      );
    } else {
      final error = res.body;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Provider Registration')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(controller: _nameController, hintText: 'Full Name'),
            SizedBox(height: 12),
            CustomTextField(
              controller: _mobileController,
              hintText: 'Mobile Number',
              isNumber: true,
            ),
            SizedBox(height: 12),
            CustomTextField(
              controller: _emailController,
              hintText: 'Email (optional)',
            ),
            SizedBox(height: 12),
            CustomTextField(
              controller: _specializationController,
              hintText: 'Specialization',
            ),
            SizedBox(height: 12),
            CustomTextField(
              controller: _experienceController,
              hintText: 'Experience Years',
              isNumber: true,
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : CustomButton(label: 'Register', onPressed: _register),
          ],
        ),
      ),
    );
  }
}
