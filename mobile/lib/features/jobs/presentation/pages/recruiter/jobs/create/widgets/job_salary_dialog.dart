import 'package:flutter/material.dart';

Future<void> showJobSalaryDialog(
  BuildContext context, {
  required TextEditingController minCtrl,
  required TextEditingController maxCtrl,
  required VoidCallback onSaved,
}) async {
  final tempMin = TextEditingController(text: minCtrl.text);
  final tempMax = TextEditingController(text: maxCtrl.text);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Salary range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: tempMin,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minimum salary', hintText: '15000'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tempMax,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Maximum salary', hintText: '30000'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            minCtrl.text = tempMin.text;
            maxCtrl.text = tempMax.text;
            onSaved();
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
