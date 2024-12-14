import 'dart:math';
import 'package:mrx_charts/mrx_charts.dart';
import 'package:flutter/material.dart';
import 'package:sahkohinta/utils/api.dart';

class ChartWidget extends StatefulWidget {
  final PriceModifiers modifiers;
  const ChartWidget({
    required this.modifiers,
    super.key,
  });

  @override
  State<ChartWidget> createState() => _ChartWidget();
}

class _ChartWidget extends State<ChartWidget> {
  late List<double> interval;
  List<ElectricityPrice>? prices;
  late PriceModifiers modifiers;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    modifiers = widget.modifiers;
    interval = getInterval();
    ElectricityApi().getPricesForDay(DateTime.now()).then((value) {
      setState(() {
        prices = value;
      });
    }).catchError((error) {
      setState(() {
        errorMessage = error.toString();
      });
    });
  }

  _nextInterval() {
    setState(() {
      if(prices == null || prices!.length < interval[1].toInt() + 12) return;
      interval = [interval[0] + 12, interval[1] + 12];
    });
  }

  _previousInterval() {
    if(interval[0] < 12) return;
    setState(() {
      interval = [interval[0] - 12, interval[1] - 12];
    });
  }

  @override
  Widget build(BuildContext context) {
      if(errorMessage != null) return Center(child: Text('Error: $errorMessage'));
     if(prices == null) return const Center(child: CircularProgressIndicator());

    double maxPrice = prices!.map((e) => e.priceWithModifiers(modifiers)).reduce(max).ceilToDouble();
    double minPrice = min(0, prices!.map((e) => e.priceWithModifiers(modifiers)).reduce(min)).floorToDouble();

    return Center(
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 16.0),
              Text(
                  '${prices![interval[0].toInt()].time.toLocal().month}. ${prices![interval[0].toInt()].time.toLocal().day}. '
                      'klo ${prices![interval[0].toInt()].time.toLocal().hour} '
                      '- ${prices![interval[1].toInt()].time.toLocal().hour + 1} välillä',
                  style: Theme.of(context).textTheme.headlineSmall
              ),
            ],
          ),
          Container(
            constraints: const BoxConstraints(
              maxHeight: 300.0,
              maxWidth: 600
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            child: Chart(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              layers: [
                ChartAxisLayer(
                  settings: ChartAxisSettings(
                    x: ChartAxisSettingsAxis(
                      frequency: 1.0,
                      max: interval[1],
                      min: interval[0],
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
                      value: prices![index + interval[0].toInt()].priceWithModifiers(modifiers),
                      x: index.toDouble() + interval[0],
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
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _previousInterval,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back),
                    const SizedBox(width: 8.0),
                    Text('Edelliset 12 tuntia', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: _nextInterval,
                child: Row(
                  children: [
                    Text('Seuraavat 12 tuntia', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: 8.0),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          )
        ],
      )
    );
  }

  List<double> getInterval() {
    DateTime now = DateTime.now().toLocal();
    if(now.hour < 12) return [0, 11];
    return [12, 23];
  }

  // List<ElectricityPrice>
}
