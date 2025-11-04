import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'accepted':
      case 'in_progress':
        color = Colors.green;
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: Colors.white)),
    );
  }
}
