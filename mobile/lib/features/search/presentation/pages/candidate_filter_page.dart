import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../providers/search_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../shared/widgets/primary_button.dart';

class CandidateFilterPage extends ConsumerStatefulWidget {
  const CandidateFilterPage({super.key});

  @override
  ConsumerState<CandidateFilterPage> createState() =>
      _CandidateFilterPageState();
}

class _CandidateFilterPageState extends ConsumerState<CandidateFilterPage> {
  RangeValues _salaryRange = const RangeValues(12000, 22000);
  bool _salaryTouched = false;
  String _selectedWorkplace = '';
  String _selectedLevel = '';
  String _selectedJobType = '';

  static const _workplaceWire = {
    'On-site': 'ON_SITE',
    'Hybrid': 'HYBRID',
    'Remote': 'REMOTE',
    'Flexible': 'FLEXIBLE',
  };
  static const _levelWire = {
    'Junior': 'JUNIOR',
    'Senior': 'SENIOR',
    'Lead': 'LEAD',
    'Manager': 'MANAGER',
  };
  static const _jobTypeWire = {
    'Full-time': 'FULL_TIME',
    'Part-time': 'PART_TIME',
    'Contract': 'CONTRACT',
    'Temporary': 'TEMPORARY',
    'Apprenticeship': 'APPRENTICESHIP',
    'Volunteer': 'VOLUNTEER',
  };

  @override
  void initState() {
    super.initState();
    // Réouvre la page avec les filtres actuellement appliqués.
    final f = ref.read(searchFiltersProvider);
    _selectedWorkplace = _workplaceWire.entries
        .firstWhere(
          (e) => e.value == f.workplace,
          orElse: () => const MapEntry('', ''),
        )
        .key;
    _selectedLevel = _levelWire.entries
        .firstWhere(
          (e) => e.value == f.level,
          orElse: () => const MapEntry('', ''),
        )
        .key;
    _selectedJobType = _jobTypeWire.entries
        .firstWhere(
          (e) => e.value == f.contractType,
          orElse: () => const MapEntry('', ''),
        )
        .key;
    if (f.salaryMin != null && f.salaryMax != null) {
      _salaryRange = RangeValues(f.salaryMin!, f.salaryMax!);
      _salaryTouched = true;
    }
  }

  void _applyFilters() {
    ref
        .read(searchFiltersProvider.notifier)
        .apply(
          SearchFilters(
            salaryMin: _salaryTouched ? _salaryRange.start : null,
            salaryMax: _salaryTouched ? _salaryRange.end : null,
            workplace: _workplaceWire[_selectedWorkplace],
            level: _levelWire[_selectedLevel],
            contractType: _jobTypeWire[_selectedJobType],
          ),
        );
    context.pop();
  }

  void _resetFilters() {
    ref.read(searchFiltersProvider.notifier).clear();
    setState(() {
      _salaryRange = const RangeValues(12000, 22000);
      _salaryTouched = false;
      _selectedWorkplace = '';
      _selectedLevel = '';
      _selectedJobType = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: CustomAppBar(
        title: 'Refine your search',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(
                    'Salary',
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${(_salaryRange.start / 1000).toStringAsFixed(0)}k',
                              style: AppTypography.titleLarge.copyWith(
                                color: colors.textDarkBlue,
                              ),
                            ),
                            Text(
                              '\$${(_salaryRange.end / 1000).toStringAsFixed(0)}k',
                              style: AppTypography.titleLarge.copyWith(
                                color: colors.textDarkBlue,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _salaryRange,
                          min: 5000,
                          max: 40000,
                          activeColor: colors.accent,
                          labels: RangeLabels(
                            _salaryRange.start.round().toString(),
                            _salaryRange.end.round().toString(),
                          ),
                          onChanged: (values) => setState(() {
                            _salaryRange = values;
                            _salaryTouched = true;
                          }),
                          onChangeEnd: (_) =>
                              SoundService.instance.vibrateSelection(),
                        ),
                        if (!_salaryTouched)
                          Text(
                            'Any salary until you adjust the range',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _section(
                    'Workplace',
                    _chips(
                      _workplaceWire.keys.where((key) => key != 'Flexible'),
                      _selectedWorkplace,
                      (value) => setState(() => _selectedWorkplace = value),
                    ),
                  ),
                  _section(
                    'Level',
                    _chips(
                      _levelWire.keys,
                      _selectedLevel,
                      (value) => setState(() => _selectedLevel = value),
                    ),
                  ),
                  _section(
                    'Contract',
                    _chips(
                      _jobTypeWire.keys,
                      _selectedJobType,
                      (value) => setState(() => _selectedJobType = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Reset',
                      outlined: true,
                      onPressed: _resetFilters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: 'Show results',
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: context.colors.cardSurface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: context.colors.textDarkBlue,
          ),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );

  Widget _chips(
    Iterable<String> values,
    String selected,
    ValueChanged<String> select,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: values
        .map(
          (label) => ChoiceChip(
            label: Text(label),
            selected: label == selected,
            showCheckmark: true,
            onSelected: (active) {
              SoundService.instance.vibrateSelection();
              select(active ? label : '');
            },
          ),
        )
        .toList(),
  );
}
