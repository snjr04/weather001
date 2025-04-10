import 'package:flutter/material.dart';
import 'package:testapp/services/currency_api.dart';
import 'package:testapp/model/currency_model.dart'; // чтобы видеть RateEntry и CurrencyRates

class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key});

  @override
  MoneyPageState createState() => MoneyPageState();
}

class CurrencyRate {
  final String currency;
  final double rate;

  CurrencyRate({required this.currency, required this.rate});
}

class MoneyPageState extends State<MoneyPage> {
  final TextEditingController amountController = TextEditingController();
  List<CurrencyRate> rates = [];
  bool isLoading = false;
  String errorMessage = '';
  double amount = 0.0;
  String selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    fetchRates();
    amountController.addListener(onAmountChanged);
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void onAmountChanged() {
    setState(() {
      amount = double.tryParse(amountController.text) ?? 0.0;
    });
  }

  Future<void> fetchRates() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final CurrencyRates fetchedRates = await CurrencyApi().fetchCurrencyRates();
      final List<CurrencyRate> updatedRates = fetchedRates.rates
          .map((entry) => CurrencyRate(currency: entry.currency, rate: entry.value))
          .toList();

      final double kgsRate = updatedRates
          .firstWhere((rate) => rate.currency == 'KGS', orElse: () => CurrencyRate(currency: 'KGS', rate: 1.0))
          .rate;

      final List<CurrencyRate> convertedRates = updatedRates.map((rate) {
        return CurrencyRate(currency: rate.currency, rate: rate.rate / kgsRate);
      }).toList();

      setState(() {
        rates = convertedRates;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки курсов: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конвертер валют'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchRates,
            tooltip: 'Обновить курсы',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            buildAmountInputCard(),
            const SizedBox(height: 24),
            buildCurrencyDropdownCard(),
            const SizedBox(height: 24),
            Expanded(child: buildRateDisplay()),
          ],
        ),
      ),
    );
  }

  Widget buildAmountInputCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Введите сумму', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: '0.00',
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCurrencyDropdownCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Выберите валюту:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: rates.map((rate) {
                return DropdownMenuItem<String>(
                  value: rate.currency,
                  child: Text(rate.currency),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCurrency = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRateDisplay() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
      );
    }

    if (rates.isEmpty) {
      return const Center(child: Text('Курсы валют не загружены', style: TextStyle(fontSize: 16)));
    }

    final double rate = rates
        .firstWhere((r) => r.currency == selectedCurrency, orElse: () => CurrencyRate(currency: selectedCurrency, rate: 0.0))
        .rate;

    final String converted = (amount * rate).toStringAsFixed(2);

    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1 KGS = ${rate.toStringAsFixed(6)} $selectedCurrency',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('$amount KGS = $converted $selectedCurrency',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }
}
