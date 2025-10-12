import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/booking.dart';
import '../models/address.dart';
import '../utils/constants.dart';
import 'dart:io';
import 'dart:async';

class ApiService {
  // ---------------------------------------------------
  // Send OTP (Keep existing implementation)
  // ---------------------------------------------------
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');

      print('🔵 Sending OTP to: $cleanMobile');
      print('🔵 API URL: ${ApiConstants.sendOtp}');

      final response = await http
          .post(
            Uri.parse(ApiConstants.sendOtp),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobile_number': cleanMobile}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Connection timeout');
            },
          );

      print('🔵 Status Code: ${response.statusCode}');
      print('🔵 Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ OTP Sent Successfully');
        return data;
      } else if (response.statusCode == 429) {
        return {'error': data['error'] ?? 'Too many requests'};
      } else {
        return {'error': data['error'] ?? 'Failed to send OTP'};
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      return {'error': 'Connection timeout. Check backend connection.'};
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      return {'error': 'Cannot connect to server. Check backend status.'};
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // ---------------------------------------------------
  // Verify OTP (Keep existing implementation)
  // ---------------------------------------------------
  static Future<Map<String, dynamic>> verifyOtp(
    String mobile,
    String otp,
  ) async {
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');

      print('🔵 Verifying OTP: $otp for mobile: $cleanMobile');

      final response = await http.post(
        Uri.parse(ApiConstants.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_number': cleanMobile, 'otp': otp}),
      );

      print('🔵 Verify OTP Status: ${response.statusCode}');
      print('🔵 Verify OTP Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save tokens
        await User.saveTokens(
          accessToken: data['access'],
          refreshToken: data['refresh'],
        );

        // Save user data if available
        if (data['user'] != null) {
          final user = User.fromJson(data['user']);
          await User.saveUserData(user);
        }

        print('✅ OTP Verified Successfully');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['error'] ?? 'OTP verification failed'};
      }
    } catch (e) {
      print('❌ Verify OTP Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // ---------------------------------------------------
  // Refresh Access Token
  // ---------------------------------------------------
  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await User.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse(ApiConstants.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        final newRefreshToken = data['refresh'];

        await User.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        return newAccessToken;
      }

      return null;
    } catch (e) {
      print('❌ Refresh Token Error: $e');
      return null;
    }
  }

  // ---------------------------------------------------
  // Authenticated Request Helper
  // ---------------------------------------------------
  static Future<http.Response> _authenticatedRequest({
    required String method,
    required String url,
    Map<String, dynamic>? body,
  }) async {
    String? token = await User.getAccessToken();

    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    Future<http.Response> makeRequest(String t) {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      };

      switch (method.toUpperCase()) {
        case 'GET':
          return http.get(Uri.parse(url), headers: headers);
        case 'POST':
          return http.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'PUT':
          return http.put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'DELETE':
          return http.delete(Uri.parse(url), headers: headers);
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    }

    var response = await makeRequest(token);

    // If unauthorized, try refreshing token
    if (response.statusCode == 401) {
      final newToken = await refreshAccessToken();
      if (newToken != null) {
        response = await makeRequest(newToken);
      }
    }

    return response;
  }

  // ---------------------------------------------------
  // Get User Profile
  // ---------------------------------------------------
  static Future<User?> getUserProfile() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        url: ApiConstants.userProfile,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data);
        await User.saveUserData(user);
        return user;
      }

      return null;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // ---------------------------------------------------
  // Create Booking with Location Support
  // ---------------------------------------------------
  static Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    try {
      // 🔧 FIX: Ensure proper date format
      if (bookingData['date'] is DateTime) {
        bookingData['date'] = (bookingData['date'] as DateTime)
            .toIso8601String()
            .split('T')[0]; // Keep only YYYY-MM-DD
      } else if (bookingData['date'] is List) {
        // Fix if date comes as array
        bookingData['date'] = bookingData['date'][0];
      }

      // 🔧 FIX: Round GPS coordinates to 6 decimal places
      if (bookingData['latitude'] is double) {
        bookingData['latitude'] = double.parse(
          (bookingData['latitude'] as double).toStringAsFixed(6),
        );
      }
      if (bookingData['longitude'] is double) {
        bookingData['longitude'] = double.parse(
          (bookingData['longitude'] as double).toStringAsFixed(6),
        );
      }

      // 🔍 DEBUG: Print what we're sending
      print('🔵 Creating booking with location data:');
      print(jsonEncode(bookingData));

      final response = await _authenticatedRequest(
        method: 'POST',
        url: ApiConstants.bookings,
        body: bookingData,
      );

      // 🔍 DEBUG: Print response
      print('🔵 Create Booking Status: ${response.statusCode}');
      print('🔵 Create Booking Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Booking Created Successfully');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ Booking Creation Failed: $errorData');
        return {'error': errorData.toString()};
      }
    } catch (e) {
      print('❌ Create Booking Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // ---------------------------------------------------
  // Get User Addresses (FIX ADDRESS LIST ERROR)
  // ---------------------------------------------------
  static Future<List<Map<String, dynamic>>> getAddresses() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        url: ApiConstants.addresses, // Make sure this exists in constants
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        // 🔧 FIX: Handle different response formats
        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map && responseData.containsKey('results')) {
          // If paginated response
          return List<Map<String, dynamic>>.from(responseData['results']);
        } else {
          print('❌ Unexpected address response format: $responseData');
          return [];
        }
      } else {
        print('❌ Get addresses failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting addresses: $e');
      return [];
    }
  }

  // ---------------------------------------------------
  // Location/Address Related APIs (NEW)
  // ---------------------------------------------------

  // Get User Addresses
  static Future<List<AddressModel>> getUserAddresses() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        url: '${ApiConstants.baseUrl}/api/locations/addresses/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AddressModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error getting addresses: $e');
      return [];
    }
  }

  // Create Address
  static Future<AddressModel?> createAddress(
    Map<String, dynamic> addressData,
  ) async {
    try {
      print('🔵 Creating address: ${jsonEncode(addressData)}');

      final response = await _authenticatedRequest(
        method: 'POST',
        url: '${ApiConstants.baseUrl}/api/locations/addresses/',
        body: addressData,
      );

      print('🔵 Create Address Status: ${response.statusCode}');
      print('🔵 Create Address Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Address Created Successfully');
        return AddressModel.fromJson(data);
      }

      return null;
    } catch (e) {
      print('❌ Create Address Error: $e');
      return null;
    }
  }

  // Update Address
  static Future<AddressModel?> updateAddress(
    int addressId,
    Map<String, dynamic> addressData,
  ) async {
    try {
      final response = await _authenticatedRequest(
        method: 'PUT',
        url: '${ApiConstants.baseUrl}/api/locations/addresses/$addressId/',
        body: addressData,
      );

      if (response.statusCode == 200) {
        return AddressModel.fromJson(jsonDecode(response.body));
      }

      return null;
    } catch (e) {
      print('Error updating address: $e');
      return null;
    }
  }

  // Delete Address
  static Future<bool> deleteAddress(int addressId) async {
    try {
      final response = await _authenticatedRequest(
        method: 'DELETE',
        url: '${ApiConstants.baseUrl}/api/locations/addresses/$addressId/',
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  // ---------------------------------------------------
  // Get Available Time Slots (Enhanced)
  // ---------------------------------------------------
  static Future<List<String>> getAvailableTimeSlots(String date) async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        url: '${ApiConstants.baseUrl}/api/bookings/available-slots/?date=$date',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['available_slots'] as List<dynamic>).cast<String>();
      }

      // Fallback to default time slots
      return _getDefaultTimeSlots();
    } catch (e) {
      print('Error getting available slots: $e');
      // Return default time slots
      return _getDefaultTimeSlots();
    }
  }

  static List<String> _getDefaultTimeSlots() {
    return [
      "05:00 AM",
      "06:00 AM",
      "07:00 AM",
      "08:00 AM",
      "09:00 AM",
      "10:00 AM",
      "11:00 AM",
      "12:00 PM",
      "01:00 PM",
      "02:00 PM",
      "03:00 PM",
      "04:00 PM",
      "05:00 PM",
      "06:00 PM",
      "07:00 PM",
      "08:00 PM",
    ];
  }

  // ---------------------------------------------------
  // Service Areas Check (NEW)
  // ---------------------------------------------------
  static Future<bool> checkServiceAvailability(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        url: '${ApiConstants.baseUrl}/api/locations/check-service-area/',
        body: {'latitude': latitude, 'longitude': longitude},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['service_available'] ?? true;
      }

      // Default to true if endpoint doesn't exist
      return true;
    } catch (e) {
      print('Service availability check error: $e');
      // Default to true if there's an error
      return true;
    }
  }

  // ---------------------------------------------------
  // Reverse Geocoding (NEW)
  // ---------------------------------------------------
  static Future<String?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        url: '${ApiConstants.baseUrl}/api/locations/reverse-geocode/',
        body: {'latitude': latitude, 'longitude': longitude},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['address'];
      }

      return null;
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }

  // ---------------------------------------------------
  // Logout
  // ---------------------------------------------------
  static Future<void> logout() async {
    try {
      // Optional: Call backend logout endpoint
      await _authenticatedRequest(
        method: 'POST',
        url: '${ApiConstants.baseUrl}/api/auth/logout/',
      );
    } catch (e) {
      print('Logout API error (non-critical): $e');
    } finally {
      // Always clear local data
      await User.clearData();
    }
  }
}
