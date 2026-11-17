import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ecosystem_scaffold.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return EcosystemScaffold(
      title: 'Asisten',
      body: EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'Rem sedang disiapkan',
        message: 'Panggung Live2D dan obrolan akan tampil di sini.',
        action: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EcosystemSpacing.x4,
            vertical: EcosystemSpacing.x2,
          ),
          decoration: BoxDecoration(
            color: colors.accents.assistant.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(EcosystemRadii.lg),
          ),
          child: Text(
            'Segera hadir',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.accents.assistant,
                ),
          ),
        ),
      ),
    );
  }
}
