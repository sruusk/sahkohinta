import 'package:flutter/material.dart';
import 'package:sahkohinta/widgets/chart.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text('Settings', style: TextStyle(fontSize: 16)),
          ]
      ),
    );
  }
}
