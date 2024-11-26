import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'pages/homepage.dart';
import 'pages/search.dart';
import 'pages/login.dart';



void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Homepage(),
    Search(),
    Container(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title:Text("Kolaylokma"),
      ),
      body: _currentIndex == 3
          ? const Login()
          : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (int index) {
          if (index == 2) {
            if(_currentIndex == 0) {
              _showFilterDialog();
            }
            else{
              setState(() {
                _currentIndex = 0;
              });
              Future.delayed(const Duration(milliseconds: 500 ),(){
                _showFilterDialog();
              });
            }
          } else if (index == 3) {
            setState(() {
              _currentIndex = index;
            });
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_alt),
            label: 'Filter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Hesabım',

          ),
        ],
      ),
    );
  }

  void _showFilterDialog(){
    showDialog(context: context,
        builder:(BuildContext context){
          return AlertDialog(
              title: const Text('Filter Options'),
              content: const Text('Filter options will be added here.'),
              actions: <Widget>[
              TextButton(
              onPressed: () {
            Navigator.of(context).pop(); // Dialog'u kapat
          },
          child: const Text('Cancel'),
          ),
          TextButton(
          onPressed: () {
          Navigator.of(context).pop(); // Dialog'u kapat ve filtre işlemi yapılabilir
          },
          child: const Text('Apply'),
          ),
          ],
          );
        },
    );
  }

}
