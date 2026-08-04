import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/fit_item.dart';

/// Grande carte du deck "Fits" — mise en page selon offre vs professionnel.
class FitCard extends StatelessWidget {
  final FitItem item;
  final bool matched;
  final VoidCallback? onTap;
  const FitCard({super.key, required this.item, this.matched = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6E6EC)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (matched) _matchBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: item.kind == FitKind.jobOffer ? _job() : _pro(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF22A06B),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text("It's a match !",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }

  // ───────────── Offre ─────────────
  Widget _job() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _logo(36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.role,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy)),
                Text(item.name,
                    style: const TextStyle(fontSize: 13, color: AppTheme.muted)),
                _location(),
              ],
            ),
          ),
        ]),
        const Divider(height: 28),
        const Text('About the job',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        const SizedBox(height: 6),
        Text(item.about ?? '',
            style: const TextStyle(color: Color(0xFF555A6B), height: 1.45)),
        const SizedBox(height: 14),
        _pinkTags(),
        if (item.salary != null) ...[
          const SizedBox(height: 16),
          const Text('Salary',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.payments_outlined, size: 16, color: AppTheme.brandPink),
            const SizedBox(width: 6),
            Text(item.salary!,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy)),
          ]),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('Posted 2 days ago',
                style: TextStyle(fontSize: 11, color: AppTheme.muted)),
          ),
        ],
      ],
    );
  }

  // ───────────── Professionnel / matched ─────────────
  Widget _pro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(item.imageUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy)),
                _location(),
              ],
            ),
          ),
          _resumeAiButton(),
        ]),
        const SizedBox(height: 14),
        if (item.targetRole != null) ...[
          Row(children: [
            const Text('Target role  ',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
            Flexible(
              child: Text(item.targetRole!,
                  style: const TextStyle(color: AppTheme.muted)),
            ),
          ]),
          const SizedBox(height: 14),
        ],
        if (item.softSkills.isNotEmpty) ...[
          const Text('Soft Skills',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 6),
          for (final s in item.softSkills) _skillLine(s),
          const SizedBox(height: 12),
        ],
        if (item.hardSkills.isNotEmpty) ...[
          const Text('Hard Skills',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 6),
          for (final s in item.hardSkills) _skillLine(s),
          const SizedBox(height: 14),
        ],
        _pinkTags(),
      ],
    );
  }

  Widget _skillLine(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(s, style: const TextStyle(color: Color(0xFF555A6B))),
      );

  Widget _resumeAiButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.auto_awesome, size: 14, color: AppTheme.brandBlue),
        SizedBox(width: 4),
        Text('Resume AI',
            style: TextStyle(
                fontSize: 11, color: AppTheme.brandBlue, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _logo(double d) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
            color: const Color(0xFFF1F3F8),
            borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text('G',
            style: TextStyle(
                fontSize: d * 0.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.brandBlue)),
      );

  Widget _location() => Row(children: [
        const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.muted),
        const SizedBox(width: 2),
        Text(item.location,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
      ]);

  Widget _pinkTags() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in item.tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppTheme.brandPink,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(t,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      );
}
