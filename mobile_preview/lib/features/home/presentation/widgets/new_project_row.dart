import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Ligne "New Project" sous la barre supérieure (entrée de création de post).
class NewProjectRow extends StatelessWidget {
  const NewProjectRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=49'),
          ),
          SizedBox(width: 12),
          Text(
            'New Project',
            style: TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
        ],
      ),
    );
  }
}
