import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../application/assistant_controller.dart';
import '../application/assistant_providers.dart';

class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final controller = ref.read(assistantControllerProvider.notifier);
    controller.send(_input.text);
    _input.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: resolveDuration(context, EcosystemDurations.normal),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final state = ref.watch(assistantControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.tokens.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(EcosystemRadii.lg),
        border: Border.all(color: colors.tokens.border),
      ),
      padding: const EdgeInsets.all(EcosystemSpacing.x3),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: colors.accents.assistant,
              ),
              const SizedBox(width: EcosystemSpacing.x2),
              Expanded(
                child: Text('Ngobrol dengan Rem', style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: EcosystemSpacing.x2),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: EcosystemSpacing.x2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  state.error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.tokens.danger),
                ),
              ),
            ),
          Expanded(
            child: state.messages.isEmpty
                ? Center(
                    child: Text(
                      'Tanya apa saja — Rem siap membantu.',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final entry = state.messages[index];
                      final isLast = index == state.messages.length - 1;
                      final typing = isLast &&
                          !entry.isUser &&
                          entry.text.isEmpty &&
                          state.isStreaming;
                      return _Bubble(
                        entry: entry,
                        typing: typing,
                        accent: colors.accents.assistant,
                      );
                    },
                  ),
          ),
          const SizedBox(height: EcosystemSpacing.x2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => state.isStreaming ? null : _send(),
                  style: theme.textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan…',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: EcosystemSpacing.x3,
                      vertical: EcosystemSpacing.x2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: EcosystemSpacing.x2),
              SizedBox(
                width: 44,
                height: 44,
                child: FilledButton(
                  onPressed: state.isStreaming
                      ? () =>
                          ref.read(assistantControllerProvider.notifier).stop()
                      : _send,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: state.isStreaming
                        ? colors.tokens.danger
                        : colors.accents.assistant,
                  ),
                  child: Icon(
                    state.isStreaming ? Icons.stop_rounded : Icons.send_rounded,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.entry,
    required this.typing,
    required this.accent,
  });

  final ChatEntry entry;
  final bool typing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isUser = entry.isUser;
    final bubbleColor =
        isUser ? accent.withValues(alpha: 0.16) : colors.tokens.surfaceAlt;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: EcosystemSpacing.x1),
        padding: const EdgeInsets.symmetric(
          horizontal: EcosystemSpacing.x3,
          vertical: EcosystemSpacing.x2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(EcosystemRadii.md),
            topRight: const Radius.circular(EcosystemRadii.md),
            bottomLeft: Radius.circular(isUser ? EcosystemRadii.md : 4),
            bottomRight: Radius.circular(isUser ? 4 : EcosystemRadii.md),
          ),
          border: Border.all(color: colors.tokens.border),
        ),
        child: typing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: colors.tokens.textSubtle,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              )
            : Text(
                entry.text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.tokens.text),
              ),
      ),
    );
  }
}
