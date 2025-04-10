import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:testapp/model/weather_model.dart';

class WeatherApi {
  static final WeatherApi instance = WeatherApi.internal();
  factory WeatherApi() => instance;
  WeatherApi.internal();

  String? weatherData;
  Position? position;
  Timer? updateTimer;
  DateTime? lastRequestTime;

  static const weatherKey = 'weather_data';
  static const latKey = 'lat';
  static const lonKey = 'lon';
  static const timeKey = 'last_time';

  Future<void> initialize() async {
    try {
      await loadFromPrefs();
      await fetchWeather();
      startAutoUpdate();
    } catch (e) {
      weatherData = 'Ошибка инициализации: $e';
    }
  }

  String getWeatherText() {
    return weatherData ?? 'Данные еще не загружены.';
  }

  void startAutoUpdate() {
    updateTimer?.cancel();
    updateTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      try {
        await fetchWeather();
      } catch (e) {
        weatherData = 'Ошибка при автообновлении: $e';
      }
    });
  }

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      weatherData = prefs.getString(weatherKey);
      final lat = prefs.getDouble(latKey);
      final lon = prefs.getDouble(lonKey);
      final timeStr = prefs.getString(timeKey);

      if (lat != null && lon != null) {
        position = Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      if (timeStr != null) {
        lastRequestTime = DateTime.tryParse(timeStr);
      }
    } catch (e) {
      throw Exception('Ошибка загрузки из SharedPreferences: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(weatherKey, weatherData ?? '');
      if (position != null) {
        await prefs.setDouble(latKey, position!.latitude);
        await prefs.setDouble(lonKey, position!.longitude);
      }
      if (lastRequestTime != null) {
        await prefs.setString(timeKey, lastRequestTime!.toIso8601String());
      }
    } catch (e) {
      throw Exception('Ошибка сохранения в SharedPreferences: $e');
    }
  }

  Future<void> fetchWeather() async {
    try {
      final now = DateTime.now();
      if (lastRequestTime != null &&
          now.difference(lastRequestTime!).inMinutes < 10 &&
          weatherData != null) {
        return;
      }

      await _updateLocation();

      if (position == null) {
        weatherData = 'Не удалось получить координаты.';
        return;
      }

      final apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('API ключ не найден');
      }

      final url = dotenv.env['WEATHER_API_URL'] ?? '';
      if (url.isEmpty) {
        throw Exception('URL API не найден');
      }

      final apiUrl =
          '$url?lat=${position!.latitude}&lon=${position!.longitude}&appid=$apiKey&units=metric&lang=ru';

      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherModel.fromJson(data);

        weatherData = 'Город: ${weather.city}\nПогода: ${weather.description}, Температура: ${weather.temp}°C';
        lastRequestTime = now;
        await _saveToPrefs();
      } else {
        weatherData = 'Ошибка загрузки данных о погоде. Код: ${response.statusCode}';
      }
    } catch (e) {
      weatherData = 'Ошибка при получении погоды: $e';
      rethrow;
    }
  }

  Future<void> _updateLocation() async {
    try {
      if (position != null) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Служба геолокации отключена');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Разрешение на определение местоположения отклонено');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Разрешение на определение местоположения навсегда отклонено');
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception('Ошибка обновления местоположения: $e');
    }
  }

  void dispose() {
    updateTimer?.cancel();
    updateTimer = null;
  }
}
