import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

String getApiUrl() {
  DateTime now = DateTime.now();
  DateTime tomorrow = now.add(const Duration(days: 2));
  final String start = "${now.year}${now.month}${now.day}0000";
  final String end = "${tomorrow.year}${tomorrow.month}${tomorrow.day}2359";
  return "https://web-api.tp.entsoe.eu/api?documentType=A44&out_Domain=10YFI-1--------U&in_Domain=10YFI-1--------U&periodStart=$start&periodEnd=$end&securityToken=${dotenv.env['ENTSOE_TOKEN']}";
}

class ElectricityApi {
  static ElectricityApi? _instance;
  late final Future<List<ElectricityPrice>> prices;

  factory ElectricityApi() {
    return _instance ??= ElectricityApi._internal();
  }
  ElectricityApi._internal() {
    prices = fetchPrices();
  }

  Future<List<ElectricityPrice>> fetchPrices() async {
    var prefs = await SharedPreferences.getInstance();
    final String? pricesJson = prefs.getString('prices');
    if(pricesJson != null) {
      final prices = List<ElectricityPrice>.from(json.decode(pricesJson).map((e) => ElectricityPrice.fromJSON(e)));
      // If time is over 16:00 and we don't have prices for the next day, fetch new prices
      if(prices.isNotEmpty || DateTime.now().hour < 16) {
        return prices;
      } else if(DateTime.now().hour >= 16 && DateTime.now().day + 1 == prices.last.time.day) {
        return prices;
      }
    }

    final response = await http.get(Uri.parse(getApiUrl()));
    final List<ElectricityPrice> prices = [];
    final document = XmlDocument.parse(response.body);
    final timeSeries = document.findAllElements('TimeSeries');
    for (var timeSerie in timeSeries) {
      final period = timeSerie.getElement("Period");
      final timeInterval = period!.getElement("timeInterval");
      final start = timeInterval!.getElement('start')?.innerText;

      final resolution = period.getElement('resolution')?.innerText;
      if(resolution != 'PT60M') throw Exception('Unsupported resolution $resolution');

      final points = period.childElements.where((element) => element.name.local == 'Point');
      for (var point in points) {
        final int position = int.parse(point.getElement('position')?.innerText ?? '0');
        final double price = double.parse(point.getElement('price.amount')?.innerText ?? '-100');
        final DateTime time = DateTime.parse(start ?? '').add(Duration(hours: position - 1));
        prices.add(ElectricityPrice.fromMWH(time, price));
      }
    }
    // Save prices as json to shared preferences
    await prefs.setString('prices', json.encode(prices.map((e) => e.toJson()).toList()));
    return prices;
  }

  Future<ElectricityPrice?> getCurrentPrice() async {
    final DateTime now = DateTime.now();
    final DateTime nowHour = DateTime(now.year, now.month, now.day, now.hour, 0, 0);
    var prices = await this.prices;
    print('Got prices $prices');
    for (var price in prices) {
      if(price.time.isAtSameMomentAs(nowHour)) {
        return price;
      }
    }
    return null;
  }
}

class ElectricityPrice {
  final DateTime time;
  final double price;

  ElectricityPrice({
    required this.time,
    required this.price
  });

  factory ElectricityPrice.fromMWH(DateTime time, double price) {
    return ElectricityPrice(
      time: time,
      price: price / 10 // Convert to €cent/MWh
    );
  }

  factory ElectricityPrice.fromJSON(Map<String, dynamic> json) {
    return ElectricityPrice(
      time: DateTime.parse(json['time']),
      price: json['price']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'price': price
    };
  }

  String toStringWithMultipliers(List<double> multipliers) {
    double result = price;
    for(var m in multipliers) {
      result *= m;
    }
    return result.toStringAsFixed(2);
  }

  String timeToString() {
    DateTime localTime = time.toLocal();
    return '${localTime.day}.${localTime.month}. ${localTime.hour.toString().padLeft(2, '0')}-${(localTime.hour + 1).toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'ElectricityPrice{time: $time, price: ${price.toStringAsFixed(2)}}';
  }
}
