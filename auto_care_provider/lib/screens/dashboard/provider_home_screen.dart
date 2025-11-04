import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../config/constants.dart';
import '../../widgets/custom_button.dart';
import 'package:http/http.dart' as http;

class ProviderHomeScreen extends StatefulWidget {
  @override
  _ProviderHomeScreenState createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  bool _isAvailable = false;
  int _completedJobs = 0;
  double _rating = 0.0;
  String _providerName = 'Provider';
  String _employeeId = '';
  Timer? _locationTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
    _fetchProfile();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  // ✅ Load provider data from storage
  Future<void> _loadProviderData() async {
    final providerData = await AuthService().getProviderData();
    setState(() {
      _providerName = providerData['full_name'] ?? 'Provider';
      _employeeId = providerData['employee_id'] ?? '';
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService().get(Constants.providerProfile);

      if (res.statusCode == 200) {
        final dataString = res.body.isNotEmpty ? res.body : '{}';
        final Map<String, dynamic> jsonMap = jsonDecode(dataString);

        // ✅ Safe parsing for all fields
        setState(() {
          _isAvailable = jsonMap['is_available'] as bool? ?? false;
          _completedJobs = jsonMap['total_jobs_completed'] as int? ?? 0;

          // ✅ Handle rating as String or num
          final ratingValue = jsonMap['rating'];
          if (ratingValue is String) {
            _rating = double.tryParse(ratingValue) ?? 0.0;
          } else if (ratingValue is num) {
            _rating = ratingValue.toDouble();
          } else {
            _rating = 0.0;
          }

          _isLoading = false;
        });

        print('✅ Profile loaded successfully');
        print('   Completed Jobs: $_completedJobs');
        print('   Rating: $_rating');
        print('   Available: $_isAvailable');
      } else {
        setState(() => _isLoading = false);
        print('❌ Failed to fetch profile: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error fetching profile: $e');

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      final res = await ApiService().post(Constants.toggleAvailability, {});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _isAvailable = data['is_available'] ?? !_isAvailable;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isAvailable
                  ? 'You are now available for jobs'
                  : 'You are now offline',
            ),
            backgroundColor: _isAvailable ? Colors.green : Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        print('✅ Availability toggled: $_isAvailable');
      }
    } catch (e) {
      print('❌ Error toggling availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update availability'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startLocationUpdates() {
    print('🔄 Starting location updates...');

    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _updateProviderLocation();
    });

    // Update immediately on start
    _updateProviderLocation();
  }

// Add this new method
  Future<void> _updateProviderLocation() async {
    try {
      final pos = await LocationService().getCurrentLocation();

      print('\n📍 Updating provider location...');
      print('   Latitude: ${pos.latitude}');
      print('   Longitude: ${pos.longitude}');

      final token = await AuthService().getAccessToken();
      if (token == null) {
        print('❌ No access token available');
        throw Exception('Unauthorized: Missing token');
      }

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/providers/location/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        }),
      );

      print('📡 Location update response: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Location updated successfully\n');
      } else {
        print('❌ Location update failed: ${response.statusCode}');
        print('   Error: ${response.body}\n');
      }
    } catch (e) {
      print('❌ Location update error: $e\n');
    }
  }

  // ✅ Improved logout with confirmation
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Cancel location updates
        _locationTimer?.cancel();

        // Logout
        await AuthService().logout();

        print('✅ User logged out successfully');

        // Navigate to login
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (_) => false,
        );
      } catch (e) {
        print('❌ Logout error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProfile,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Provider Info Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    _providerName.isNotEmpty
                                        ? _providerName[0].toUpperCase()
                                        : 'P',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _providerName,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'ID: $_employeeId',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Availability Toggle
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isAvailable
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color:
                                      _isAvailable ? Colors.green : Colors.grey,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Availability Status',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isAvailable,
                              onChanged: (_) => _toggleAvailability(),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 2,
                            color: Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 40, color: Colors.blue),
                                  SizedBox(height: 8),
                                  Text(
                                    '$_completedJobs',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Jobs Completed',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 2,
                            color: Colors.orange[50],
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.star,
                                      size: 40, color: Colors.orange),
                                  SizedBox(height: 8),
                                  Text(
                                    _rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Rating',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ✅ Action Button
                    CustomButton(
                      label: 'View Available Jobs',
                      onPressed: () => Navigator.pushNamed(context, '/jobs'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
