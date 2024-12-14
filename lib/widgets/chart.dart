import 'dart:math';
import 'package:mrx_charts/mrx_charts.dart';
import 'package:flutter/material.dart';
import 'package:sahkohinta/utils/api.dart';

class ChartWidget extends StatelessWidget {
  ChartWidget({super.key, required PriceModifiers modifiers});
  final pricesFuture = ElectricityApi().getPricesForDay(DateTime.now());
  final modifiersFuture = getModifiers();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([pricesFuture, modifiersFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if(snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Virhe ladatessa hintatietoja'),
            );
          } else {
            var prices = snapshot.data![0] as List<ElectricityPrice>;
            var modifiers = snapshot.data![1] as PriceModifiers;
            if(prices.length != 24) {
              return const Center(
                child: Text('Virhe ladatessa hintatietoja'),
              );
            }

            double maxPrice = prices.map((e) => e.priceWithModifiers(modifiers)).reduce(max).ceilToDouble();
            double minPrice = min(0, prices.map((e) => e.priceWithModifiers(modifiers)).reduce(min)).floorToDouble();
            return Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 300.0,
                  maxWidth: 600
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: Chart(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  layers: [
                    ChartAxisLayer(
                      settings: ChartAxisSettings(
                        x: ChartAxisSettingsAxis(
                          frequency: 1.0,
                          max: getInterval()[1],
                          min: getInterval()[0],
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            fontSize: 14.0,
                          ),
                        ),
                        y: ChartAxisSettingsAxis(
                          frequency: (maxPrice - minPrice) / 5,
                          max: maxPrice,
                          min: minPrice,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                            fontSize: 14.0,
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
                          color: Theme.of(context).colorScheme.primary,
                          value: prices[index + getInterval()[0].toInt()].priceWithModifiers(modifiers),
                          x: index.toDouble() + getInterval()[0],
                        ),
                      ),
                      settings: const ChartBarSettings(
                        thickness: 14.0,
                      ),
                    ),
                    ChartTooltipLayer(
                      shape: () => ChartTooltipBarShape<ChartBarDataItem>(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        radius: 8.0,
                        currentPos: (item) => item.currentValuePos,
                        currentSize: (item) => item.currentValueSize,
                        onTextValue: (item) => '${item.value.toStringAsFixed(2)} sent/kWh',
                        textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
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
