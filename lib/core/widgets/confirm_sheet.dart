import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

abstract final class ConfirmSheet {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Lanjutkan',
    bool danger = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colors = AppColors.of(sheetContext);
        final theme = Theme.of(sheetContext);
        final confirmColor = danger ? colors.tokens.danger : colors.accents.assistant;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            EcosystemSpacing.x6,
            EcosystemSpacing.x6,
            EcosystemSpacing.x6,
            EcosystemSpacing.x6 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: EcosystemSpacing.x2),
              Text(message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: EcosystemSpacing.x6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: EcosystemSpacing.x3),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: confirmColor),
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }
}
