import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/job_offer_write_datasource.dart';

/// Formulaire "Add a job offer" (état local). Certaines lignes ouvrent un
/// sous-écran (Description, Select an assessment) ou une feuille (employment type).
class AddJobOfferPage extends StatefulWidget {
  const AddJobOfferPage({super.key});
  @override
  State<AddJobOfferPage> createState() => _AddJobOfferPageState();
}

class _AddJobOfferPageState extends State<AddJobOfferPage> {
  final _position = TextEditingController();
  final _location = TextEditingController();
  final _salary = TextEditingController();
  String _workplace = 'On-site';
  String? _employment;
  String? _assessment;
  bool _international = false;
  bool _posting = false;

  static const _employmentTypes = [
    'Full time', 'Part time', 'Contract', 'Temporary', 'Apprenticeship', 'Volunteer',
  ];

  // Libellés UI → valeurs d'enum exactes attendues par le backend.
  static const _workplaceEnum = {
    'On-site': 'ON_SITE',
    'Hybrid': 'HYBRID',
    'Remote': 'REMOTE',
    'Flexible': 'FLEXIBLE',
  };
  static const _contractEnum = {
    'Full time': 'FULL_TIME',
    'Part time': 'PART_TIME',
    'Contract': 'CONTRACT',
    'Temporary': 'TEMPORARY',
    'Apprenticeship': 'APPRENTICESHIP',
    'Volunteer': 'VOLUNTEER',
  };

  @override
  void dispose() {
    _position.dispose();
    _location.dispose();
    _salary.dispose();
    super.dispose();
  }

  /// POST /job-offers puis PATCH status=ACTIVE, puis retour à l'espace recruteur
  /// (qui recharge ses offres depuis le backend).
  Future<void> _post() async {
    final title = _position.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renseigne le poste.')));
      return;
    }
    final parts = _location.text.split(',');
    final city = parts.isNotEmpty ? parts.first.trim() : '';
    final country = parts.length > 1 ? parts[1].trim() : '';

    setState(() => _posting = true);
    try {
      final ds = sl<JobOfferWriteDataSource>();
      final id = await ds.create(
        title: title,
        description: 'Offre publiée depuis l\'app.',
        contractType: _contractEnum[_employment] ?? 'FULL_TIME',
        workplaceType: _workplaceEnum[_workplace] ?? 'ON_SITE',
        experienceLevel: 'JUNIOR',
        locationCity: city,
        locationCountry: country,
        locationRemote: _workplace == 'Remote',
      );
      await ds.activate(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job offer posted ✅')));
      context.go('/careers');
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la publication : $e')));
    }
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
        title: const Text('Add a job offer',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _input('Job position', _position),
          _dropdown('Type of workplace', _workplace,
              const ['On-site', 'Hybrid', 'Remote', 'Flexible'],
              (v) => setState(() => _workplace = v)),
          _input('Job location', _location),
          _navRow('Employment type', _employment, _pickEmployment),
          _input('Salary', _salary),
          _navRow('Description', null, () => context.push('/recruiter/offer-description'),
              hint: 'Add description'),
          _navRow('Add a hard skills test', _assessment, () async {
            final picked = await context.push<String>('/recruiter/select-assessment');
            if (picked != null) setState(() => _assessment = picked);
          }, hint: 'Select a test'),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _international,
            onChanged: (v) => setState(() => _international = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.brandBlue,
            title: const Text('Open to hire international candidates',
                style: TextStyle(fontSize: 13, color: AppTheme.navy)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Post'),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: const Icon(Icons.add, color: AppTheme.muted),
          ),
        ),
      );

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }

  Widget _navRow(String label, String? value, VoidCallback onTap, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: const Icon(Icons.add, color: AppTheme.muted),
          ),
          child: Text(value ?? (hint ?? ''),
              style: TextStyle(
                  color: value == null ? AppTheme.muted : AppTheme.navy)),
        ),
      ),
    );
  }

  void _pickEmployment() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose the employment type',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.navy)),
              const SizedBox(height: 4),
              const Text(
                  'Determine and choose the type of work according to what you want.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12)),
              const SizedBox(height: 8),
              for (final t in _employmentTypes)
                RadioListTile<String>(
                  value: t,
                  groupValue: _employment,
                  activeColor: AppTheme.brandBlue,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t),
                  onChanged: (v) {
                    setState(() => _employment = v);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
