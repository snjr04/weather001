import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testapp/services/currency_api.dart';
import 'package:testapp/model/currency_model.dart';

class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key});

  @override
  MoneyPageState createState() => MoneyPageState();
}

class MoneyPageState extends State<MoneyPage> {
  final TextEditingController amountController = TextEditingController();
  final CurrencyApi currencyApi = CurrencyApi();
  List<RateEntry>? rates;
  String errorMessage = '';
  double amount = 0.0;
  String selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    currencyApi.initialize();
    fetchRates();
  }

  @override
  void dispose() {
    amountController.dispose();
    currencyApi.dispose();
    super.dispose();
  }

  Future fetchRates() async {
    setState(() => errorMessage = '');
    try {
      final newRates = await currencyApi.getCurrentRates();
      setState(() => rates = newRates.rates);
    } catch (e) {
      setState(() => errorMessage = 'Не удалось загрузить курсы валют: $e');
    }
  }

  double getCurrentRate() {
    return rates?.firstWhere(
          (r) => r.currency == selectedCurrency,
      orElse: () => RateEntry(selectedCurrency, 0.0),
    ).value ?? 0.0;
  }

  Widget buildStyledCard({required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rate = getCurrentRate();
    final converted = (amount * rate).toStringAsFixed(2);

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
            buildStyledCard(
              child: Column(
                children: [
                  const Text('Введите сумму', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    onChanged: (value) {
                      setState(() => amount = double.tryParse(value) ?? 0.0);
                    },
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
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
            const SizedBox(height: 24),
            buildStyledCard(
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
                    items: rates?.map((rate) {
                      return DropdownMenuItem<String>(
                        value: rate.currency,
                        child: Text(rate.currency),
                      );
                    }).toList() ?? [],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCurrency = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: errorMessage.isNotEmpty
                  ? Center(
                child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
              )
                  : rates == null
                  ? const Center(
                child: Text('Курсы валют не загружены', style: TextStyle(fontSize: 16)),
              )
                  : Center(
                child: buildStyledCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '1 KGS = ${rate.toStringAsFixed(6)} $selectedCurrency',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$amount KGS = $converted $selectedCurrency',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
