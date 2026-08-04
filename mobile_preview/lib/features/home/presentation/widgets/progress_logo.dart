import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Logo "Progress Careers" : pastille dégradée + texte bicolore.
class ProgressLogo extends StatelessWidget {
  final double size;
  const ProgressLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 8,
          height: size + 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.brandBlue, AppTheme.brandPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text('G',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.62)),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'PROGRESS ',
              style: TextStyle(
                  color: AppTheme.brandBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.62,
                  letterSpacing: 0.5),
            ),
            TextSpan(
              text: 'Careers',
              style: TextStyle(
                  color: AppTheme.brandPink,
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.62),
            ),
          ]),
        ),
      ],
    );
  }
}
