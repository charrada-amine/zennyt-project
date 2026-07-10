import 'package:flutter/material.dart';
import '../../domain/cv_parsed_data.dart';

class CvSkillChip extends StatelessWidget {
  final CvParsedSkill skill;

  const CvSkillChip({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final isTechnical = skill.type == 'TECHNICAL';
    return Chip(
      label: Text(skill.name),
      backgroundColor: isTechnical ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isTechnical ? Colors.blue[700] : Colors.green[700],
        fontSize: 12,
      ),
      side: BorderSide.none,
    );
  }
}
