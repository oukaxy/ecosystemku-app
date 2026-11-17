import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum SnackKind { info, success, error }

abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackKind kind = SnackKind.info,
  }) {
    final colors = AppColors.of(context);
    final (icon, color) = switch (kind) {
      SnackKind.info => (Icons.info_outline_rounded, colors.accents.assistant),
      SnackKind.success => (Icons.check_circle_outline_rounded, colors.tokens.success),
      SnackKind.error => (Icons.error_outline_rounded, colors.tokens.danger),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(message, maxLines: 3)),
            ],
          ),
        ),
      );
  }
}
