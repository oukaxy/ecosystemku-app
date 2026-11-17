import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../application/assistant_providers.dart';
import 'chat_panel.dart';

class AssistantPage extends ConsumerWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final buildStage = ref.watch(live2dStageBuilderProvider);

    return Scaffold(
      backgroundColor: colors.tokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EcosystemSpacing.x3),
          child: Column(
            children: [
              Expanded(
                flex: 58,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Builder(builder: buildStage),
                    Positioned(
                      top: EcosystemSpacing.x3,
                      left: EcosystemSpacing.x3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EcosystemSpacing.x3,
                          vertical: EcosystemSpacing.x1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.tokens.surface.withValues(alpha: 0.85),
                          borderRadius:
                              BorderRadius.circular(EcosystemRadii.sm),
                          border: Border.all(color: colors.tokens.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.accents.assistant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: EcosystemSpacing.x2),
                            Text(
                              'Rem',
                              style: theme.textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EcosystemSpacing.x3),
              const Expanded(
                flex: 42,
                child: ChatPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
