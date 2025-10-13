import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({Key? key, required this.booking})
    : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isLoading = false;

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await ApiService.cancelBooking(widget.booking.id!);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel booking'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking #${widget.booking.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Details Card
            _buildDetailsCard(),
            const SizedBox(height: 16),

            // Timeline (if you want to show booking progress)
            _buildTimelineCard(),
            const SizedBox(height: 24),

            // Action Buttons
            if (widget.booking.canBeCancelled()) ...[
              CustomButton(
                text: 'Cancel Booking',
                onPressed: _cancelBooking,
                isLoading: _isLoading,
                backgroundColor: AppColors.error,
                icon: Icons.cancel,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.booking.getStatusColor(),
            widget.booking.getStatusColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: widget.booking.getStatusColor().withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            widget.booking.getStatusIcon(),
            size: 60,
            color: AppColors.white,
          ),
          const SizedBox(height: 12),
          Text(
            widget.booking.status.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getStatusMessage(),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.directions_car,
            'Vehicle Type',
            widget.booking.vehicleType.toUpperCase(),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.calendar_today,
            'Service Date',
            widget.booking.getFormattedDate(),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.access_time,
            'Time Slot',
            widget.booking.timeSlot,
          ),
          if (widget.booking.userName != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.person,
              'Customer Name',
              widget.booking.userName!,
            ),
          ],
          if (widget.booking.userMobile != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.phone,
              'Contact Number',
              widget.booking.userMobile!,
            ),
          ],
          if (widget.booking.notes != null &&
              widget.booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.note_outlined,
              'Special Instructions',
              widget.booking.notes!,
            ),
          ],
          if (widget.booking.createdAt != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.schedule,
              'Booked On',
              widget.booking.getFormattedDate(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            'Booking Confirmed',
            'Your booking has been received',
            true,
          ),
          _buildTimelineItem(
            'Provider Assigned',
            'A service provider will be assigned soon',
            widget.booking.status != 'pending',
          ),
          _buildTimelineItem(
            'Service In Progress',
            'Provider will arrive at scheduled time',
            widget.booking.status == 'in_progress' ||
                widget.booking.status == 'completed',
          ),
          _buildTimelineItem(
            'Service Completed',
            'Rate your experience',
            widget.booking.status == 'completed',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    bool isCompleted, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : AppColors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  color: AppColors.white,
                  size: isCompleted ? 18 : 8,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? AppColors.success
                    : AppColors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusMessage() {
    switch (widget.booking.status.toLowerCase()) {
      case 'pending':
        return 'We are processing your booking';
      case 'confirmed':
        return 'Your booking has been confirmed';
      case 'in_progress':
        return 'Service provider is on the way';
      case 'completed':
        return 'Service completed successfully';
      case 'cancelled':
        return 'This booking has been cancelled';
      default:
        return '';
    }
  }
}
