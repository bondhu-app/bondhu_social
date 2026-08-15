import 'package:flutter/material.dart';

void main() {
  runApp(const BondhuApp());
}

class BondhuApp extends StatelessWidget {
  const BondhuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bondhu Social',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bondhu Social'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'স্বাগতম Bondhu Social-এ ❤️',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
