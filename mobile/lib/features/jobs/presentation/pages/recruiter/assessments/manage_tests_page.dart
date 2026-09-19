import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_dialog.dart';

/// Full list of the recruiter's tests (design 197) with edit/delete and an
/// "Add a test" action. The horizontal preview on the Careers home links here.
class ManageTestsPage extends ConsumerWidget {
  const ManageTestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assessmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      appBar: CustomAppBar(
        title: 'Your tests',
        onBack: () => context.pop(),
        trailingAction: _AddButton(
          onTap: () async {
            await context.pushNamed(AppRoutes.nCreateAssessment);
            ref.read(assessmentsProvider.notifier).refresh();
          },
        ),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => ref.read(assessmentsProvider.notifier).refresh(),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (_, _) => ListView(
            children: [
              const SizedBox(height: 120),
              const Center(
                child: Text('Failed to load your tests.', style: TextStyle(color: Color(0xFFE53935))),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => ref.read(assessmentsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (tests) {
            if (tests.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No tests yet.\nCreate one to attach it to a job offer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A90A2), height: 1.5),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                for (final test in tests)
                  _TestRow(
                    test: test,
                    onEdit: () async {
                      await context.pushNamed(
                        AppRoutes.nEditAssessment,
                        pathParameters: {'assessmentId': test.id},
                        extra: test,
                      );
                      ref.read(assessmentsProvider.notifier).refresh();
                    },
                    onDelete: () => _confirmDelete(context, ref, test),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Assessment test) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete this test?',
      message: '"${test.title}" will be removed from your tests. This cannot be undone.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(assessmentsProvider.notifier).deleteAssessment(test.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete this test.')),
        );
      }
    }
  }
}

class _TestRow extends StatelessWidget {
  final Assessment test;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TestRow({required this.test, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final minutes = (test.timeLimitSeconds / 60).ceil();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const AppIcon(HugeIcons.strokeRoundedIdea01, color: Color(0xFF21438A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                ),
                const SizedBox(height: 3),
                Text(
                  '${test.questions.length} questions · $minutes min',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const AppIcon(HugeIcons.strokeRoundedPencilEdit01, color: Color(0xFF21438A), size: 20),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const AppIcon(HugeIcons.strokeRoundedDelete02, color: Color(0xFFE53935), size: 20),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: kAppBarButtonDecoration(),
        child: const AppIcon(HugeIcons.strokeRoundedAdd01, color: Color(0xFF21438A), size: 22),
      ),
    );
  }
}
