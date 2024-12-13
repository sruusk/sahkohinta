import 'dart:math';
import 'package:mrx_charts/mrx_charts.dart';
import 'package:flutter/material.dart';
import 'package:sahkohinta/utils/api.dart';

class ChartWidget extends StatelessWidget {
  ChartWidget({super.key});
  final pricesFuture = ElectricityApi().getPricesForDay(DateTime.now());

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
            print("First: ${snapshot.data!.first}");
            print("Last: ${snapshot.data!.last}");
            double maxPrice = snapshot.data!.map((e) => e.price).reduce(max).ceilToDouble();
            double minPrice = min(0, snapshot.data!.map((e) => e.price).reduce(min)).floorToDouble();
            return Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 300.0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: Chart(
                  layers: [
                    ChartAxisLayer(
                      settings: ChartAxisSettings(
                        x: ChartAxisSettingsAxis(
                          frequency: 1.0,
                          max: getInterval()[1],
                          min: getInterval()[0],
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            fontSize: 10.0,
                          ),
                        ),
                        y: ChartAxisSettingsAxis(
                          frequency: 10,
                          max: maxPrice,
                          min: minPrice,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            fontSize: 10.0,
                          ),
                        ),
                      ),
                      labelX: (value) => value.toInt().toString(),
                      labelY: (value) => value.toInt().toString(),
                    ),
                    ChartBarLayer(
                      items: List.generate(
                        12,
                            (index) => ChartBarDataItem(
                          color: const Color(0xFF00A49F),
                          value: snapshot.data![index + getInterval()[0].toInt()].price,
                          x: index.toDouble() + getInterval()[0],
                        ),
                      ),
                      settings: const ChartBarSettings(
                        thickness: 8.0,
                        radius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                    ),
                  ],
                )
              )
            );
          }
        }
    );
  }

  List<double> getInterval() {
    DateTime now = DateTime.now().toLocal();
    if(now.hour < 12) return [0, 11];
    return [12, 23];
  }

  // List<ElectricityPrice>
}
