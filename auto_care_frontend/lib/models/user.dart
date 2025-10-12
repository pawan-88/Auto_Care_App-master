import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class User {
  final String mobileNumber;
  final String? name;
  final String? email;
  final String? address;
  final String? vehicle;

  User({
    required this.mobileNumber,
    this.name,
    this.email,
    this.address,
    this.vehicle,
  });

  // From JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      mobileNumber: json['mobile_number'] ?? '',
      name: json['name'],
      email: json['email'],
      address: json['address'],
      vehicle: json['vehicle'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'mobile_number': mobileNumber,
      'name': name,
      'email': email,
      'address': address,
      'vehicle': vehicle,
    };
  }

  // Save tokens to SharedPreferences
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.accessTokenKey, accessToken);
    await prefs.setString(ApiConstants.refreshTokenKey, refreshToken);
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.accessTokenKey);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.refreshTokenKey);
  }

  // Save user data
  static Future<void> saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.userMobileKey, user.mobileNumber);
    if (user.name != null) {
      await prefs.setString(ApiConstants.userNameKey, user.name!);
    }
    if (user.email != null) {
      await prefs.setString(ApiConstants.userEmailKey, user.email!);
    }
  }

  // Get user data
  static Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString(ApiConstants.userMobileKey);

    if (mobile == null) return null;

    return User(
      mobileNumber: mobile,
      name: prefs.getString(ApiConstants.userNameKey),
      email: prefs.getString(ApiConstants.userEmailKey),
    );
  }

  // Clear all data (logout)
  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Copy with method for updating user data
  User copyWith({
    String? mobileNumber,
    String? name,
    String? email,
    String? address,
    String? vehicle,
  }) {
    return User(
      mobileNumber: mobileNumber ?? this.mobileNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      vehicle: vehicle ?? this.vehicle,
    );
  }
}
