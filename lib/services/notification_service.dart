import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_model.dart';
import 'weather_service.dart';

/// Notification Service
/// Strictly provides only the 4 allowed botanical notifications:
/// 1. Plant Added
/// 2. Plant Watered
/// 3. Plant Watering Reminder (deduplicated daily to prevent cycling/spamming)
/// 4. Climate & Weather Care Alert (temperature / humidity)
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

  // -------------------------------------------------------------
  // NOTIFICATION 1: PLANT ADDED
  // -------------------------------------------------------------
  Future<void> notifyPlantAdded(PlantModel plant) async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'plant_added_channel',
        'Plant Added Alerts',
        channelDescription: 'Sent once when a new plant is added to your garden',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final int id = (plant.id.hashCode ^ 101).abs() % 100000;
      final String title = '🌱 New Plant Added: ${plant.plantName}';
      final String body =
          '${plant.speciesName} is now growing in your garden (${plant.location}). Tap to view care details!';

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: plant.id,
      );
    } catch (e) {
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        debugPrint('notifyPlantAdded error: $e');
      }
    }
  }

  // -------------------------------------------------------------
  // NOTIFICATION 2: PLANT WATERED
  // -------------------------------------------------------------
  Future<void> notifyPlantWatered(PlantModel plant) async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'plant_watered_channel',
        'Plant Watering Confirmation',
        channelDescription: 'Sent when a plant is verified and watered for the day',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final int id = (plant.id.hashCode ^ 202).abs() % 100000;
      final String title = '💧 Plant Watered: ${plant.plantName}';
      final String body =
          'Hydration verified! Your ${plant.speciesName} is happily watered today. Next watering due in ${plant.wateringIntervalDays} days.';

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: plant.id,
      );
    } catch (e) {
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        debugPrint('notifyPlantWatered error: $e');
      }
    }
  }

  // -------------------------------------------------------------
  // NOTIFICATION 3: WATERING REMINDER (Deduplicated Daily)
  // -------------------------------------------------------------
  /// Dispatches reminders ONLY for plants due today, at most once per calendar day.
  /// Eliminates the repetitive cycling notification loop on home screen visits.
  Future<void> checkAndNotifyDuePlants(List<PlantModel> plants) async {
    try {
      await initialize();
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (final plant in plants) {
        if (!plant.isWateringDue) continue;

        // Check if we already notified for this plant today
        final reminderKey = 'notified_water_reminder_${plant.id}';
        final lastNotifiedDate = prefs.getString(reminderKey);

        if (lastNotifiedDate == todayStr) {
          // Already notified today, do not cycle/spam!
          continue;
        }

        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'plant_watering_channel',
          'Plant Watering Reminders',
          channelDescription: 'Notifications sent once daily when a plant is due for watering',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        );

        const NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
        );

        final int id = (plant.id.hashCode ^ 303).abs() % 100000;
        final String title = '⏰ Watering Due: ${plant.plantName}';
        final String body =
            'Your ${plant.speciesName} is thirsty today! Regular interval is ${plant.wateringIntervalDays} days.';

        try {
          await _notificationsPlugin.show(
            id: id,
            title: title,
            body: body,
            notificationDetails: platformDetails,
            payload: plant.id,
          );
        } catch (_) {}

        // Record that we successfully sent today's reminder
        await prefs.setString(reminderKey, todayStr);
      }
    } catch (e) {
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        debugPrint('checkAndNotifyDuePlants error: $e');
      }
    }
  }

  // -------------------------------------------------------------
  // NOTIFICATION 4: CLIMATE & WEATHER CARE ALERT
  // -------------------------------------------------------------
  /// Sends notification based on temperature and humidity from local weather APIs
  Future<void> notifyClimateWeatherAlert({
    required PlantModel plant,
    required WeatherData weather,
    required PlantClimateEvaluation evaluation,
  }) async {
    if (!evaluation.alertTriggered) return;

    try {
      await initialize();
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final climateKey = 'notified_climate_${plant.id}';
      final lastNotified = prefs.getString(climateKey);
      if (lastNotified == todayStr) {
        return; // Only 1 climate alert per plant per day
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'plant_climate_channel',
        'Climate & Weather Botanical Alerts',
        channelDescription: 'Notifications for temperature and humidity care adjustments',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final int id = (plant.id.hashCode ^ 404).abs() % 100000;
      try {
        await _notificationsPlugin.show(
          id: id,
          title: evaluation.alertTitle,
          body: evaluation.recommendation,
          notificationDetails: platformDetails,
          payload: plant.id,
        );
      } catch (_) {}

      await prefs.setString(climateKey, todayStr);
    } catch (e) {
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        debugPrint('notifyClimateWeatherAlert error: $e');
      }
    }
  }

  /// Backward compatible helper for manual test triggers
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
        importance: Importance.high,
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
      debugPrint('sendSystemNotification error: $e');
    }
  }
}
