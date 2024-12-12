
import 'package:flutter/material.dart';
import 'package:sahkohinta/api.dart';

class ChartWidget extends StatelessWidget {
  ChartWidget({super.key});
  final pricesFuture = ElectricityApi().prices;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: pricesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return const Center(
              child: Text('TODO: Chart'),
            );
          }
        }
    );
  }
}
