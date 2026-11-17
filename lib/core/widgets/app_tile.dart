import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'accent_icon_badge.dart';

class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.external = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool external;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.tokens.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.tokens.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AccentIconBadge(icon: icon, accent: accent, size: 40, radius: 12),
                    if (external)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: colors.tokens.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.tokens.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
