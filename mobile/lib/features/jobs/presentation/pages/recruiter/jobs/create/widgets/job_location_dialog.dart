import 'package:flutter/material.dart';

Future<void> showJobLocationDialog(
  BuildContext context, {
  required TextEditingController cityCtrl,
  required TextEditingController countryCtrl,
  required VoidCallback onSaved,
}) async {
  final cityLocal = TextEditingController(text: cityCtrl.text);
  final countryLocal = TextEditingController(text: countryCtrl.text);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: cityLocal,
            decoration: const InputDecoration(labelText: 'City', hintText: 'e.g. Tunis'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: countryLocal,
            decoration: const InputDecoration(labelText: 'Country', hintText: 'e.g. Tunisia'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            cityCtrl.text = cityLocal.text;
            countryCtrl.text = countryLocal.text;
            onSaved();
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
