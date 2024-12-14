import 'package:flutter/material.dart';
import 'package:sahkohinta/utils/home_widget.dart';
import 'package:sahkohinta/utils/preferences.dart';
import '../utils/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencesNotifier = Provider.of<PreferencesNotifier>(context);
    //preferencesNotifier.value.preferences['vat'],

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      children: [
        Card(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hinta", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                SettingsItem(
                  title: "Sisällytä ALV hintoihin",
                  child: SettingsSwitch(
                    value: double.parse(preferencesNotifier.value.preferences['vat'] ?? '25.5') != 0,
                    onChanged: (value) {
                      preferencesNotifier.setPreference('vat', value ? '25.5' : '0');
                      updateWidget();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SettingsItem(
                  title: "Myyjän marginaali",
                  child: SettingsNumberField(
                    value: double.parse(preferencesNotifier.value.preferences['margin'] ?? '0'),
                    onChanged: (value) {
                      if(value < 0) return;
                      preferencesNotifier.setPreference('margin', value.toString());
                      updateWidget();
                    },
                    helperText: "sent/kWh",
                  ),
                ),
              ],
            ),
          )
        )
      ],
    );
  }
}

class SettingsItem extends StatelessWidget {
  const SettingsItem({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 13.0),
          child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        ),
        child,
      ],
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}

class SettingsNumberField extends StatelessWidget {
  const SettingsNumberField({super.key, required this.value, required this.onChanged, this.helperText});

  final double value;
  final String? helperText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: value.toString());
    final FocusNode focusNode = FocusNode();

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        onChanged(double.tryParse(controller.text) ?? 0);
      }
    });

    return SizedBox(
      width: 100,
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
        onSubmitted: (value) => onChanged(double.tryParse(value) ?? 0),
        onTapOutside: (value) => focusNode.unfocus(),
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(10.0)
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
          fillColor: Theme.of(context).colorScheme.secondaryContainer,
          filled: true,
          hintText: '0.0',
          helperText: helperText,
        ),
      ),
    );
  }
}
