import 'package:flutter/material.dart';
import 'package:sahkohinta/widgets/chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChartWidget(),
            const Text('Home Page', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            const Text('Welcome to the Home Page', style: TextStyle(fontSize: 16)),
          ]
      ),
    );
  }
}
