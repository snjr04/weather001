import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:testapp/model/currency_model.dart';

class CurrencyApi {
  static bool initialized = false;
  static CurrencyRates? cachedRates;
  static DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration cacheDuration = Duration(minutes: 10);

  Future<CurrencyRates> fetchCurrencyRates() async {
    await ensureInitialized();

    if (cachedRates != null &&
        DateTime.now().difference(lastUpdated) < cacheDuration) {
      return cachedRates!;
    }

    final apiUrl =
        '${dotenv.env['EXCHANGE_API_URL']}?access_key=${dotenv.env['EXCHANGE_API_KEY']}&base=EUR';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      final dynamic rawData = json.decode(response.body);

      if (response.statusCode != 200 || rawData['success'] != true) {
        final error = rawData['error'];
        final message = error != null && error['info'] != null
            ? error['info'].toString()
            : 'Failed to fetch rates';
        throw Exception(message);
      }

      // Преобразуем вручную
      final String base = rawData['base'].toString();
      final DateTime date = DateTime.parse(rawData['date'].toString());

      final dynamic rawRates = rawData['rates'];
      List<RateEntry> ratesList = [];

      for (final key in (rawRates as dynamic).keys) {
        final value = rawRates[key];
        if (value is num) {
          ratesList.add(RateEntry(key.toString(), value.toDouble()));
        }
      }

      cachedRates = CurrencyRates(
        base: base,
        date: date,
        rates: ratesList,
      );
      lastUpdated = DateTime.now();
      return cachedRates!;
    } catch (e) {
      if (cachedRates != null) {
        debugPrint('Using cached data due to error: ${e.toString()}');
        return cachedRates!;
      }
      throw Exception('Currency API error: ${e.toString()}');
    }
  }

  Future<CurrencyRates> refreshRates() async {
    lastUpdated = DateTime.fromMillisecondsSinceEpoch(0);
    return await fetchCurrencyRates();
  }

  static Future<void> ensureInitialized() async {
    if (!initialized) {
      try {
        await dotenv.load(fileName: '.env');
        initialized = true;
      } catch (e) {
        throw Exception('.env error');
      }
    }
  }
}
