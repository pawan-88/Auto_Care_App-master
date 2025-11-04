import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import '../../services/notification_service.dart';
import 'job_detail_screen.dart';

class AvailableJobsScreen extends StatefulWidget {
  @override
  _AvailableJobsScreenState createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen> {
  List<AssignmentModel> _assignments = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _startAutoRefresh();

    // Listen for new assignments from notification service
    NotificationService().onNewAssignments = (newAssignments) {
      if (mounted) {
        setState(() {
          _assignments = newAssignments;
        });
      }
    };
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 10 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _loadAssignments(showLoading: false);
    });
  }

  Future<void> _loadAssignments({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final assignments = await AssignmentService().getPendingAssignments();

      if (mounted) {
        setState(() {
          _assignments = assignments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading assignments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Jobs'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadAssignments(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAssignments,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      return _buildJobCard(_assignments[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Jobs Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for new assignments',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAssignments,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(AssignmentModel assignment) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(assignment: assignment),
            ),
          ).then((_) => _loadAssignments());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      assignment.vehicleType == 'car'
                          ? Icons.directions_car
                          : Icons.two_wheeler,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.vehicleType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Assignment #${assignment.id}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              Divider(height: 24),

              // Customer Info
              _buildInfoRow(
                Icons.person,
                'Customer',
                assignment.customerName,
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                Icons.phone,
                'Phone',
                assignment.customerMobile,
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                'Date',
                assignment.getFormattedDate(),
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time,
                'Time',
                assignment.timeSlot,
              ),

              if (assignment.latitude != null &&
                  assignment.longitude != null) ...[
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.location_on,
                  'Distance',
                  assignment.getDistanceDisplay(
                      5), // Calculate actual distance in production
                  valueColor: Colors.green,
                ),
              ],

              if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.note,
                  'Notes',
                  assignment.notes!,
                ),
              ],

              SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectAssignment(assignment),
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptAssignment(assignment),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptAssignment(AssignmentModel assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Job?'),
        content: Text(
          'Accept this service request from ${assignment.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final success = await AssignmentService.acceptAssignment(assignment.id);

    Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Job accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAssignments();

      // Navigate to home or active job screen
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to accept job'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAssignment(AssignmentModel assignment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(),
    );

    if (reason == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final success = await AssignmentService.rejectAssignment(
      assignment.id,
      reason,
    );

    Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadAssignments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject job'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Reject Dialog
class _RejectDialog extends StatefulWidget {
  @override
  __RejectDialogState createState() => __RejectDialogState();
}

class __RejectDialogState extends State<_RejectDialog> {
  String _selectedReason = 'Too far away';
  final List<String> _reasons = [
    'Too far away',
    'Not available at this time',
    'Vehicle type mismatch',
    'Already have another job',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reject Job'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Please select a reason:'),
          SizedBox(height: 16),
          ..._reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() => _selectedReason = value!);
                },
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedReason),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Reject'),
        ),
      ],
    );
  }
}
