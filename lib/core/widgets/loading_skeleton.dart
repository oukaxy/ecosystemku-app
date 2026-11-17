import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
