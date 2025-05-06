class RateEntry {
  final String currency;
  final double value;

  RateEntry(this.currency, this.value);
  factory RateEntry.fromJson(Map<String, dynamic> json) {
    return RateEntry(
      json['currency'],
      (json['value'] as num).toDouble(),
    );
  }
}

class CurrencyRates {
  final String base;
  final DateTime date;
  final List<RateEntry> rates;

  CurrencyRates({
    required this.base,
    required this.date,
    required this.rates,
  });

  factory CurrencyRates.fromJson(Map<String, dynamic> json) {
    final rateList = (json['rates'] as Map<String, dynamic>)
        .entries
        .where((e) => e.value is num)
        .map((e) => RateEntry(e.key, (e.value as num).toDouble()))
        .toList();

    return CurrencyRates(
      base: json['base'],
      date: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
      rates: rateList,
    );
  }
}
