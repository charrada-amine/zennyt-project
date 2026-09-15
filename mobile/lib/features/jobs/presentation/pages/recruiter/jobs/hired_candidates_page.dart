import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/features/jobs/domain/entities/hired_candidate.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

/// Recrutements du recruteur (maquette 258) : nom, poste, compte à rebours
/// d'essai (D-xx) et annulation tant que la période d'essai court.
class HiredCandidatesPage extends ConsumerWidget {
  const HiredCandidatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hiredCandidatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      appBar: CustomAppBar(title: 'Hired Candidates', onBack: () => context.pop()),
      body: RefreshIndicator(
        onRefresh: () => ref.read(hiredCandidatesProvider.notifier).refresh(),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ListView(
            children: [
              const SizedBox(height: 120),
              const Center(child: Text('Could not load your hires.', style: TextStyle(color: Color(0xFFE53935)))),
              Center(
                child: TextButton(
                  onPressed: () => ref.read(hiredCandidatesProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (hires) {
            if (hires.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No hired candidates yet.',
                      style: TextStyle(color: Color(0xFF8A90A2)),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                for (final hire in hires)
                  _HireTile(
                    hire: hire,
                    onCancel: () => _confirmCancel(context, ref, hire),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, HiredCandidate hire) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this hire?'),
        content: Text(
          'Ending the recruitment of ${hire.displayName} for "${hire.title}". '
          'This is only possible during the probation period.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel hire', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(hiredCandidatesProvider.notifier).cancel(hire.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }
}

class _HireTile extends StatelessWidget {
  final HiredCandidate hire;
  final VoidCallback onCancel;
  const _HireTile({required this.hire, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final initial = hire.displayName.trim().isEmpty ? '?' : hire.displayName.trim()[0].toUpperCase();
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
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEEF2FF),
            backgroundImage: (hire.avatarUrl != null && hire.avatarUrl!.isNotEmpty)
                ? NetworkImage(hire.avatarUrl!)
                : null,
            child: (hire.avatarUrl == null || hire.avatarUrl!.isEmpty)
                ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF11428D)))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hire.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (hire.cancellable)
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF59E0B)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 5),
                  Text(
                    hire.daysRemaining != null ? 'D-${hire.daysRemaining}' : 'Cancel',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
            )
          else
            _Badge(
              label: hire.isCancelled ? 'Cancelled' : 'Hired',
              color: hire.isCancelled ? const Color(0xFF94A3B8) : const Color(0xFF22C55E),
            ),
        ],
      ),
    );
  }

  String _subtitle() {
    final when = _timeAgo(hire.hiredAt);
    return when.isEmpty ? hire.title : '${hire.title} • $when';
  }

  String _timeAgo(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inDays >= 30) {
      final months = diff.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    return 'Just now';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
