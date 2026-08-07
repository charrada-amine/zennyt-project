import 'dart:math';
import 'package:flutter/material.dart';
import 'fit_card_data.dart';

class TinderCard extends StatefulWidget {
  final FitCardData data;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final bool isFront;

  const TinderCard({
    super.key,
    required this.data,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.isFront,
  });

  @override
  State<TinderCard> createState() => _TinderCardState();
}

class _TinderCardState extends State<TinderCard> with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _isDragging = false;
  late Size _screenSize;

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    if (!widget.isFront) {
      return _buildCardContent();
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) => setState(() => _position += details.delta),
      onPanEnd: (_) {
        setState(() => _isDragging = false);
        _handlePanEnd();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final milliseconds = _isDragging ? 0 : 250;
          final angle = (_position.dx / _screenSize.width) * (pi / 12);
          final transform = Matrix4.identity()
            ..translate(_position.dx, _position.dy)
            ..rotateZ(angle);

          return AnimatedContainer(
            duration: Duration(milliseconds: milliseconds),
            curve: Curves.easeOut,
            transform: transform,
            child: _buildCardContent(),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context) {
    // Les pages de détail (offre / candidat) arrivent avec le portage des
    // features jobs et applications — le tap est neutre en attendant.
  }

  void _handlePanEnd() {
    const threshold = 130.0;
    if (_position.dx > threshold) {
      widget.onSwipeRight();
    } else if (_position.dx < -threshold) {
      widget.onSwipeLeft();
    } else {
      setState(() => _position = Offset.zero);
    }
  }

  Widget _buildCardContent() {
    final d = widget.data;

    const Color primaryColor = Color(0xFF0D2146);
    const Color secondaryColor = Color(0xFF64748B);
    const Color accentColor = Color(0xFFD82C74);
    const Color dividerColor = Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFF1F5F9),
            Color(0xFFBACCEE),
          ],
          stops: [0.0, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: NetworkImage(d.avatarUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: secondaryColor),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              d.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: secondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B3B7B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Resume AI',
                      style: TextStyle(
                        fontSize: 10,
                        color: secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(flex: 1),

            Row(
              children: [
                Text(
                  '${d.primaryLabel}   ',
                  style: const TextStyle(
                    fontSize: 13,
                    color: secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(
                    d.primaryValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 1),
            const Divider(color: dividerColor, thickness: 1),
            const Spacer(flex: 1),

            Text(
              d.section1Title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            ...d.section1Stats.map(
              (s) => _buildStatRow(s.label, s.value, primaryColor, secondaryColor),
            ),

            const Spacer(flex: 1),

            Text(
              d.section2Title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            ...d.section2Stats.map(
              (s) => _buildStatRow(s.label, s.value, primaryColor, secondaryColor),
            ),

            const Spacer(flex: 1),
            const Divider(color: dividerColor, thickness: 1),
            const Spacer(flex: 2),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: d.tags.map((t) => _buildPillTag(t, accentColor)).toList(),
            ),

            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color primary, Color secondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: secondary, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}