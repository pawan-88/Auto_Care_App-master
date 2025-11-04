// lib/widgets/assignment_card.dart
import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const AssignmentCard({
    Key? key,
    required this.assignment,
    this.onAccept,
    this.onReject,
    this.onTap,
  }) : super(key: key);

  void _openMaps() async {
    if (assignment.latitude == null || assignment.longitude == null) return;
    final lat = assignment.latitude!;
    final lng = assignment.longitude!;
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = assignment.getStatusDisplay();
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${assignment.vehicleType.toUpperCase()} • ${assignment.getFormattedDate()}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Time: ${assignment.timeSlot}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          '${assignment.customerName} • ${assignment.customerMobile}')),
                ],
              ),
              const SizedBox(height: 8),
              if (assignment.latitude != null && assignment.longitude != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Location: ${assignment.latitude!.toStringAsFixed(5)}, ${assignment.longitude!.toStringAsFixed(5)}')),
                    IconButton(
                        onPressed: _openMaps, icon: const Icon(Icons.map)),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  if (onReject != null) const SizedBox(width: 12),
                  if (onAccept != null)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check),
                        label: const Text('Accept Job'),
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
}
