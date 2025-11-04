import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../config/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ProviderProfileScreen extends StatefulWidget {
  @override
  _ProviderProfileScreenState createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    final res = await ApiService().get(Constants.providerProfile);
    setState(() => _loading = false);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      _nameController.text = json['full_name'] ?? '';
      _emailController.text = json['email'] ?? '';
      _specializationController.text = json['specialization'] ?? '';
      _experienceController.text = (json['experience_years'] ?? '').toString();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    final body = {
      'full_name': _nameController.text,
      'email': _emailController.text,
      'specialization': _specializationController.text,
      'experience_years': int.tryParse(_experienceController.text) ?? 0,
    };
    final res = await ApiService().post(Constants.providerProfile, body);
    setState(() => _loading = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Provider Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(controller: _nameController, hintText: 'Full Name'),
            SizedBox(height: 12),
            CustomTextField(controller: _emailController, hintText: 'Email'),
            SizedBox(height: 12),
            CustomTextField(
              controller: _specializationController,
              hintText: 'Specialization',
            ),
            SizedBox(height: 12),
            CustomTextField(
              controller: _experienceController,
              hintText: 'Experience (years)',
              isNumber: true,
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : CustomButton(label: 'Save Profile', onPressed: _saveProfile),
          ],
        ),
      ),
    );
  }
}
