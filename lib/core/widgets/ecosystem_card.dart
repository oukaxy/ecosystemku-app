import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class EcosystemCard extends StatelessWidget {
  const EcosystemCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EcosystemSpacing.x4),
    this.radius = EcosystemRadii.md,
    this.accent,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accent;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final border = accent?.withValues(alpha: 0.35) ?? colors.tokens.border;
    final card = Material(
      color: colors.tokens.surface,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
          ),
          child: child,
        ),
      ),
    );
    if (semanticLabel == null) {
      return card;
    }
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: card,
    );
  }
}
