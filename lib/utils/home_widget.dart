// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
import 'dart:isolate';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sahkohinta/utils/api.dart';

@pragma('vm:entry-point')
void updateWidget() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=${isolateId} function='$updateWidget'");

  ElectricityApi().getThreeHourPrices().then((prices) async {
    print("Got prices $prices");
    final PriceModifiers modifiers = PriceModifiers(multipliers: [ PriceModifier(type: ModifierType.vat, value: 1.255) ], addons: []);
    List<Future> futures = [
      HomeWidget.saveWidgetData("price", prices[0].toStringWithModifiers(modifiers)),
      HomeWidget.saveWidgetData("price0", prices[0].toStringWithModifiers(modifiers)),
      HomeWidget.saveWidgetData("price1", prices[1].toStringWithModifiers(modifiers)),
      HomeWidget.saveWidgetData("price2", prices[2].toStringWithModifiers(modifiers)),
      HomeWidget.saveWidgetData("time", prices[0].timeToString()),
      HomeWidget.saveWidgetData("time0", prices[0].timeToHourString()),
      HomeWidget.saveWidgetData("time1", prices[1].timeToHourString()),
      HomeWidget.saveWidgetData("time2", prices[2].timeToHourString())
    ];
    Future.wait(futures).then((value) {
      print("Saved widget data");
      HomeWidget.updateWidget(name: 'WidgetProvider');
    });
  });
}

void runPeriodicSync() async {
  final DateTime now = DateTime.now();
  // final int isolateId = Isolate.current.hashCode;
  final DateTime nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);
  await AndroidAlarmManager.periodic(
    const Duration(hours: 1),
    2,
    updateWidget,
    startAt: nextHour,
  );
  print("Scheduled updateWidget at $nextHour");
}
