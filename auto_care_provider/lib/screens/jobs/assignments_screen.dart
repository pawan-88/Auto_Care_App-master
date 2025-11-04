// lib/screens/assignments_screen.dart
import 'package:flutter/material.dart';
import 'package:auto_care_provider/services/assignment_service.dart';
import 'package:auto_care_provider/models/assignment_model.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AssignmentService _service = AssignmentService();

  late Future<List<AssignmentModel>> _pendingFuture;
  late Future<List<AssignmentModel>> _activeFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pendingFuture = _service.getPendingAssignments();
    _activeFuture = _service.getActiveAssignments();
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('${assignment.customerName} - ${assignment.vehicleType}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${assignment.getStatusDisplay()}'),
            if (assignment.serviceAddress != null)
              Text('Address: ${assignment.serviceAddress}'),
            if (assignment.timeSlot.isNotEmpty)
              Text('Time: ${assignment.serviceDate} | ${assignment.timeSlot}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  Widget _buildTab(Future<List<AssignmentModel>> future) {
    return FutureBuilder<List<AssignmentModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final assignments = snapshot.data ?? [];
        if (assignments.isEmpty) {
          return const Center(child: Text('No assignments found'));
        }
        return ListView.builder(
          itemCount: assignments.length,
          itemBuilder: (context, index) =>
              _buildAssignmentCard(assignments[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active/History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(_pendingFuture),
          _buildTab(_activeFuture),
        ],
      ),
    );
  }
}
