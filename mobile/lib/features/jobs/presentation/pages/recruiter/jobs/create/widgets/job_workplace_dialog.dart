import 'package:flutter/material.dart';

import 'package:zennyt/features/jobs/domain/entities/job.dart';
Future<WorkplaceType?> showJobWorkplaceDialog(BuildContext context) async {
  return showDialog<WorkplaceType>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Type of workplace'),
      children: WorkplaceType.values.map((type) {
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, type),
          child: Text(type.label),
        );
      }).toList(),
    ),
  );
}
