import 'package:flutter/material.dart';

class AccentIconBadge extends StatelessWidget {
  const AccentIconBadge({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 28,
    this.radius = 9,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: size * 0.55, color: accent),
    );
  }
}
