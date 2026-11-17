import 'package:flutter/material.dart';

class BadgePill extends StatelessWidget {
  const BadgePill({
    super.key,
    required this.label,
    required this.accent,
    this.icon,
  });

  final String label;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textColor = Color.lerp(accent, Colors.white, 0.35)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
