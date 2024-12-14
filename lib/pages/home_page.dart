import 'package:flutter/material.dart';
import 'package:sahkohinta/utils/api.dart';
import 'package:sahkohinta/widgets/chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Future<PriceModifiers> modifiersFuture = getModifiers();
    return Center(
      child: Container(
        constraints: const BoxConstraints(),
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: FutureBuilder(future: modifiersFuture, builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if(snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            PriceModifiers modifiers = snapshot.data!;
            return LayoutBuilder(builder: (context, constraints) {
              if(constraints.maxWidth > 600) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChartWidget(modifiers: modifiers),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CurrentHourPrice(modifiers: modifiers),
                        NextHourPrice(modifiers: modifiers),
                      ],
                    )
                  ]
                );
              } else {
                return ListView(
                  children: [
                    CurrentPriceBanner(modifiers: modifiers),
                    const SizedBox(height: 20),
                    ChartWidget(modifiers: modifiers),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        NextHourPrice(modifiers: modifiers),
                        const DailyAverage(),
                      ],
                    )
                  ]
                );
              }
            });
          }
        }),
      )
    );
  }
}

class CurrentHourPrice extends StatelessWidget {
  const CurrentHourPrice({
    super.key,
    required this.modifiers,
  });

  final PriceModifiers modifiers;

  @override
  Widget build(BuildContext context) {
    return InfoBox(
        title: 'Hinta nyt',
        children: [
          FutureBuilder(
              future: ElectricityApi().getCurrentPrice(),
              builder: (context, snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if(snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text(snapshot.data!.toStringWithModifiers(modifiers), style: const TextStyle(fontSize: 20));
                }
              }
          ),
          const Text('sent/kWh', style: TextStyle(fontSize: 16)),
        ]
    );
  }
}

class NextHourPrice extends StatelessWidget {
  const NextHourPrice({
    super.key,
    required this.modifiers,
  });

  final PriceModifiers modifiers;

  @override
  Widget build(BuildContext context) {
    return InfoBox(
      title: 'Seuraava tunti',
      children: [
        FutureBuilder(
            future: ElectricityApi().getNextPrice(),
            builder: (context, snapshot) {
              if(snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if(snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Text(snapshot.data!.toStringWithModifiers(modifiers), style: const TextStyle(fontSize: 20));
              }
            }
        ),
        const Text('sent/kWh', style: TextStyle(fontSize: 16)),
      ]
    );
  }
}

class DailyAverage extends StatelessWidget {
  const DailyAverage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InfoBox(
      title: 'Vuorokauden keskihinta',
      children: [
        FutureBuilder(
            future: ElectricityApi().getPricesForDay(DateTime.now().toLocal()),
            builder: (context, snapshot) {
              if(snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if(snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                double average = snapshot.data!.map((e) => e.price).reduce((a, b) => a + b) / snapshot.data!.length;
                return Text(average.toStringAsFixed(2), style: const TextStyle(fontSize: 20));
              }
            }
        ),
        const Text('sent/kWh', style: TextStyle(fontSize: 16)),
      ]
    );
  }
}

class CurrentPriceBanner extends StatelessWidget {
  const CurrentPriceBanner({
    super.key,
    required this.modifiers,
  });

  final PriceModifiers modifiers;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Sähkön hinta nyt ', style: TextStyle(fontSize: 16)),
          FutureBuilder(
              future: ElectricityApi().getCurrentPrice(),
              builder: (context, snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if(snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text('${snapshot.data!.toStringWithModifiers(modifiers)} sent/kWh', style: const TextStyle(fontSize: 24));
                }
              }
          ),
        ],
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 6,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              )
            ],
          )
        ],
      )
    );
  }
}
