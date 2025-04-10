class RateEntry {
  final String currency;
  final double value;

  RateEntry(this.currency, this.value);
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
    List<RateEntry> rateList = [];

    final ratesJson = json['rates'] as Map<String, dynamic>;
    for (final key in ratesJson.keys) {
      final value = ratesJson[key];
      if (value is num) {
        rateList.add(RateEntry(key, value.toDouble()));
      }
    }

    return CurrencyRates(
      base: json['base'] as String,
      date: DateTime.parse(json['date'] as String),
      rates: rateList,
    );
  }
}
