import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/plant_model.dart';

class WeatherData {
  final double temperature;
  final double relativeHumidity;
  final int weatherCode;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.relativeHumidity,
    required this.weatherCode,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get weatherDescription {
    if (weatherCode == 0) return 'Clear sky';
    if (weatherCode <= 3) return 'Partly cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 67) return 'Rainy';
    if (weatherCode <= 77) return 'Snowy';
    if (weatherCode <= 99) return 'Thunderstorm';
    return 'Clear';
  }

  String get weatherEmoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 99) return '⛈️';
    return '🌤️';
  }
}

class PlantClimateEvaluation {
  final bool alertTriggered;
  final String alertTitle;
  final String recommendation;
  final String suggestedEnvironment; // 'Indoor' or 'Outdoor'

  PlantClimateEvaluation({
    required this.alertTriggered,
    required this.alertTitle,
    required this.recommendation,
    required this.suggestedEnvironment,
  });
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  WeatherData? _cachedWeather;
  DateTime? _lastFetchTime;
  String _cachedLocationName = 'Local Garden';

  WeatherData? get cachedWeather => _cachedWeather;

  /// Acquires real-time GPS coordinates with automatic permission handling and fallbacks
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('Error getting GPS position: $e');
      return null;
    }
  }

  /// Reverse geocodes latitude and longitude to a human-readable city/locality name
  Future<String> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final city = data['city'] ?? data['locality'] ?? data['principalSubdivision'];
        final country = data['countryName'];
        if (city != null && city.toString().isNotEmpty) {
          final loc = country != null ? '$city, $country' : city.toString();
          _cachedLocationName = loc;
          return loc;
        }
      }
    } catch (_) {}
    return _cachedLocationName;
  }

  /// Fetches real-time weather and humidity for the plant's location
  Future<WeatherData> fetchLocalWeather({double? lat, double? lon, String? locationName}) async {
    // Return cache if fetched less than 15 minutes ago
    if (_cachedWeather != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 15) {
      return _cachedWeather!;
    }

    double latitude = lat ?? 13.0827; // Default Chennai coordinates
    double longitude = lon ?? 80.2707;
    String locName = locationName ?? _cachedLocationName;

    if (lat == null || lon == null) {
      final pos = await getCurrentPosition();
      if (pos != null) {
        latitude = pos.latitude;
        longitude = pos.longitude;
        locName = await reverseGeocode(latitude, longitude);
      }
    }

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,weather_code,is_day',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>? ?? {};

        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
        final humidity = (current['relative_humidity_2m'] as num?)?.toDouble() ?? 65.0;
        final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

        _cachedWeather = WeatherData(
          temperature: temp,
          relativeHumidity: humidity,
          weatherCode: weatherCode,
          locationName: locName,
          latitude: latitude,
          longitude: longitude,
        );
        _lastFetchTime = DateTime.now();
        return _cachedWeather!;
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
    }

    // Default fallback weather
    _cachedWeather = WeatherData(
      temperature: 28.0,
      relativeHumidity: 65.0,
      weatherCode: 0,
      locationName: locName,
      latitude: latitude,
      longitude: longitude,
    );
    return _cachedWeather!;
  }

  /// Evaluates whether current humidity and temperature warrant indoor preservation or watering adjustment
  PlantClimateEvaluation evaluateClimateForPlant(PlantModel plant, WeatherData weather) {
    final temp = weather.temperature;
    final humidity = weather.relativeHumidity;

    if (temp >= 36.0) {
      return PlantClimateEvaluation(
        alertTriggered: true,
        alertTitle: '🔥 High Heat Warning (${temp.toStringAsFixed(1)}°C)',
        recommendation:
            'Extreme heat detected in ${weather.locationName}. Move ${plant.plantName} indoors away from harsh sun and consider hydrating earlier!',
        suggestedEnvironment: 'Indoor',
      );
    }

    if (temp <= 12.0) {
      return PlantClimateEvaluation(
        alertTriggered: true,
        alertTitle: '❄️ Cold Weather Alert (${temp.toStringAsFixed(1)}°C)',
        recommendation:
            'Chilly weather detected. Keep ${plant.plantName} indoors in a warm spot away from cold drafts.',
        suggestedEnvironment: 'Indoor',
      );
    }

    if (humidity < 30.0) {
      return PlantClimateEvaluation(
        alertTriggered: true,
        alertTitle: '🏜️ Low Humidity (${humidity.toStringAsFixed(0)}%)',
        recommendation:
            'The air is very dry in ${weather.locationName}. Mist leaves of ${plant.plantName} with water to prevent leaf tips from browning.',
        suggestedEnvironment: 'Indoor',
      );
    }

    if (humidity > 85.0) {
      return PlantClimateEvaluation(
        alertTriggered: true,
        alertTitle: '🌧️ High Humidity (${humidity.toStringAsFixed(0)}%)',
        recommendation:
            'High humidity detected (${humidity.toStringAsFixed(0)}%). Reduce watering frequency for ${plant.plantName} to prevent root fungal issues.',
        suggestedEnvironment: 'Outdoor',
      );
    }

    return PlantClimateEvaluation(
      alertTriggered: false,
      alertTitle: 'Optimal Weather',
      recommendation: 'Current climate (${temp.toStringAsFixed(1)}°C, ${humidity.toStringAsFixed(0)}% humidity) is well-suited for ${plant.plantName}.',
      suggestedEnvironment: plant.environment,
    );
  }
}
