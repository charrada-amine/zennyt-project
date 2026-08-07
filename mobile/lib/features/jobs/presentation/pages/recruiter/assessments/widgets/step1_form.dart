import 'package:flutter/material.dart';

import 'package:zennyt/features/jobs/presentation/widgets/app_text_field.dart';
class AssessmentStep1Form extends StatelessWidget {
  final TextEditingController titleCtrl;
  final int numQuestions;
  final ValueChanged<int?> onNumQuestionsChanged;
  final VoidCallback onContinue;
  final VoidCallback? onGenerateWithAi;

  const AssessmentStep1Form({
    super.key,
    required this.titleCtrl,
    required this.numQuestions,
    required this.onNumQuestionsChanged,
    required this.onContinue,
    this.onGenerateWithAi,
  });

  @override
  Widget build(BuildContext context) {
    final int totalMinutes = numQuestions * 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select the number of questions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'The test includes a maximum of 30 questions. Candidates have 2 minutes to answer each question.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Test title',
            hint: 'e.g. Flutter Developer Assessment',
            controller: titleCtrl,
          ),
          const SizedBox(height: 20),
          const Text(
            'Number of questions',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          _QuestionsDropdown(value: numQuestions, onChanged: onNumQuestionsChanged),
          const SizedBox(height: 16),
          _TimeLimitBanner(totalMinutes: totalMinutes, numQuestions: numQuestions),
          const SizedBox(height: 40),
          Center(
            child: SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D3557),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: onContinue,
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          if (onGenerateWithAi != null) ...[
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 220,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D3557),
                    side: const BorderSide(color: Color(0xFF1D3557)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onGenerateWithAi,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text(
                    "Générer avec l'IA",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionsDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int?> onChanged;

  const _QuestionsDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          items: [1, 10, 15, 20, 25, 30].map((v) {
            return DropdownMenuItem<int>(value: v, child: Text('Maximum $v questions'));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TimeLimitBanner extends StatelessWidget {
  final int totalMinutes;
  final int numQuestions;

  const _TimeLimitBanner({required this.totalMinutes, required this.numQuestions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF4338CA)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total time limit: $totalMinutes min ($numQuestions questions × 2 min)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4338CA)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
