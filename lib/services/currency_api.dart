import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testapp/model/currency_model.dart';

class CurrencyApi {
  static const int refreshIntervalMinutes = 10;
  static const Duration refreshInterval = Duration(minutes: refreshIntervalMinutes);

  CurrencyRates? cachedRates;
  DateTime? lastUpdate;
  Timer? autoRefreshTimer;

  CurrencyRates? get currentRates => cachedRates;

  void initialize() {
    fetchAndUpdateRates();
    startAutoRefresh();
  }

  Future<CurrencyRates> getCurrentRates() async {
    if (shouldRefreshData) {
      return await fetchAndUpdateRates();
    }
    return cachedRates ?? await fetchAndUpdateRates();
  }

  Future<CurrencyRates> fetchAndUpdateRates() async {
    try {
      debugPrint('Fetching new currency rates...');
      final response = await http.get(Uri.parse(
          '${dotenv.env['EXCHANGE_API_URL']}?app_id=${dotenv.env['EXCHANGE_API_KEY']}&base=USD'));

      if (response.statusCode != 200) {
        throw Exception('Ошибка 200: ${response.statusCode}');
      }

      final rawData = json.decode(response.body);
      validateResponseStructure(rawData);

      cachedRates = CurrencyRates.fromJson(rawData);
      lastUpdate = DateTime.now();
      debugPrint('Rates updated successfully');
      return cachedRates!;
    } catch (e) {
      debugPrint('Ошибка обновления rates: $e');
      return cachedRates ?? createEmptyRates();
    }
  }

  bool get shouldRefreshData {
    if (cachedRates == null) return true;
    return DateTime.now().difference(lastUpdate!) >= refreshInterval;
  }

  void validateResponseStructure(Map<String, dynamic> rawData) {
    const requiredKeys = {'base', 'rates', 'timestamp'};
    if (requiredKeys.any((key) => !rawData.containsKey(key))) {
      throw Exception('Ошибка получении данных');
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
      refreshInterval,
          (_) => fetchAndUpdateRates(),
    );
  }

}

