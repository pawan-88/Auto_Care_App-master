import 'package:flutter/material.dart';

class ApiConstants {
  // ⚠️ IMPORTANT: Change based on your setup
  // For Android Emulator: use 10.0.2.2:8000
  // For iOS Simulator: use 127.0.0.1:8000
  // For Real Device: use your computer's IP (e.g., 192.168.1.100:8000)

  //static const String baseUrl = 'http://10.240.95.214:8000'; // Android Emulator
  // static const String baseUrl = 'http://127.0.0.1:8000'; // iOS Simulator
  static const String baseUrl = 'http://10.219.56.214:8000'; // Real Device

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
  // Primary Colors
  static const primaryColor = Color(0xFF1976D2);
  static const primaryDark = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const accent = Color(0xFF2196F3);

  // Status Colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  // Text Colors
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFF9E9E9E);

  // Background Colors
  static const background = Color(0xFFF5F7FA);
  static const cardBackground = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE0E0E0);

  // Gradient Colors
  static const gradientStart = Color(0xFF1976D2);
  static const gradientEnd = Color(0xFF2196F3);

  // Other
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const grey = Color(0xFF9E9E9E);
  static const lightGrey = Color(0xFFF5F5F5);
}

class AppStrings {
  // App
  static const appName = 'Auto Care';
  static const appTagline = 'Your Car, Our Care';

  // Auth
  static const loginTitle = 'Welcome Back';
  static const loginSubtitle = 'Enter your mobile number to continue';
  static const otpTitle = 'Verify OTP';
  static const otpSubtitle = 'Enter the 6-digit code sent to';

  // Bottom Nav
  static const home = 'Home';
  static const wash = 'Wash';
  static const profile = 'Profile';

  // Home
  static const welcomeBack = 'Welcome Back';
  static const quickActions = 'Quick Actions';
  static const ourServices = 'Our Services';
  static const recentBookings = 'Recent Bookings';
  static const viewAll = 'View All';

  // Booking
  static const bookService = 'Book Service';
  static const selectVehicle = 'Select Your Vehicle';
  static const selectService = 'Select Service';
  static const selectDateTime = 'Select Date & Time';
  static const bookingSummary = 'Booking Summary';
  static const confirmBooking = 'Confirm Booking';

  // Profile
  static const myProfile = 'My Profile';
  static const editProfile = 'Edit Profile';
  static const savedAddresses = 'Saved Addresses';
  static const myVehicles = 'My Vehicles';
  static const myBookings = 'My Bookings';
  static const settings = 'Settings';
  static const logout = 'Logout';

  static const homeTitle = 'Book Service';
  static const bookingsTitle = 'My Bookings';
  static const profileTitle = 'My Profile';
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 24.0;

  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}

class ServiceTypes {
  static const carWash = 'car_wash';
  static const bikeWash = 'bike_wash';
  static const carDetailing = 'car_detailing';
  static const bikeDetailing = 'bike_detailing';
}

class VehicleTypes {
  static const car = 'car';
  static const bike = 'bike';
}

class BookingStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
}
