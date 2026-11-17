import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/ecosystem_scaffold.dart';
import '../../../core/widgets/section_header.dart';

class AppsHubPage extends StatelessWidget {
  const AppsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return EcosystemScaffold(
      title: 'EcosystemKu',
      body: ListView(
        children: [
          Text(
            'Selamat datang',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: EcosystemSpacing.x1),
          Text(
            'Semua aplikasi dalam satu tempat.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colors.tokens.text,
                ),
          ),
          const SizedBox(height: EcosystemSpacing.x6),
          const SectionHeader(title: 'Aplikasi'),
          const SizedBox(height: EcosystemSpacing.x3),
          Container(
            padding: const EdgeInsets.all(EcosystemSpacing.x4),
            decoration: BoxDecoration(
              color: colors.tokens.surface,
              borderRadius: BorderRadius.circular(EcosystemRadii.md),
              border: Border.all(color: colors.tokens.border),
            ),
            child: Text(
              'Grid aplikasi sedang disiapkan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
