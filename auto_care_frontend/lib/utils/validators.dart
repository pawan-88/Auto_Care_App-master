class Validators {
  static String? validateMobile(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Mobile number is required';
    }

    // Remove any spaces or special characters
    final digitsOnly = input.replaceAll(RegExp(r'[^\d]'), '');

    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      return 'Only numbers are allowed';
    }

    if (digitsOnly.length < 10) {
      return 'Mobile number must be 10 digits';
    }

    if (digitsOnly.length > 10) {
      return 'Mobile number cannot exceed 10 digits';
    }

    return null;
  }

  static String? validateOtp(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'OTP is required';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(input)) {
      return 'OTP must be exactly 6 digits';
    }

    return null;
  }

  static String? validateName(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Name is required';
    }

    if (input.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return null; // Email is optional
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(input)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }
}
