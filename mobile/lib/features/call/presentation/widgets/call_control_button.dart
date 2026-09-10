import 'package:flutter/material.dart';

class CallControlButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: backgroundColor ?? Colors.white24,
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
