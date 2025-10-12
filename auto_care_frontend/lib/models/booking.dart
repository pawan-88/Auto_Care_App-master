import 'package:flutter/material.dart';

class Booking {
  final int? id;
  final String vehicleType;
  final String date;
  final String timeSlot;
  final String status;
  final String? notes;
  final String? createdAt;
  final String? userName;
  final String? userMobile;

  Booking({
    this.id,
    required this.vehicleType,
    required this.date,
    required this.timeSlot,
    this.status = 'pending',
    this.notes,
    this.createdAt,
    this.userName,
    this.userMobile,
  });

  // From JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      vehicleType: json['vehicle_type'] ?? '',
      date: json['date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: json['created_at'],
      userName: json['user_name'],
      userMobile: json['user_mobile'],
    );
  }

  // To JSON (for creating booking)
  Map<String, dynamic> toJson() {
    return {
      'vehicle_type': vehicleType,
      'date': date,
      'time_slot': timeSlot,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  // Get status color
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange; // pending
    }
  }

  // Get status icon
  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.pending; // pending
    }
  }

  // Get formatted date
  String getFormattedDate() {
    try {
      final dateTime = DateTime.parse(date);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]}, ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  // Get vehicle icon
  IconData getVehicleIcon() {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.two_wheeler;
      default:
        return Icons.local_shipping;
    }
  }

  // Check if booking can be cancelled
  bool canBeCancelled() {
    return status.toLowerCase() == 'pending' ||
        status.toLowerCase() == 'confirmed';
  }
}
