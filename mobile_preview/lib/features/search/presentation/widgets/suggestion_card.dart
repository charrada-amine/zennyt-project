import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/suggestion.dart';

/// Carte de suggestion (grille). Bandeau "fit score" + corps selon le type.
class SuggestionCard extends StatelessWidget {
  final Suggestion s;
  const SuggestionCard({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2DEF7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _banner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: s.kind == SuggestionKind.jobOffer ? _jobBody() : _proBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      color: AppTheme.brandBlue,
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      child: Row(
        children: [
          Text('${s.fitScore}% Fit score',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          const Icon(Icons.more_vert, color: Colors.white70, size: 16),
        ],
      ),
    );
  }

  Widget _jobBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _logo(),
          const SizedBox(width: 6),
          Flexible(
            child: Text(s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(s.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.navy)),
        const SizedBox(height: 2),
        _location(),
        const SizedBox(height: 8),
        _tags(),
        const Spacer(),
        if (s.salary != null)
          Align(
            alignment: Alignment.centerRight,
            child: Text(s.salary!,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandBlue)),
          ),
      ],
    );
  }

  Widget _proBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          CircleAvatar(radius: 14, backgroundImage: NetworkImage(s.imageUrl)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy)),
                _location(),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(s.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy)),
        const SizedBox(height: 8),
        _tags(),
      ],
    );
  }

  Widget _logo() {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F3F8)),
      alignment: Alignment.center,
      child: const Text('G',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.brandBlue)),
    );
  }

  Widget _location() {
    return Row(children: [
      const Icon(Icons.location_on_outlined, size: 11, color: AppTheme.muted),
      const SizedBox(width: 2),
      Flexible(
        child: Text(s.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
      ),
    ]);
  }

  Widget _tags() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final t in s.tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F0F4),
                borderRadius: BorderRadius.circular(6)),
            child: Text(t,
                style: const TextStyle(fontSize: 9, color: Color(0xFF5F6275))),
          ),
      ],
    );
  }
}
