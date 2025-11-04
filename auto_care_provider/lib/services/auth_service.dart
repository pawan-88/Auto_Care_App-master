import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // ✅ Save tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    print('✅ Tokens saved successfully');
  }

  // ✅ Get access token (use secure storage)
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // ✅ Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  // ✅ Clear all tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    print('✅ Tokens cleared');
  }

  // ✅ Logout
  Future<void> logout() async {
    await clearTokens();
    print('✅ User logged out');
  }

  // ✅ Check login
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ✅ Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: 'user_id', value: userData['id'].toString());
    await _storage.write(key: 'user_name', value: userData['name']);
    await _storage.write(
      key: 'mobile_number',
      value: userData['mobile_number'],
    );
    await _storage.write(key: 'user_type', value: userData['user_type']);
    print('✅ User data saved');
  }

  // ✅ Get user data
  Future<Map<String, String?>> getUserData() async {
    return {
      'user_id': await _storage.read(key: 'user_id'),
      'user_name': await _storage.read(key: 'user_name'),
      'mobile_number': await _storage.read(key: 'mobile_number'),
      'user_type': await _storage.read(key: 'user_type'),
    };
  }

  // ✅ Save provider data
  Future<void> saveProviderData(Map<String, dynamic> providerData) async {
    await _storage.write(
        key: 'provider_id', value: providerData['id'].toString());
    await _storage.write(
        key: 'employee_id', value: providerData['employee_id']);
    await _storage.write(key: 'full_name', value: providerData['full_name']);
    await _storage.write(
        key: 'specialization', value: providerData['specialization']);
    await _storage.write(
        key: 'is_available', value: providerData['is_available'].toString());
    print('✅ Provider data saved');
  }

  // ✅ Get provider data
  Future<Map<String, String?>> getProviderData() async {
    return {
      'provider_id': await _storage.read(key: 'provider_id'),
      'employee_id': await _storage.read(key: 'employee_id'),
      'full_name': await _storage.read(key: 'full_name'),
      'specialization': await _storage.read(key: 'specialization'),
      'is_available': await _storage.read(key: 'is_available'),
    };
  }

  // ✅ Clear all
  Future<void> clearAllData() async {
    await _storage.deleteAll();
    print('✅ All data cleared');
  }
}
