import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/ecosystem_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return EcosystemScaffold(
      title: 'Setelan',
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(EcosystemSpacing.x4),
            decoration: BoxDecoration(
              color: colors.tokens.surface,
              borderRadius: BorderRadius.circular(EcosystemRadii.md),
              border: Border.all(color: colors.tokens.border),
            ),
            child: Text(
              'Profil, backup, dan kunci AI akan tampil di sini.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
