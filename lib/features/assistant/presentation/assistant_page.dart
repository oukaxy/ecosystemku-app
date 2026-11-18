import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../application/assistant_providers.dart';
import 'chat_panel.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  bool _chatOpen = true;

  void _toggleChat() {
    if (_chatOpen) FocusScope.of(context).unfocus();
    setState(() => _chatOpen = !_chatOpen);
  }

  void _showSettingsSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pengaturan karakter segera hadir')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final buildStage = ref.watch(live2dStageBuilderProvider);

    return Scaffold(
      backgroundColor: colors.tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            _AssistantHeader(
              chatOpen: _chatOpen,
              onSettings: _showSettingsSoon,
              onToggleChat: _toggleChat,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sheetHeight = constraints.maxHeight * 0.44;
                  final duration =
                      resolveDuration(context, EcosystemDurations.slow);
                  return ClipRect(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            key: const Key('assistant-stage'),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, 0.15),
                                radius: 0.85,
                                colors: [
                                  colors.accents.assistant
                                      .withValues(alpha: 0.18),
                                  colors.accents.assistant
                                      .withValues(alpha: 0.05),
                                  colors.accents.assistant
                                      .withValues(alpha: 0),
                                ],
                              ),
                            ),
                            child: Builder(builder: buildStage),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          left: 0,
                          right: 0,
                          bottom: _chatOpen ? 0 : -sheetHeight - 80,
                          height: sheetHeight,
                          child: IgnorePointer(
                            ignoring: !_chatOpen,
                            child: ChatPanel(onClose: _toggleChat),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({
    required this.chatOpen,
    required this.onSettings,
    required this.onToggleChat,
  });

  final bool chatOpen;
  final VoidCallback onSettings;
  final VoidCallback onToggleChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EcosystemSpacing.x6,
        EcosystemSpacing.x3,
        EcosystemSpacing.x6,
        EcosystemSpacing.x2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rem', style: theme.textTheme.displayLarge),
                const SizedBox(height: EcosystemSpacing.x1),
                Text(
                  'AI Companion',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    letterSpacing: 0.26,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _GlassButton(
                label: 'Pengaturan karakter',
                icon: Icons.settings_outlined,
                onTap: onSettings,
              ),
              const SizedBox(height: 10),
              _GlassButton(
                key: const Key('assistant-chat-toggle'),
                label: chatOpen ? 'Tutup chat' : 'Buka chat',
                icon: Icons.chat_bubble_outline_rounded,
                active: chatOpen,
                onTap: onToggleChat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(EcosystemRadii.sm);
    final accent = colors.accents.assistant;
    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: colors.tokens.surface.withValues(alpha: 0.78),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color:
                  active ? accent.withValues(alpha: 0.55) : colors.tokens.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                size: 19,
                color: active ? accent : colors.tokens.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
