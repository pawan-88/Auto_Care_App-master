import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/address.dart';
import '../utils/constants.dart'; // ensure ApiConstants.bookings etc exist

class LocationService {
  // Get current GPS position (permissions handled)
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permission permanently denied. Enable from settings.",
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Fetch user addresses
  static Future<List<AddressModel>> fetchAddresses(String token) async {
    final resp = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/api/locations/addresses/"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print(
      '🔵 Fetching addresses from: ${ApiConstants.baseUrl}/api/locations/addresses/',
    );
    print('🔵 Address Response Status: ${resp.statusCode}');
    print('🔵 Address Response Body: ${resp.body}');

    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(resp.body);

      // Handle paginated response
      if (data.containsKey('results')) {
        final List results = data['results'];
        print('✅ Addresses parsed: ${results.length} addresses');
        return results.map((e) => AddressModel.fromJson(e)).toList();
      } else {
        // Handle direct array response
        final List arr = jsonDecode(resp.body);
        return arr.map((e) => AddressModel.fromJson(e)).toList();
      }
    }

    throw Exception("Failed to load addresses: ${resp.body}");
  }

  // Create address
  static Future<AddressModel> createAddress(
    String token,
    AddressModel address,
  ) async {
    final resp = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/api/locations/addresses/"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(address.toJson()),
    );
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return AddressModel.fromJson(jsonDecode(resp.body));
    }
    throw Exception("Failed to create address: ${resp.body}");
  }

  // Delete or update endpoints similar...
}
