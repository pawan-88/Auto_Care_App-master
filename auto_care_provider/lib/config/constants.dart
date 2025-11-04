import 'package:flutter/material.dart';

class Constants {
  static const String baseUrl = 'http://10.40.83.214:8000/api'; // Real Device

  static const String providerRegister = '$baseUrl/providers/register/';
  static const String providerLogin = '$baseUrl/providers/login/';
  static const String providerVerifyOtp = '$baseUrl/providers/verify-otp/';
  static const String providerProfile = '$baseUrl/providers/profile/';
  static const String availableJobs = '$baseUrl/providers/jobs/available/';
  static String assignmentAction(int id) =>
      '$baseUrl/providers/assignments/$id/action/';
  static String startService(int id) =>
      '$baseUrl/providers/assignments/$id/start/';
  static String completeService(int id) =>
      '$baseUrl/providers/assignments/$id/complete/';
  static const String updateLocation = '$baseUrl/providers/location/update/';
  static const String toggleAvailability =
      '$baseUrl/providers/availability/toggle/';
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };
}
