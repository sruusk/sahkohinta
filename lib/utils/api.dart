import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

String getApiUrl() {
  DateTime now = DateTime.now();
  DateTime startTime = now.add(const Duration(days: -3));
  DateTime tomorrow = now.add(const Duration(days: 2));
  final String start = "${startTime.year}${startTime.month}${startTime.day}0000";
  final String end = "${tomorrow.year}${tomorrow.month}${tomorrow.day}2359";
  const String token = String.fromEnvironment('ENTSOE_TOKEN');
  return "https://web-api.tp.entsoe.eu/api?documentType=A44&out_Domain=10YFI-1--------U&in_Domain=10YFI-1--------U&periodStart=$start&periodEnd=$end&securityToken=$token";
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
      // Return cached prices if we have them. If it's after 16:00, return the cached prices if we already have the next day's prices
      if(prices.isNotEmpty && DateTime.now().toLocal().hour < 16 && prices.last.time.toLocal().add(const Duration(hours: -1)).day == DateTime.now().toLocal().day) {
        return prices;
      } else if(prices.isNotEmpty &&
          DateTime.now().toLocal().hour >= 16 &&
          DateTime.now().toLocal().day + 1 == prices.last.time.add(const Duration(hours: -2)).toLocal().day
      ) {
        return prices;
      }
    }

    print('Fetching prices');

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
      int position = 1;
      ElectricityPrice? prevPrice;
      for (var point in points) {
        final double price = double.parse(point.getElement('price.amount')?.innerText ?? '-100');
        final int pos = int.parse(point.getElement('position')?.innerText ?? '-1');
        final DateTime time = DateTime.parse(start ?? '').add(Duration(hours: pos - 1));
        if(pos == position) {
          prevPrice = ElectricityPrice.fromMWH(time, price);
          prices.add(prevPrice);
        } else if(pos > position) {
          final double oldPrice = prevPrice!.price;
          final DateTime oldTime = prevPrice.time;
          for(int i = 1; i < pos - position + 1; i++) {
            prices.add(ElectricityPrice(time: oldTime.add(Duration(hours: i)), price: oldPrice));
          }
          prevPrice = ElectricityPrice.fromMWH(time, price);
          prices.add(prevPrice);
        }
        position = pos + 1;
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
    for (var price in prices) {
      if(price.time.isAtSameMomentAs(nowHour)) {
        print('Current price: $price');
        return price;
      }
    }
    return null;
  }

  Future<ElectricityPrice?> getNextPrice() async {
    final DateTime now = DateTime.now();
    final DateTime nextHour = DateTime(now.year, now.month, now.day, now.hour, 0, 0).add(const Duration(hours: 1));
    var prices = await this.prices;
    for (var price in prices) {
      if(price.time.isAtSameMomentAs(nextHour)) {
        return price;
      }
    }
    return null;
  }

  Future<List<ElectricityPrice>> getThreeHourPrices() {
    final DateTime now = DateTime.now();
    final DateTime nowHour = DateTime(now.year, now.month, now.day, now.hour, 0, 0);
    final DateTime nextThreeHours = nowHour.add(const Duration(hours: 2));
    return getPricesForInterval(nowHour, nextThreeHours);
  }

  Future<List<ElectricityPrice>> getPricesForInterval(DateTime start, DateTime end) async {
    var prices = await this.prices;
    return prices.where(
            (element) => (element.time.toLocal().isAfter(start) || element.time.toLocal().isAtSameMomentAs(start)) &&
                (element.time.toLocal().isBefore(end) || element.time.toLocal().isAtSameMomentAs(end))
    ).toList();
  }

  /// Get prices for the current day
  Future<List<ElectricityPrice>> getPricesForDay(DateTime day) async {
    final DateTime start = DateTime(day.year, day.month, day.day, 0, 0, 0);
    final DateTime end = DateTime(day.year, day.month, day.day, 23, 0, 0);
    return getPricesForInterval(start, end);
  }

  /// Get prices for current - n days.
  Future<List<ElectricityPrice>> getPricesForDays(int days) async {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day - days, 0, 0, 0);
    final DateTime end = DateTime(now.year, now.month, now.day + 1, 23, 0, 0);
    return getPricesForInterval(start, end);
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

  String toStringWithModifiers(PriceModifiers modifiers) {
    double result = price;
    for (var modifier in modifiers.multipliers) {
      result *= modifier.value;
    }
    for (var modifier in modifiers.addons) {
      result += modifier.value;
    }
    return result.toStringAsFixed(2);
  }

  double priceWithModifiers(PriceModifiers modifiers) {
    double result = price;
    for (var modifier in modifiers.multipliers) {
      result *= modifier.value;
    }
    for (var modifier in modifiers.addons) {
      result += modifier.value;
    }
    return result;
  }

  String timeToString() {
    DateTime localTime = time.toLocal();
    return '${localTime.day}.${localTime.month}. ${localTime.hour.toString().padLeft(2, '0')}-${(localTime.hour + 1).toString().padLeft(2, '0')}';
  }

  String timeToHourString() {
    DateTime localTime = time.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}-${(localTime.hour + 1).toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'ElectricityPrice{time: $time, price: ${price.toStringAsFixed(2)}}';
  }
}

class PriceModifiers {
  // Multipliers to base price
  final List<PriceModifier> multipliers;
  // Addons added after multipliers are applied
  List<PriceModifier> addons;

  PriceModifiers({
    required this.multipliers,
    required this.addons
  });
}

class PriceModifier {
  final ModifierType type;
  final double value;

  PriceModifier({
    required this.type,
    required this.value
  });
}

enum ModifierType { // This is unnecessary for now
  vat,
  margin,
  tax,
  transfer
}

Future<PriceModifiers> getModifiers() async {
  final prefs = await SharedPreferences.getInstance();
  final vat = double.parse(prefs.getString('vat') ?? '25.5');
  final margin = double.parse(prefs.getString('margin') ?? '0');
  final electricityTax = double.parse(prefs.getString('tax') ?? '0');
  final transfer = double.parse(prefs.getString('transfer') ?? '0');
  print('VAT: $vat, margin: $margin');
  return PriceModifiers(
    multipliers: [
      PriceModifier(type: ModifierType.vat, value: vat / 100 + 1),
    ],
    addons: [
      PriceModifier(type: ModifierType.margin, value: margin),
      PriceModifier(type: ModifierType.tax, value: electricityTax),
      PriceModifier(type: ModifierType.transfer, value: transfer)
    ]
  );
}
