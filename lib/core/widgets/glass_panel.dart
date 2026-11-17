import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = EcosystemRadii.lg,
    this.blur = 22,
    this.borderColor,
  });

  final Widget child;
  final double radius;
  final double blur;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.tokens.surfaceAlt.withValues(alpha: 0.86),
                colors.tokens.surface,
              ],
            ),
            border: Border(
              top: BorderSide(color: borderColor ?? colors.tokens.border),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
