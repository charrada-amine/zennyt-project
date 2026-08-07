import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../providers/search_provider.dart';

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
  String _selectedExperience = 'Entry-level';
  String _selectedJobType = '';

  static const _workplaceWire = {
    'On-site': 'ON_SITE', 'Hybrid': 'HYBRID', 'Remote': 'REMOTE', 'Flexible': 'FLEXIBLE',
  };
  static const _levelWire = {
    'Junior': 'JUNIOR', 'Senior': 'SENIOR', 'Lead': 'LEAD', 'Manager': 'MANAGER',
  };
  static const _jobTypeWire = {
    'Full-time': 'FULL_TIME', 'Part-time': 'PART_TIME', 'Contract': 'CONTRACT',
    'Temporary': 'TEMPORARY', 'Apprenticeship': 'APPRENTICESHIP', 'Volunteer': 'VOLUNTEER',
  };

  @override
  void initState() {
    super.initState();
    // Réouvre la page avec les filtres actuellement appliqués.
    final f = ref.read(searchFiltersProvider);
    _selectedWorkplace = _workplaceWire.entries
        .firstWhere((e) => e.value == f.workplace,
            orElse: () => const MapEntry('', ''))
        .key;
    _selectedLevel = _levelWire.entries
        .firstWhere((e) => e.value == f.level, orElse: () => const MapEntry('', ''))
        .key;
    _selectedJobType = _jobTypeWire.entries
        .firstWhere((e) => e.value == f.contractType,
            orElse: () => const MapEntry('', ''))
        .key;
    if (f.salaryMin != null && f.salaryMax != null) {
      _salaryRange = RangeValues(f.salaryMin!, f.salaryMax!);
      _salaryTouched = true;
    }
  }

  void _applyFilters() {
    ref.read(searchFiltersProvider.notifier).apply(SearchFilters(
          salaryMin: _salaryTouched ? _salaryRange.start : null,
          salaryMax: _salaryTouched ? _salaryRange.end : null,
          workplace: _workplaceWire[_selectedWorkplace],
          level: _levelWire[_selectedLevel],
          contractType: _jobTypeWire[_selectedJobType],
        ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Filter',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildSectionTitle('Job position'),
                  const SizedBox(height: 8),
                  _buildInputField(hint: 'Add a job position'),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Field of work'),
                  const SizedBox(height: 8),
                  _buildDropdownField(hint: 'Select a field of work'),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Salary'),
                  const SizedBox(height: 8),
                  _buildSalarySlider(),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Type of workplace'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('On-site', _selectedWorkplace, (val) => setState(() => _selectedWorkplace = val)),
                      _buildFilterChip('Hybrid', _selectedWorkplace, (val) => setState(() => _selectedWorkplace = val)),
                      _buildFilterChip('Remote', _selectedWorkplace, (val) => setState(() => _selectedWorkplace = val)),
                      _buildFilterChip('Flexible', _selectedWorkplace, (val) => setState(() => _selectedWorkplace = val)),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('City'),
                  const SizedBox(height: 8),
                  _buildDropdownField(hint: 'California'),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Level'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Junior', _selectedLevel, (val) => setState(() => _selectedLevel = val)),
                      _buildFilterChip('Senior', _selectedLevel, (val) => setState(() => _selectedLevel = val)),
                      _buildFilterChip('Mid', _selectedLevel, (val) => setState(() => _selectedLevel = val)),
                      _buildFilterChip('Executive', _selectedLevel, (val) => setState(() => _selectedLevel = val)),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Experience'),
                  const SizedBox(height: 6),
                  _buildRadioOption('Entry-level'),
                  _buildRadioOption('1-2 years'),
                  _buildRadioOption('2-3 years'),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('Type of job'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Full-time', _selectedJobType, (val) => setState(() => _selectedJobType = val)),
                      _buildFilterChip('Part-time', _selectedJobType, (val) => setState(() => _selectedJobType = val)),
                      _buildFilterChip('Contract', _selectedJobType, (val) => setState(() => _selectedJobType = val)),
                      _buildFilterChip('Temporary', _selectedJobType, (val) => setState(() => _selectedJobType = val)),
                      _buildFilterChip('Apprenticeship', _selectedJobType, (val) => setState(() => _selectedJobType = val)),
                      _buildFilterChip('Volunteer', _selectedJobType, (val) => setState(() => _selectedJobType = val)),
                      _buildFilterChip('Any contrat type', _selectedJobType.isEmpty ? 'Any contrat type' : _selectedJobType, (val) => setState(() => _selectedJobType = '')),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.5), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(searchFiltersProvider.notifier).clear();
                      setState(() {
                        _salaryRange = const RangeValues(12000, 22000);
                        _salaryTouched = false;
                        _selectedWorkplace = '';
                        _selectedLevel = '';
                        _selectedExperience = 'Entry-level';
                        _selectedJobType = '';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size.fromHeight(48), 
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Color(0xFF1B3B7B), fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size.fromHeight(48), 
                      backgroundColor: const Color(0xFF1B3B7B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
    );
  }

  Widget _buildInputField({required String hint}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String hint}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
        ],
      ),
    );
  }

  Widget _buildSalarySlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFD91B5C),
            inactiveTrackColor: const Color(0xFFF1F5F9),
            trackHeight: 4.0,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9.0, elevation: 3),
            overlayColor: const Color(0xFFD91B5C).withOpacity(0.1),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 9.0, elevation: 3),
          ),
          child: RangeSlider(
            values: _salaryRange,
            min: 5000,
            max: 40000,
            onChanged: (values) => setState(() { _salaryRange = values; _salaryTouched = true; }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${(_salaryRange.start / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1B3B7B), fontSize: 13)),
              Text('\$${(_salaryRange.end / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1B3B7B), fontSize: 13)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFilterChip(String label, String groupValue, ValueChanged<String> onSelected) {
    final isSelected = label == groupValue;
    return GestureDetector(
      // Retaper un chip sélectionné le désélectionne (filtre inactif).
      onTap: () => onSelected(isSelected ? '' : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD91B5C) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD91B5C) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label) {
    final isSelected = _selectedExperience == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedExperience = label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                  width: isSelected ? 5.5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}