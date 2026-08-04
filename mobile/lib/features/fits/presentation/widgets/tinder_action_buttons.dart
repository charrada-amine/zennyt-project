import 'package:flutter/material.dart';

class TinderActionButtons extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onReject;
  final VoidCallback onApprove;
  final VoidCallback onForward;
  final bool canUndo;

  const TinderActionButtons({
    super.key,
    required this.onUndo,
    required this.onReject,
    required this.onApprove,
    required this.onForward,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.refresh,
            color: const Color(0xFF2563EB),
            backgroundColor: Colors.white,
            onTap: canUndo ? onUndo : null,
            size: 46,
            iconSize: 22,
          ),
          _buildActionButton(
            icon: Icons.close,
            color: const Color(0xFFE11D48),
            backgroundColor: Colors.white,
            onTap: onReject,
            size: 56,
            iconSize: 28,
            hasShadow: true,
          ),
          _buildActionButton(
            icon: Icons.check,
            color: const Color(0xFF10B981),
            backgroundColor: Colors.white,
            onTap: onApprove,
            size: 56,
            iconSize: 28,
            hasShadow: true,
          ),
          _buildActionButton(
            icon: Icons.send,
            color: Colors.white,
            backgroundColor: const Color(0xFFD91B5C),
            onTap: onForward,
            size: 46,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback? onTap,
    required double size,
    required double iconSize,
    bool hasShadow = false,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : null,
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}