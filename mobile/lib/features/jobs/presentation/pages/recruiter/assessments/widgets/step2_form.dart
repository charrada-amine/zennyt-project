import 'package:flutter/material.dart';

import 'question_form_state.dart';

class AssessmentStep2Form extends StatelessWidget {
  final int currentQuestionIndex;
  final int numQuestions;
  final QuestionFormState currentQuestion;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onChanged;

  const AssessmentStep2Form({
    super.key,
    required this.currentQuestionIndex,
    required this.numQuestions,
    required this.currentQuestion,
    required this.isLoading,
    required this.onNext,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isQuestionFilled = currentQuestion.questionCtrl.text.trim().isNotEmpty &&
        currentQuestion.optionCtrls.every((c) => c.text.trim().isNotEmpty);

    const optionHints = ['Answer A', 'Answer B', 'Answer C', 'Answer D'];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestionHeader(currentIndex: currentQuestionIndex, total: numQuestions),
                const SizedBox(height: 10),
                _ProgressBar(current: currentQuestionIndex + 1, total: numQuestions),
                const SizedBox(height: 16),
                _QuestionTextField(
                  controller: currentQuestion.questionCtrl,
                  hint: 'Type the question',
                  onChanged: onChanged,
                ),
                const SizedBox(height: 20),
                ...List.generate(
                  4,
                  (i) => _OptionRow(
                    controller: currentQuestion.optionCtrls[i],
                    hint: optionHints[i],
                    isCorrect: currentQuestion.correctIndex == i,
                    onTap: () {
                      currentQuestion.correctIndex = i;
                      onChanged();
                    },
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
        _Step2BottomBar(
          isQuestionFilled: isQuestionFilled,
          isLoading: isLoading,
          isLastQuestion: currentQuestionIndex == numQuestions - 1,
          onNext: onNext,
        ),
      ],
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _QuestionHeader({required this.currentIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Question number ${currentIndex + 1}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
        Text(
          '${currentIndex + 1} / $total',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: current / total,
        backgroundColor: const Color(0xFFE2E8F0),
        color: const Color(0xFF1D3557),
        minHeight: 4,
      ),
    );
  }
}

class _QuestionTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  const _QuestionTextField({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      onChanged: (_) => onChanged(),
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1D3557), width: 1.5),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isCorrect;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  const _OptionRow({
    required this.controller,
    required this.hint,
    required this.isCorrect,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCorrect ? const Color(0xFF22C55E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _RadioDot(isCorrect: isCorrect),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isCorrect ? Colors.white : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: isCorrect ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool isCorrect;
  const _RadioDot({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isCorrect ? Colors.white : const Color(0xFFCBD5E1), width: 2),
        color: isCorrect ? Colors.white : Colors.transparent,
      ),
      child: isCorrect
          ? const Center(child: Icon(Icons.circle, size: 10, color: Color(0xFF22C55E)))
          : null,
    );
  }
}

class _Step2BottomBar extends StatelessWidget {
  final bool isQuestionFilled;
  final bool isLoading;
  final bool isLastQuestion;
  final VoidCallback onNext;

  const _Step2BottomBar({
    required this.isQuestionFilled,
    required this.isLoading,
    required this.isLastQuestion,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isQuestionFilled)
            const Text(
              'Select the right answers',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
            ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isQuestionFilled ? const Color(0xFF1D3557) : Colors.white,
                  foregroundColor: isQuestionFilled ? Colors.white : const Color(0xFF1D3557),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isQuestionFilled
                        ? BorderSide.none
                        : const BorderSide(color: Color(0xFF1D3557), width: 1.5),
                  ),
                  elevation: 0,
                ),
                onPressed: isLoading ? null : onNext,
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        isLastQuestion ? 'Finish' : 'Continue',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
