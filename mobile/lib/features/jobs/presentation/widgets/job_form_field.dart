import 'package:flutter/material.dart';

class JobFormField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool showPen;

  const JobFormField({
    super.key,
    required this.label,
    this.value,
    required this.onTap,
    this.showPen = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasValue ? value! : label,
              style: TextStyle(
                fontSize: 15,
                color: hasValue ? const Color(0xFF232323) : const Color(0xFF7C8393),
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF21438A).withValues(alpha: 0.05),
              ),
              child: Icon(
                showPen ? Icons.edit_outlined : Icons.add,
                size: 14,
                color: const Color(0xFF21438A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
