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
    ElectricityApi().getPricesForDays(1).then((value) {
      setState(() {
        prices = value;
        interval = [getInterval()[0] + 24, getInterval()[1] + 24];
      });
    }).catchError((error) {
      setState(() {
        errorMessage = error.toString();
      });
    });
  }

  _nextInterval() {
    setState(() {
      if(!isNextInterval) return;
      interval = [interval[0] + 12, interval[1] + 12];
    });
  }

  _previousInterval() {
    if(!isPreviousInterval) return;
    setState(() {
      interval = [interval[0] - 12, interval[1] - 12];
    });
  }

  bool get isNextInterval => prices != null && prices!.length >= interval[1].toInt() + 12;
  bool get isPreviousInterval => interval[0] >= 12;

  @override
  Widget build(BuildContext context) {
    if(errorMessage != null) return Center(child: Text('Error: $errorMessage'));
    if(prices == null) return const Center(child: CircularProgressIndicator());

    double maxPrice = prices!.sublist(interval[0].toInt(), interval[1].toInt() + 1).map((e) => e.priceWithModifiers(modifiers)).reduce(max).ceilToDouble();
    double minPrice = min(0, prices!.sublist(interval[0].toInt(), interval[1].toInt() + 1).map((e) => e.priceWithModifiers(modifiers)).reduce(min)).floorToDouble();
    double screenHeight = MediaQuery.of(context).size.height;

    if(maxPrice - minPrice < 5) {
      maxPrice = minPrice + 5;
    }

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 8.0),
          Row(
            children: [
              const SizedBox(width: 16.0),
              Text(
                  '${prices![interval[0].toInt()].time.toLocal().day}.${prices![interval[0].toInt()].time.toLocal().month}. '
                      'klo ${prices![interval[0].toInt()].time.toLocal().hour.toString().padLeft(2, '0')}'
                      '-${prices![interval[1].toInt()].time.toLocal().hour + 1}',
                  style: Theme.of(context).textTheme.headlineSmall
              ),
            ],
          ),
          Container(
            constraints: BoxConstraints(
              maxHeight: min(300.0, screenHeight - 140),
              maxWidth: 600
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16.0 , vertical: 8.0),
            padding: const EdgeInsets.all(8.0),
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
                  labelX: (value) => (value.toInt() % 24).toString(),
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
                    thickness: 18.0,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10.0,
              children: [
                ElevatedButton(
                  onPressed: _previousInterval,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back),
                      const SizedBox(width: 8.0),
                      Text('Edelliset 12 tuntia', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _nextInterval,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Seuraavat 12 tuntia', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 8.0),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            )
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
