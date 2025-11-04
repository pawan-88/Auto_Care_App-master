import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/assignment_model.dart';

class AssignmentProvider with ChangeNotifier {
  bool _isLoading = false;

  // Available and active jobs
  List<AssignmentModel> _availableJobs = [];
  List<AssignmentModel> _activeJobs = [];

  bool get isLoading => _isLoading;
  List<AssignmentModel> get availableJobs => _availableJobs;
  List<AssignmentModel> get activeJobs => _activeJobs;

  /// Fetch available jobs from API
  Future<void> fetchAvailableJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        'http://10.207.63.214:8000/api/provider/active-assignment/',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _availableJobs =
            data.map((json) => AssignmentModel.fromJson(json)).toList();
      } else {
        if (kDebugMode) print('Failed to fetch jobs: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching jobs: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch active jobs (jobs with status ACTIVE)
  Future<void> fetchActiveJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      // For demo, we just filter availableJobs for active jobs
      // In real API, you might have a separate endpoint
      _activeJobs = _availableJobs
          .where((job) => job.status.toUpperCase() == 'ACTIVE')
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching active jobs: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Accept a job (update its status)
  Future<void> acceptJob(String jobId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mark as inactive (remove from active jobs)
      _availableJobs.removeWhere((job) => job.id == jobId);
      _activeJobs.removeWhere((job) => job.id == jobId);

      if (kDebugMode) print('Job $jobId accepted.');
    } catch (e) {
      if (kDebugMode) print('Error accepting job: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
