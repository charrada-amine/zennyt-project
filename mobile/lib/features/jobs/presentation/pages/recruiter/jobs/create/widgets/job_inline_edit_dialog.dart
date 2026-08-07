import 'package:flutter/material.dart';

Future<void> showJobInlineEditDialog(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  String hint = '',
}) async {
  final tempCtrl = TextEditingController(text: controller.text);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(label),
      content: TextField(
        controller: tempCtrl,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            controller.text = tempCtrl.text;
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
