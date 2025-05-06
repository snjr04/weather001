import 'package:flutter/material.dart';
import 'package:testapp/services/weather_api.dart';
import 'dart:async';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  String weatherInfo = 'Загрузка данных...';
  bool isLoading = true;
  bool hasData = false;
  Timer? updateTimer;

  final WeatherApi weatherApi = WeatherApi();

  @override
  void initState() {
    super.initState();
    initializeWeather();
    setupAutoUpdate();
  }

  void setupAutoUpdate() {
    updateTimer?.cancel();
    updateTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      fetchWeatherData();
    });
  }

  Future initializeWeather() async {
    setState(() => isLoading = true);
    await weatherApi.initialize();
    await fetchWeatherData();
  }

  Future fetchWeatherData() async {
    try {
      final data = weatherApi.weatherData ?? 'Данные еще не загружены.';
      if (mounted) {
        setState(() {
          weatherInfo = formatWeatherData(data);
          isLoading = false;
          hasData = data.isNotEmpty && !data.toLowerCase().contains('ошибка');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          weatherInfo = 'Ошибка при загрузке: $e';
          isLoading = false;
          hasData = false;
        });
      }
    }
  }

  String formatWeatherData(String rawData) {
    if (rawData.contains('\n')) {
      final parts = rawData.split('\n');
      if (parts.length >= 2) {
        return '${parts[0]}, ${parts[1].replaceAll("Погода: ", "").replaceAll("Температура: ", "")}';
      }
    }
    return rawData;
  }

  Future refreshManually() async {
    setState(() {
      isLoading = true;
      weatherInfo = 'Обновление данных...';
    });
    await fetchWeatherData();
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    weatherApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Текущая Погода'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshManually,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  spreadRadius: 5,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        weatherInfo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                if (!hasData && !isLoading) const SizedBox(height: 16),
                if (!hasData && !isLoading)
                  ElevatedButton(
                    onPressed: refreshManually,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Обновить'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
