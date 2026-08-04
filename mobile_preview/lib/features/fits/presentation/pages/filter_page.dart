import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Écran Filtre (offres / candidats). État local — applique au retour.
class FilterPage extends StatefulWidget {
  const FilterPage({super.key});
  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final _position = TextEditingController();
  RangeValues _salary = const RangeValues(12, 22);
  String? _level;
  String? _workplace = 'Hybrid';
  String _city = 'California';
  String? _jobType = 'Contract';

  static const _levels = ['Junior', 'Senior', 'Lead', 'Manager'];
  static const _workplaces = ['On-site', 'Hybrid', 'Remote', 'Flexible'];
  static const _cities = ['California', 'New York', 'Texas', 'Remote'];
  static const _jobTypes = [
    'Full-time', 'Part-time', 'Contract', 'Temporary',
    'Apprenticeship', 'Volunteer', 'Any type of contract',
  ];

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => context.pop()),
        title: const Text('Filter',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _label('Job position'),
          TextField(
            controller: _position,
            decoration: _fieldDeco('Add a job position'),
          ),
          const SizedBox(height: 20),
          _label('Salary'),
          RangeSlider(
            values: _salary,
            min: 0,
            max: 100,
            activeColor: AppTheme.brandPink,
            labels: RangeLabels(
                '\$${_salary.start.round()}K', '\$${_salary.end.round()}K'),
            onChanged: (v) => setState(() => _salary = v),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('\$${_salary.start.round()}K',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            Text('\$${_salary.end.round()}K',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          _label('Level'),
          _chips(_levels, _level, (v) => setState(() => _level = v)),
          const SizedBox(height: 20),
          _label('Type of workplace'),
          _chips(_workplaces, _workplace, (v) => setState(() => _workplace = v)),
          const SizedBox(height: 20),
          _label('City'),
          DropdownButtonFormField<String>(
            value: _city,
            decoration: _fieldDeco(''),
            items: _cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _city = v ?? _city),
          ),
          const SizedBox(height: 20),
          _label('Type of job'),
          _chips(_jobTypes, _jobType, (v) => setState(() => _jobType = v)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _position.clear();
                  _salary = const RangeValues(12, 22);
                  _level = null;
                  _workplace = null;
                  _jobType = null;
                }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brandBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Search'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
      );

  InputDecoration _fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _chips(List<String> options, String? selected, ValueChanged<String> onTap) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () => onTap(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: o == selected ? AppTheme.brandPink : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: o == selected ? AppTheme.brandPink : const Color(0xFFD9DAE5)),
              ),
              child: Text(o,
                  style: TextStyle(
                      fontSize: 13,
                      color: o == selected ? Colors.white : AppTheme.navy)),
            ),
          ),
      ],
    );
  }
}
