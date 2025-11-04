import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/assignment_provider.dart';
import '../../models/assignment_model.dart';
import 'job_detail_screen.dart';

class ActiveServiceScreen extends StatefulWidget {
  final AssignmentModel? assignment;

  const ActiveServiceScreen({this.assignment, Key? key}) : super(key: key);

  @override
  _ActiveServiceScreenState createState() => _ActiveServiceScreenState();
}

class _ActiveServiceScreenState extends State<ActiveServiceScreen> {
  late AssignmentModel _assignment;
  Timer? _locationTimer;
  bool _isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    Provider.of<AssignmentProvider>(
      context,
      listen: false,
    ).fetchActiveJobs(); // Make sure your provider has this method
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Active Services")),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, _) {
          final activeJobs =
              provider.activeJobs; // Should be defined in provider

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (activeJobs.isEmpty) {
            return const Center(child: Text("No active jobs"));
          }

          return ListView.builder(
            itemCount: activeJobs.length,
            itemBuilder: (context, index) {
              final assignment = activeJobs[index];
              final title =
                  assignment.bookingDetails['job_title'] ?? 'No Title';
              final description =
                  assignment.bookingDetails['description'] ?? 'No Description';

              return ListTile(
                title: Text(title),
                subtitle: Text(description),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(assignment: assignment),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
