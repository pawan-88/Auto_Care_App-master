import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _auth = AuthService();

  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final token = await _auth.getAccessToken();
    return http.post(
      Uri.parse(url),
      headers: {
        ...Constants.jsonHeaders,
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(String url) async {
    final token = await _auth.getAccessToken();
    return http.get(
      Uri.parse(url),
      headers: {
        ...Constants.jsonHeaders,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
