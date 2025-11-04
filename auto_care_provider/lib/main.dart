import 'package:flutter/material.dart';
import 'screens/auth/provider_login_screen.dart';
import 'screens/auth/provider_otp_screen.dart';
import 'screens/auth/provider_registration_screen.dart';
import 'screens/dashboard/provider_home_screen.dart';
import 'screens/jobs/available_jobs_screen.dart';
import 'services/notification_service.dart';
import 'screens/jobs/assignments_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Care Provider',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => ProviderLoginScreen(),
        '/register': (context) => ProviderRegistrationScreen(),
        '/otp': (context) => ProviderOtpScreen(),
        '/home': (context) => ProviderHomeScreen(),
        '/jobs': (context) => AvailableJobsScreen(),
        '/assignments': (context) => AssignmentsScreen(),
      },
    );
  }
}
