import 'package:flutter/material.dart';
import 'package:zennyt/shared/icons/app_icons.dart';

import 'package:zennyt/features/jobs/domain/entities/job.dart';

Future<void> showJobSalaryDialog(
  BuildContext context, {
  required TextEditingController minCtrl,
  required TextEditingController maxCtrl,
  required String currency,
  required SalaryPeriod period,
  required void Function(String currency, SalaryPeriod period) onSaved,
}) async {
  final tempMin = TextEditingController(text: minCtrl.text);
  final tempMax = TextEditingController(text: maxCtrl.text);
  var selectedCurrency = kSalaryCurrencies.contains(currency) ? currency : 'EUR';
  var selectedPeriod = period;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Salary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Périodicité (maquette 213 : Monthly / Yearly).
              Row(
                children: [
                  for (final p in SalaryPeriod.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.label),
                        selected: selectedPeriod == p,
                        onSelected: (_) => setState(() => selectedPeriod = p),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                icon: const AppIcon(HugeIcons.strokeRoundedArrowDown01, size: 20),
                initialValue: selectedCurrency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: [
                  for (final c in kSalaryCurrencies)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => selectedCurrency = v ?? 'EUR'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tempMin,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum salary (gross)',
                  hintText: '30000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tempMax,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum salary (gross)',
                  hintText: '35000',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              minCtrl.text = tempMin.text;
              maxCtrl.text = tempMax.text;
              onSaved(selectedCurrency, selectedPeriod);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
