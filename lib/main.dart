import 'package:flutter/material.dart';

void main() => runApp(const TavrixApp());

class TavrixApp extends StatelessWidget {
  const TavrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tavrix Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      home: const Scaffold(
        body: Center(child: Text('Tavrix Browser')),
      ),
    );
  }
}
