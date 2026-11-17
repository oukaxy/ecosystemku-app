import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/ecosystem_scaffold.dart';
import 'sections/account_sections.dart';
import 'sections/data_sections.dart';
import 'sections/misc_sections.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return EcosystemScaffold(
      title: 'Setelan',
      body: ListView(
        children: [
          const ProfileSection(),
          const SizedBox(height: EcosystemSpacing.x6),
          const AiKeysSection(),
          const SizedBox(height: EcosystemSpacing.x6),
          const BackupSection(),
          const SizedBox(height: EcosystemSpacing.x6),
          const AppearanceSection(),
          const SizedBox(height: EcosystemSpacing.x6),
          const NotificationsSection(),
          const SizedBox(height: EcosystemSpacing.x6),
          const DataSection(),
          const SizedBox(height: EcosystemSpacing.x6),
          const AboutSection(),
          const SizedBox(height: EcosystemSpacing.x2),
          Text(
            'EcosystemKu menjaga data di perangkat.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.tokens.textSubtle),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
