import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/assignment_service.dart';
import '../models/assignment_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;
  List<int> _notifiedAssignmentIds = [];
  Function(List<AssignmentModel>)? onNewAssignments;

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    print('✅ Notification service initialized');
  }

  void startPolling() {
    print('🔄 Starting assignment polling...');

    // Poll every 10 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await _checkForNewAssignments();
    });

    // Check immediately
    _checkForNewAssignments();
  }

  void stopPolling() {
    print('⏹️ Stopping assignment polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkForNewAssignments() async {
    try {
      final assignments = await AssignmentService().getPendingAssignments();

      if (assignments.isEmpty) return;

      // Find new assignments that haven't been notified yet
      final newAssignments = assignments.where((assignment) {
        return !_notifiedAssignmentIds.contains(assignment.id);
      }).toList();

      if (newAssignments.isNotEmpty) {
        print('🔔 ${newAssignments.length} new assignment(s) found!');

        // Show notification for each new assignment
        for (var assignment in newAssignments) {
          await _showNotification(assignment);
          _notifiedAssignmentIds.add(assignment.id);
        }

        // Callback to update UI
        if (onNewAssignments != null) {
          onNewAssignments!(newAssignments);
        }
      }
    } catch (e) {
      print('❌ Error checking for assignments: $e');
    }
  }

  Future<void> _showNotification(AssignmentModel assignment) async {
    const androidDetails = AndroidNotificationDetails(
      'assignments_channel',
      'Service Assignments',
      channelDescription: 'Notifications for new service assignments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      assignment.id,
      '🚗 New Service Request!',
      '${assignment.customerName} - ${assignment.vehicleType.toUpperCase()} - ${assignment.getDistanceDisplay(5)}',
      notificationDetails,
    );

    print('🔔 Notification shown for assignment ${assignment.id}');
  }

  void clearNotifiedAssignments() {
    _notifiedAssignmentIds.clear();
  }

  void dispose() {
    stopPolling();
  }
}
