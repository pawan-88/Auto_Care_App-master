import 'package:flutter/material.dart';

class ApiConstants {
  // ⚠️ IMPORTANT: Change based on your setup
  // For Android Emulator: use 10.0.2.2:8000
  // For iOS Simulator: use 127.0.0.1:8000
  // For Real Device: use your computer's IP (e.g., 192.168.1.100:8000)

  //static const String baseUrl = 'http://10.240.95.214:8000'; // Android Emulator
  // static const String baseUrl = 'http://127.0.0.1:8000'; // iOS Simulator
  static const String baseUrl = 'http://10.157.72.214:8000'; // Real Device

  // API Endpoints
  static const String sendOtp = '$baseUrl/api/accounts/send-otp/';
  static const String verifyOtp = '$baseUrl/api/accounts/verify-otp/';
  static const String refreshToken = '$baseUrl/api/accounts/token/refresh/';
  static const String userProfile = '$baseUrl/api/accounts/profile/';
  static const String bookings = '$baseUrl/api/bookings/';
  // 🆕 ADD: Address endpoint
  static const String addresses = '$baseUrl/api/locations/addresses/';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userMobileKey = 'user_mobile';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
}

class AppColors {
  static const primaryColor = Color(0xFF1976D2);
  static const primaryDark = Color(0xFF1565C0);
  static const accent = Color(0xFF2196F3);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const background = Color(0xFFF5F5F5);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFFE0E0E0);
}

class AppStrings {
  static const appName = 'Auto Care';
  static const loginTitle = 'Welcome Back';
  static const loginSubtitle = 'Enter your mobile number to continue';
  static const otpTitle = 'Verify OTP';
  static const otpSubtitle = 'Enter the 6-digit code sent to';
  static const homeTitle = 'Book Service';
  static const bookingsTitle = 'My Bookings';
  static const profileTitle = 'My Profile';
}
