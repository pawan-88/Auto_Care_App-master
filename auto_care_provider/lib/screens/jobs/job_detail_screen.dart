import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';

class JobDetailsScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const JobDetailsScreen({Key? key, required this.assignment})
      : super(key: key);

  @override
  _JobDetailsScreenState createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildCustomerSection(),
            _buildServiceSection(),
            if (widget.assignment.latitude != null &&
                widget.assignment.longitude != null)
              _buildLocationSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue, Colors.blue[700]!]),
      ),
      child: Column(
        children: [
          Icon(
            widget.assignment.vehicleType == 'car'
                ? Icons.directions_car
                : Icons.two_wheeler,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            widget.assignment.vehicleType.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Assignment #${widget.assignment.id}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return _buildSection(
      'Customer Information',
      [
        _buildDetailRow(Icons.person, 'Name', widget.assignment.customerName),
        _buildDetailRow(
          Icons.phone,
          'Phone',
          widget.assignment.customerMobile,
          trailing: IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: _callCustomer,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
    return _buildSection(
      'Service Details',
      [
        _buildDetailRow(
          Icons.calendar_today,
          'Date',
          widget.assignment.getFormattedDate(),
        ),
        _buildDetailRow(Icons.access_time, 'Time', widget.assignment.timeSlot),
        if (widget.assignment.estimatedArrivalTime != null)
          _buildDetailRow(Icons.schedule, 'ETA', widget.assignment.getETA()),
        if (widget.assignment.notes != null &&
            widget.assignment.notes!.isNotEmpty)
          _buildDetailRow(Icons.note, 'Notes', widget.assignment.notes!),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildSection(
      'Location',
      [
        _buildDetailRow(
          Icons.location_on,
          'Address',
          widget.assignment.serviceAddress ?? 'Service location',
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _openMaps,
          icon: const Icon(Icons.navigation),
          label: const Text('Navigate to Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _acceptJob,
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text('Accept This Job',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _rejectJob,
                    icon: const Icon(Icons.cancel, size: 24),
                    label: const Text('Reject',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Future<void> _acceptJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Job?'),
        content: Text(
          'You will be assigned to ${widget.assignment.customerName}. '
          'Make sure you can reach the location on time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept Job'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success =
        await AssignmentService.acceptAssignment(widget.assignment.id);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Job accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to accept job'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectJob() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _RejectDialog(),
    );

    if (reason == null) return;

    setState(() => _isLoading = true);
    final success =
        await AssignmentService.rejectAssignment(widget.assignment.id, reason);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job rejected and reassigned'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject job'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callCustomer() async {
    final Uri url = Uri.parse('tel:${widget.assignment.customerMobile}');
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  Future<void> _openMaps() async {
    final lat = widget.assignment.latitude;
    final lng = widget.assignment.longitude;
    if (lat == null || lng == null) return;

    final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url,
          mode: url_launcher.LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }
}

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => __RejectDialogState();
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
      title: const Text('Reject Job'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _reasons
            .map(
              (r) => RadioListTile<String>(
                title: Text(r),
                value: r,
                groupValue: _selectedReason,
                onChanged: (value) => setState(() => _selectedReason = value!),
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedReason),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
