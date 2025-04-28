import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testapp/model/currency_model.dart';

class CurrencyApi {
  static const int refreshIntervalMinutes = 10;

  CurrencyRates? cachedRates;
  int lastUpdateTimestamp = 0;
  Timer? autoRefreshTimer;
  bool isFetching = false;

  CurrencyRates? get currentRates => cachedRates;

  void initialize() {
    loadInitialData();
    startAutoRefresh();
  }

  Future<CurrencyRates> getCurrentRates() async {
    if (shouldRefreshData) {
      return await fetchAndUpdateRates();
    }
    return cachedRates ?? await fetchAndUpdateRates();
  }

  Future<CurrencyRates> fetchAndSaveRates() async {
    return await fetchAndUpdateRates();
  }

  Future loadInitialData() async {
    try {
      await fetchAndUpdateRates();
    } catch (e) {
      debugPrint('Initial load error: $e');
    }
  }

  Future<CurrencyRates> fetchAndUpdateRates() async {
    if (isFetching) return cachedRates ?? createEmptyRates();
    isFetching = true;

    try {
      debugPrint('Fetching new currency rates...');
      final response = await http.get(Uri.parse(
          '${dotenv.env['EXCHANGE_API_URL']}?app_id=${dotenv.env['EXCHANGE_API_KEY']}&base=USD'));

      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.statusCode}');
      }

      final rawData = json.decode(response.body);
      validateResponseStructure(rawData);

      cachedRates = CurrencyRates(//копирования данных
        base: rawData['base'].toString(),// базовая валюта
        date: DateTime.fromMillisecondsSinceEpoch(rawData['timestamp'] * 1000),//переобразуется в милисекунды
        rates: (rawData['rates'] as Map<String, dynamic>)//данные переобразуется в ключ значение
            .entries//переобразует в ключ значение
            .where((e) => e.value is num)//фильтр для num
            .map((e) => RateEntry(e.key, (e.value as num).toDouble()))// num to double
            .toList(),
      );

      lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
      debugPrint('Rates updated successfully');
      return cachedRates!;
    } catch (e) {
      debugPrint('Error updating rates: $e');
      return cachedRates ?? createEmptyRates();
    } finally {
      isFetching = false;
    }
  }

  bool get shouldRefreshData {
    if (cachedRates == null) return true;
    final minutesSinceLastUpdate =
        (DateTime.now().millisecondsSinceEpoch - lastUpdateTimestamp) / (1000 * 60);
    return minutesSinceLastUpdate >= refreshIntervalMinutes;
  }

  void validateResponseStructure(Map<String, dynamic> rawData) {
    const requiredKeys = {'base', 'rates', 'timestamp'};
    if (requiredKeys.any((key) => !rawData.containsKey(key))) {
      throw Exception('Invalid API response structure');
    }
  }

  CurrencyRates createEmptyRates() {
    return CurrencyRates(
      base: 'USD',
      date: DateTime.now(),
      rates: [],

    );
  }

  void startAutoRefresh() {
    autoRefreshTimer?.cancel();
    autoRefreshTimer = Timer.periodic(
      const Duration(minutes: refreshIntervalMinutes),
          (_) => fetchAndUpdateRates(),
    );
  }

  void dispose() {
    autoRefreshTimer?.cancel();
  }
}