import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sahkohinta/pages/home_page.dart';
import 'package:sahkohinta/pages/settings_page.dart';
import 'package:sahkohinta/utils/preferences.dart';
import 'package:sahkohinta/utils/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:sahkohinta/utils/home_widget.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure the binding is initialized
  await AndroidAlarmManager.initialize();
  await AndroidAlarmManager.oneShot(const Duration(seconds: 5), 1, updateWidget);
  HomeWidget.updateWidget(name: 'WidgetProvider');
  runPeriodicSync();
  runApp(
    Provider<PreferencesNotifier>(
      notifier: PreferencesNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sähköhinta',
      locale: const Locale('fi', ''), // Finnish, no country code
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Tuntihinta'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _pageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _pageIndex = _pageController.page!.round();
      });
    });
  }

  void setPageIndex(int index) {
    setState(() {
      _pageIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return _buildMobileLayout(context);
      } else {
        return _buildTabletLayout(context);
      }
    });
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            itemCount: 2,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return const HomePage();
                case 1:
                  return const SettingsPage();
                default:
                  return const Text('Error');
              }
            },
          )
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: setPageIndex,
        currentIndex: _pageIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Koti"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Asetukset",
          ),
        ],
        selectedItemColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _pageIndex,
              onDestinationSelected: setPageIndex,
              labelType: NavigationRailLabelType.selected,
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Koti'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Asetukset'),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 2,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return const HomePage();
                    case 1:
                      return const SettingsPage();
                    default:
                      return const Text('Error');
                  }
                },
              ),
            ),
          ],
        )
      ),
    );
  }
}
