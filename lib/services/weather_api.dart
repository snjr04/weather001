import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:testapp/model/weather_model.dart';


Position? position;
String latKey = 'lat';
String lonKey = 'lon';


class WeatherApi {
  static final WeatherApi instance = WeatherApi.internal();
  factory WeatherApi() => instance;
  WeatherApi.internal();

  String? weatherData;
  Position? position;
  Timer? updateTimer;
  DateTime? lastRequestTime;

  static const weatherKey = 'weather_data';

  static const timeKey = 'last_time';

  Future initialize() async {
    try {
      await loadFromPrefs();
      await fetchWeather();
      startAutoUpdate();
    } catch (e) {
      weatherData = 'Ошибка инициализации: $e';
    }
  }

  void startAutoUpdate()
  {
    updateTimer?.cancel();
    updateTimer = Timer.periodic(const Duration(minutes: 10), (_){
      fetchWeather().then((_){
      }).catchError((e){
        weatherData = 'Ошибка автобновлении: $e';
      });
    });
  }

  Future loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      weatherData = prefs.getString(weatherKey);

      final timeStr = prefs.getString(timeKey);
      lastRequestTime = timeStr != null ? DateTime.tryParse(timeStr) : null;

      // Если прошло больше 10 минут - сбрасываем данные
      if (lastRequestTime != null &&
          DateTime.now().difference(lastRequestTime!).inMinutes >= 10) {
        weatherData = null;
        position = null;
        lastRequestTime = null;
        return;
      }

      final lat = prefs.getDouble(latKey);
      final lon = prefs.getDouble(lonKey);

      position = (lat != null && lon != null)
          ? Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 1.0,
        altitudeAccuracy: 1.0,
        headingAccuracy: 1.0,
        floor: null,
        isMocked: false,
      )
          : null;
    } catch (e) {
      throw Exception('Ошибка загрузки из SharedPreferences: $e');
    }
  }

  Future saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(weatherKey, weatherData ?? ''),
        if (position != null) ...[
          prefs.setDouble(latKey, position!.latitude),
          prefs.setDouble(lonKey, position!.longitude),
        ],
        if (lastRequestTime != null)
          prefs.setString(timeKey, lastRequestTime!.toIso8601String()),
      ]);
    } catch (e) {
      throw Exception('Ошибка сохранения в SharedPreferences: $e');
    }
  }

  Future fetchWeather() async {
    try {
      final now = DateTime.now();
      if (lastRequestTime != null &&
          now.difference(lastRequestTime!).inMinutes < 10 &&
          weatherData != null) {
        return;
      }
      await updateLocation();
      final apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
      final url = dotenv.env['WEATHER_API_URL'] ?? '';
      final apiUrl = '$url?lat=${position!.latitude}&lon=${position!.longitude}&appid=$apiKey&units=metric&lang=ru';

      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherModel.fromJson(data);
        weatherData = 'Город: ${weather.city}\nПогода: ${weather.description}, Температура: ${weather.temp}°C';
        lastRequestTime = now;
        await saveToPrefs();

      } else {
        weatherData = 'Ошибка загрузки данных о погоде. Код: ${response.statusCode}';
      }
    } catch (e) {
      weatherData = 'Ошибка при получении погоды: $e';
      rethrow;
    }
  }

  Future updateLocation() async {
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

// Future loadFromPrefs() async
// {
//   try{
//   DateTime? lastRequestTime;
//   String timeKey;
//
//   final prefs = await SharedPreferences.getInstance();
//   final timeStr = prefs.getString(timeKey);
//   lastRequestTime = timeStr != null ? DateTime.tryParse(timeStr) : null;
//   if (lastRequestTime != null &&
//       DateTime.now().difference(lastRequestTime!).inMinutes >= 10) {
//     const weatherData = null;
//     const position = null;
//     lastRequestTime = null;
//     return;
//   }
//
//   final lat = prefs.getDouble(latKey);
//   final lon = prefs.getDouble(lonKey);
//
//   position = (lat != null && lon != null)
//       ? Position(
//     latitude: lat,
//     longitude: lon,
//     timestamp: DateTime.now(),
//     accuracy: 1.0,
//     altitude: 0.0,
//     heading: 0.0,
//     speed: 0.0,
//     speedAccuracy: 1.0,
//     altitudeAccuracy: 1.0,
//     headingAccuracy: 1.0,
//     floor: null,
//     isMocked: false,
//   )
//       : null;
// } catch (e) {
// throw Exception('Ошибка загрузки из SharedPreferences: $e');
// }
//   return position;
// }
