// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
import 'dart:isolate';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sahkohinta/api.dart';

@pragma('vm:entry-point')
void updateWidget() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=${isolateId} function='$updateWidget'");

  ElectricityApi().getCurrentPrice().then((price) {
    print("Got price $price");
    if(price != null) {
      List<Future> futures = [
        HomeWidget.saveWidgetData("price", price.price.toString()),
        HomeWidget.saveWidgetData("time", price.timeToString())
      ];
      Future.wait(futures).then((value) {
        print("Saved widget data");
        HomeWidget.updateWidget(name: 'WidgetProvider');
      });
    }
  });

  HomeWidget.saveWidgetData("price", "1.23");
  HomeWidget.saveWidgetData("time", "01.01. 00-01");
}

void runPeriodicSync() async {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  final DateTime nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);
  await AndroidAlarmManager.periodic(
    const Duration(hours: 1),
    2,
    updateWidget,
    startAt: nextHour,
  );
  print("Scheduled updateWidget at $nextHour");
}
