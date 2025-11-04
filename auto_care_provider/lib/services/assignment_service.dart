// lib/services/assignment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/assignment_model.dart';
import '../services/auth_service.dart';

class AssignmentService {
  static const String baseUrl = 'http://10.175.158.214:8000/api';

  /// ✅ Helper for headers
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService().getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// ✅ Fetch all pending assignments for the provider
  Future<List<AssignmentModel>> getPendingAssignments() async {
    final token = await AuthService().getAccessToken();

    if (token == null || token.isEmpty) {
      print('❌ No access token available');
      throw Exception('Unauthorized: Missing token');
    }

    final uri = Uri.parse('$baseUrl/assignments/pending/');
    print('📡 Fetching pending assignments from: $uri');

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    print('📡 Pending assignments response: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return body.map((json) => AssignmentModel.fromJson(json)).toList();
      } else if (body is Map && body['assignments'] is List) {
        return (body['assignments'] as List)
            .map((json) => AssignmentModel.fromJson(json))
            .toList();
      } else {
        print('⚠️ Unexpected response format: $body');
        return [];
      }
    } else if (response.statusCode == 401) {
      print('❌ Unauthorized: Token expired or invalid');
      throw Exception('Unauthorized: Token expired');
    } else {
      print('❌ Failed to load assignments: ${response.statusCode}');
      throw Exception('Failed to load assignments');
    }
  }

  Future<List<AssignmentModel>> getActiveAssignments() async {
    final token = await AuthService().getAccessToken();

    if (token == null || token.isEmpty) {
      print('❌ No access token available');
      throw Exception('Unauthorized: Missing token');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/assignments/active/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return body.map((json) => AssignmentModel.fromJson(json)).toList();
      } else if (body is Map && body['assignments'] is List) {
        return (body['assignments'] as List)
            .map((json) => AssignmentModel.fromJson(json))
            .toList();
      } else {
        print('⚠️ Unexpected response format: $body');
        return [];
      }
    } else if (response.statusCode == 401) {
      print('❌ Unauthorized: Token expired or invalid');
      throw Exception('Unauthorized: Token expired');
    } else {
      print('❌ Failed to fetch active assignments: ${response.statusCode}');
      throw Exception('Failed to fetch active assignments');
    }
  }

  /// ✅ Fetch bookings assigned to this provider
  static Future<List<AssignmentModel>> getProviderAssignments() async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null || token.isEmpty) {
        print('❌ No token found');
        throw Exception('Unauthorized: Missing token');
      }

      final url = Uri.parse('$baseUrl/bookings/assignments/pending/');
      print('📡 Fetching provider assignments from: $url');

      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      print('📦 Response status: ${res.statusCode}');
      print('📦 Body: ${res.body}');

      if (res.statusCode == 200) {
        final body = json.decode(res.body);

        if (body is List) {
          return body.map((json) => AssignmentModel.fromJson(json)).toList();
        } else if (body is Map && body['assignments'] is List) {
          return (body['assignments'] as List)
              .map((json) => AssignmentModel.fromJson(json))
              .toList();
        } else if (body['results'] is List) {
          return (body['results'] as List)
              .map((json) => AssignmentModel.fromJson(json))
              .toList();
        } else {
          print('⚠️ Unexpected response format: $body');
          return [];
        }
      } else {
        print('❌ Failed: ${res.statusCode} - ${res.reasonPhrase}');
        throw Exception('Failed to load provider assignments');
      }
    } catch (e) {
      print('🔥 Exception in getProviderAssignments: $e');
      throw Exception('Error fetching provider assignments: $e');
    }
  }

  /// ✅ Accept booking
  static Future<bool> acceptAssignment(int id) async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null || token.isEmpty) return false;

      final res = await http.post(
        Uri.parse('$baseUrl/bookings/assignments/$id/accept/'),
        headers: await _headers(),
      );

      print('📩 Accept response: ${res.statusCode} - ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('❌ Accept assignment error: $e');
      return false;
    }
  }

  /// ✅ Reject booking
  static Future<bool> rejectAssignment(int id, String reason) async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null || token.isEmpty) return false;

      final res = await http.post(
        Uri.parse('$baseUrl/bookings/assignments/$id/reject/'),
        headers: await _headers(),
        body: json.encode({'reason': reason}),
      );

      print('📩 Reject response: ${res.statusCode} - ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('❌ Reject assignment error: $e');
      return false;
    }
  }
}
