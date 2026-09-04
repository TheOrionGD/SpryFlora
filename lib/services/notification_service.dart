import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/plant_model.dart';

/// Notification Service
/// Handles Android System Notifications & Multiplatform Due Date Alerts for Plants
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize Android & Local notification settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification click
        },
      );

      // Request notification permissions for Android 13+ (TIRAMISU)
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (_) {
      // Graceful fallback on non-supported platforms
    }
  }

  /// Sends an Android system notification for a plant whose watering is due
  Future<void> sendWateringDueNotification(PlantModel plant) async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'plant_watering_channel',
        'Plant Watering Reminders',
        channelDescription: 'Notifications sent when a plant is due or overdue for watering',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final int notificationId = plant.id.hashCode;
      final String title = '💧 Watering Due: ${plant.plantName}';
      final String body =
          'Your ${plant.speciesName} needs water today! Regular interval is ${plant.wateringIntervalDays} days.';

      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: plant.id,
      );
    } catch (_) {}
  }

  /// Reconciles notification schedules for all plants in repository
  Future<void> reconcileNotifications(List<PlantModel> plants) async {
    await initialize();
    try {
      await _notificationsPlugin.cancelAll();
      for (final plant in plants) {
        if (plant.isWateringDue) {
          await sendWateringDueNotification(plant);
        }
      }
    } catch (_) {}
  }

  /// Displays a native mobile system notification in the phone's notification center shade
  Future<void> sendSystemNotification({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'spryflora_general_channel',
        'SpryFlora Botanical Alerts',
        channelDescription: 'System notifications for plant care, diagnostics & reminders',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Notification display error: $e');
    }
  }

  /// Checks all plants and dispatches system notifications for any plant due today or overdue
  Future<void> checkAndNotifyDuePlants(List<PlantModel> plants) async {
    await reconcileNotifications(plants);
  }
}
