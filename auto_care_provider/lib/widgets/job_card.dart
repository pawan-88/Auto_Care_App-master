import 'package:flutter/material.dart';
import '../models/assignment_model.dart';

class JobCard extends StatelessWidget {
  final ServiceAssignment assignment;
  final VoidCallback onTap;
  JobCard({required this.assignment, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Booking #${assignment.bookingDetails['id']}'),
        subtitle: Text('Customer: ${assignment.customerName}'),
        trailing: Text(assignment.status),
        onTap: onTap,
      ),
    );
  }
}
