import 'package:flutter/material.dart';

class CallActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const CallActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14),),
          ],
        ),
      ),
    );
  }
}
