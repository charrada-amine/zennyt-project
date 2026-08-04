import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Rangée d'actions du deck : revenir, passer, liker, envoyer.
class FitActionBar extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onSend;
  const FitActionBar({
    super.key,
    required this.onUndo,
    required this.onPass,
    required this.onLike,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _btn(Icons.refresh, AppTheme.muted, onUndo, size: 46),
        _btn(Icons.close, const Color(0xFFE53935), onPass, size: 58),
        _btn(Icons.check, const Color(0xFF22A06B), onLike, size: 58),
        _btn(Icons.send, AppTheme.brandBlue, onSend, size: 46),
      ],
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback onTap, {double size = 56}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: color, size: size * 0.42),
        ),
      ),
    );
  }
}
