import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
class AssessmentSuccessSheet extends StatefulWidget {
  final Assessment assessment;

  const AssessmentSuccessSheet({super.key, required this.assessment});

  static void show(BuildContext context, Assessment assessment) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AssessmentSuccessSheet(assessment: assessment),
    );
  }

  @override
  State<AssessmentSuccessSheet> createState() => _AssessmentSuccessSheetState();
}

class _AssessmentSuccessSheetState extends State<AssessmentSuccessSheet> {
  bool _isLinkCopied = false;

  void _navigateToDetail(BuildContext ctx) {
    Navigator.of(ctx).pop();
    ctx.pushReplacementNamed(
      AppRoutes.nAssessmentDetail,
      pathParameters: {'assessmentId': widget.assessment.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Color(0xFF5B4EF5), size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your test was successfully added!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1B4B),
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Copy the link to share it with your candidates.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 28),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: 200,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLinkCopied ? const Color(0xFF5B4EF5) : Colors.white,
                    foregroundColor: _isLinkCopied ? Colors.white : const Color(0xFF1D3557),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: _isLinkCopied
                          ? BorderSide.none
                          : const BorderSide(color: Color(0xFF1D3557), width: 1.5),
                    ),
                    elevation: _isLinkCopied ? 4 : 0,
                    shadowColor: const Color(0xFF5B4EF5).withValues(alpha: 0.35),
                  ),
                  onPressed: () async {
                    final link = widget.assessment.shareableLink ?? 'https://www.zennyt.com/tests/';
                    await Clipboard.setData(ClipboardData(text: link));
                    setState(() => _isLinkCopied = true);
                    await Future.delayed(const Duration(milliseconds: 350));
                    if (!mounted) return;
                    _navigateToDetail(context);
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLinkCopied
                        ? const Icon(Icons.arrow_forward_rounded, key: ValueKey('arrow'), size: 18)
                        : const Icon(Icons.copy_outlined, key: ValueKey('copy'), size: 18),
                  ),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _isLinkCopied ? 'Opening...' : 'Get a link',
                      key: ValueKey(_isLinkCopied),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _navigateToDetail(context),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
