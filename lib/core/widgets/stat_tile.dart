import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'accent_icon_badge.dart';
import 'ecosystem_card.dart';
import 'loading_skeleton.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.icon,
    this.accent,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? sub;
  final IconData? icon;
  final Color? accent;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final accentColor = accent ?? colors.accents.assistant;
    return EcosystemCard(
      accent: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                AccentIconBadge(icon: icon!, accent: accentColor),
                const SizedBox(width: EcosystemSpacing.x2),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: EcosystemSpacing.x2),
          if (isLoading) ...[
            const LoadingSkeleton(width: 120, height: 26),
            const SizedBox(height: EcosystemSpacing.x2),
            const LoadingSkeleton(width: 80, height: 12),
          ] else if (error != null) ...[
            Text(
              error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.tokens.danger),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
          ] else ...[
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (compact ? theme.textTheme.headlineMedium : theme.textTheme.displayMedium)
                  ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            if (sub != null)
              Text(
                sub!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}
