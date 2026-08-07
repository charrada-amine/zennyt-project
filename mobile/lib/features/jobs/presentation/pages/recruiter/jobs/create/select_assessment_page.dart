import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/shared/widgets/custom_app_bar.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'widgets/assessment_preview_sheet.dart';

/// Sélection d'un test à attacher à l'offre — porté depuis REC-04.
class SelectAssessmentPage extends ConsumerStatefulWidget {
  final String? currentSelectedId;
  const SelectAssessmentPage({super.key, this.currentSelectedId});

  @override
  ConsumerState<SelectAssessmentPage> createState() => _SelectAssessmentPageState();
}

class _SelectAssessmentPageState extends ConsumerState<SelectAssessmentPage> {
  String? _selectedId;
  String? _selectedTitle;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentSelectedId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assessmentsProvider.notifier).refresh();
    });
  }

  void _onAssessmentSelected(Assessment assessment, String id) {
    setState(() {
      _selectedId = id;
      _selectedTitle = assessment.title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessmentsAsync = ref.watch(assessmentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Select an assessment',
        onBack: () => context.pop(),
      ),
      body: assessmentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF21438A)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Failed to load tests.',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(assessmentsProvider.notifier).refresh(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
        data: (assessments) {
          if (assessments.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_outlined, size: 48, color: Color(0xFF8A90A2)),
                    SizedBox(height: 12),
                    Text('No tests available',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      'Create a test first to assign it to this job offer',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A90A2)),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: assessments.length,
                  itemBuilder: (context, index) {
                    final a = assessments[index];
                    final isSelected = _selectedId == a.id;
                    return AssessmentGridCard(
                      title: a.title,
                      isSelected: isSelected,
                      onTap: () => AssessmentPreviewSheet.show(
                        context,
                        assessment: a,
                        onSelected: (id) => _onAssessmentSelected(a, id),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Center(
                    child: SizedBox(
                      height: 50,
                      width: 180,
                      child: _selectedId != null
                          ? ElevatedButton(
                              onPressed: () {
                                context.pop<Map<String, String>>({
                                  'id': _selectedId!,
                                  'title': _selectedTitle!,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF21438A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text(
                                'Select',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF21438A), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text(
                                'Select',
                                style: TextStyle(color: Color(0xFF21438A), fontWeight: FontWeight.w600),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AssessmentGridCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const AssessmentGridCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isSelected ? const Color(0xFF21438A) : Colors.white;
    final elementColor = isSelected ? Colors.white : const Color(0xFF21438A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF21438A),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF21438A).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.white, size: 22)
                  : Icon(Icons.visibility_outlined, color: elementColor, size: 20),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb_outline, color: elementColor, size: 34),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(color: elementColor, fontWeight: FontWeight.w600, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
