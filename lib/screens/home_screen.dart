import 'package:flutter/material.dart';
import 'package:testapp/screens/money_screen.dart';
import 'package:testapp/screens/weather_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          WeatherScreen(),
          MoneyPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.sunny),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'Money',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: onItemTapped,
      ),
    );
  }
}