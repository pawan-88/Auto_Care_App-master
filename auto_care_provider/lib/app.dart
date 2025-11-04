import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/jobs/assignments_screen.dart';
import 'providers/assignment_provider.dart';
import 'screens/auth/provider_login_screen.dart';
import 'screens/auth/provider_registration_screen.dart';
import 'screens/auth/provider_otp_screen.dart';
import 'screens/dashboard/provider_home_screen.dart';
import 'screens/jobs/available_jobs_screen.dart';
import 'screens/jobs/job_detail_screen.dart';
import 'screens/profile/provider_profile_screen.dart';

// Alias import to avoid name conflict
import 'screens/jobs/active_service_screen.dart' as active;

class AutoCareProviderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AssignmentProvider(),
      child: MaterialApp(
        title: 'AutoCare Provider',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/login', // Start from login screen
        routes: {
          '/login': (context) => ProviderLoginScreen(),
          '/register': (context) => ProviderRegistrationScreen(),
          '/otp': (context) => ProviderOtpScreen(),
          '/home': (context) => ProviderHomeScreen(),
          '/jobs': (context) => AvailableJobsScreen(),
          '/profile': (context) => ProviderProfileScreen(),
          '/assignments': (context) => AssignmentsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/job_detail') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => JobDetailScreen(assignment: args['assignment']),
            );
          } else if (settings.name == '/active_service') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) =>
                  active.ActiveServiceScreen(assignment: args['assignment']),
            );
          }
          return null;
        },
      ),
    );
  }
}
