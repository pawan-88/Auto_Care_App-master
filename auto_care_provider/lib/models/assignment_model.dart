// lib/models/assignment_model.dart
class AssignmentModel {
  final int id;
  final int bookingId;
  final String status;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? estimatedArrivalTime;
  final String? providerNotes;

  // Customer details
  final String customerName;
  final String customerMobile;

  // Booking details
  final String vehicleType;
  final String serviceDate;
  final String timeSlot;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final String? serviceAddress;

  AssignmentModel({
    required this.id,
    required this.bookingId,
    required this.status,
    this.assignedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.estimatedArrivalTime,
    this.providerNotes,
    required this.customerName,
    required this.customerMobile,
    required this.vehicleType,
    required this.serviceDate,
    required this.timeSlot,
    this.notes,
    this.latitude,
    this.longitude,
    this.serviceAddress,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    // Many APIs wrap booking info under 'booking_details' or return booking object.
    final bookingDetails = json['booking_details'] ??
        (json['booking'] is Map ? json['booking'] : null) ??
        {};

    String parseString(dynamic s) {
      if (s == null) return '';
      return s.toString();
    }

    double? parseDouble(dynamic d) {
      if (d == null) return null;
      if (d is double) return d;
      if (d is int) return d.toDouble();
      try {
        return double.tryParse(d.toString());
      } catch (_) {
        return null;
      }
    }

    DateTime? parseDateTime(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return AssignmentModel(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(parseString(json['id'])) ?? 0,
      bookingId: (json['booking'] is int)
          ? json['booking'] as int
          : int.tryParse(parseString(json['booking'])) ??
              (bookingDetails is Map && bookingDetails['id'] != null
                  ? int.tryParse(parseString(bookingDetails['id'])) ?? 0
                  : 0),
      status: parseString(json['status'] ?? 'assigned'),
      assignedAt: parseDateTime(json['assigned_at']),
      acceptedAt: parseDateTime(json['accepted_at']),
      startedAt: parseDateTime(json['started_at']),
      completedAt: parseDateTime(json['completed_at']),
      estimatedArrivalTime: parseDateTime(json['estimated_arrival_time']),
      providerNotes: json['provider_notes'] != null
          ? parseString(json['provider_notes'])
          : null,
      customerName: json['customer_name'] != null
          ? parseString(json['customer_name'])
          : (bookingDetails is Map && bookingDetails['user_name'] != null)
              ? parseString(bookingDetails['user_name'])
              : '',
      customerMobile: json['customer_mobile'] != null
          ? parseString(json['customer_mobile'])
          : (bookingDetails is Map && bookingDetails['user_mobile'] != null)
              ? parseString(bookingDetails['user_mobile'])
              : '',
      vehicleType: bookingDetails != null
          ? parseString(bookingDetails['vehicle_type'] ?? '')
          : '',
      serviceDate: bookingDetails != null
          ? parseString(bookingDetails['date'] ?? '')
          : '',
      timeSlot: bookingDetails != null
          ? parseString(bookingDetails['time_slot'] ?? '')
          : '',
      notes: bookingDetails != null
          ? (bookingDetails['notes'] != null
              ? parseString(bookingDetails['notes'])
              : null)
          : null,
      latitude: bookingDetails != null
          ? parseDouble(bookingDetails['latitude'])
          : null,
      longitude: bookingDetails != null
          ? parseDouble(bookingDetails['longitude'])
          : null,
      serviceAddress: bookingDetails != null
          ? (bookingDetails['service_address'] != null
              ? parseString(bookingDetails['service_address'])
              : null)
          : null,
    );
  }

  String getStatusDisplay() {
    switch (status) {
      case 'assigned':
        return 'New Request';
      case 'accepted':
        return 'Accepted';
      case 'en_route':
        return 'On The Way';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String getDistanceDisplay(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  String getFormattedDate() {
    try {
      final date = DateTime.parse(serviceDate);
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
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return serviceDate;
    }
  }

  String getETA() {
    if (estimatedArrivalTime == null) return 'Calculating...';
    final now = DateTime.now();
    final difference = estimatedArrivalTime!.difference(now);
    if (difference.isNegative) return 'Arrive now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins';
    }
    return '${difference.inHours}h ${difference.inMinutes % 60}m';
  }
}
