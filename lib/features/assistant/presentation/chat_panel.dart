import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../application/assistant_controller.dart';
import '../application/assistant_providers.dart';

class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  double _dragOffset = 0;
  bool _dismissed = false;

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

  void _onDragStart(DragStartDetails details) {
    _dragOffset = 0;
    _dismissed = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dismissed) return;
    _dragOffset += details.delta.dy;
    if (_dragOffset > 36) {
      _dismissed = true;
      widget.onClose?.call();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final dismissed = _dismissed;
    _dragOffset = 0;
    _dismissed = false;
    if (!dismissed && velocity > 300) widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final state = ref.watch(assistantControllerProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.tokens.surfaceAlt.withValues(alpha: 0.86),
            colors.tokens.surface.withValues(alpha: 0.96),
            colors.tokens.surface,
          ],
          stops: const [0, 0.18, 1],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EcosystemRadii.xl),
        ),
        border: Border.all(color: colors.tokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.72),
            blurRadius: 44,
            offset: const Offset(0, -18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                GestureDetector(
                  key: const Key('assistant-sheet-handle'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.tokens.textSubtle
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: colors.tokens.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 20,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    bottom: 0,
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 20,
                                      color: colors.tokens.textSubtle,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Icon(
                                      Icons.chat_bubble_rounded,
                                      size: 11,
                                      color: colors.accents.assistant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      EcosystemSpacing.x4,
                      EcosystemSpacing.x2,
                      EcosystemSpacing.x4,
                      0,
                    ),
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: EcosystemSpacing.x4,
                            ),
                            child: Text(
                              'Tanya apa saja — Rem siap membantu.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(
                            EcosystemSpacing.x4,
                            14,
                            EcosystemSpacing.x4,
                            6,
                          ),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final entry = state.messages[index];
                            final isLast = index == state.messages.length - 1;
                            final typing = isLast &&
                                !entry.isUser &&
                                entry.text.isEmpty &&
                                state.isStreaming;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _Bubble(entry: entry, typing: typing),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EcosystemSpacing.x4,
                    EcosystemSpacing.x2,
                    EcosystemSpacing.x4,
                    EcosystemSpacing.x3,
                  ),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.only(left: 16, right: 6),
                    decoration: BoxDecoration(
                      color: colors.tokens.surfaceAlt,
                      borderRadius: BorderRadius.circular(EcosystemRadii.xl),
                      border: Border.all(color: colors.tokens.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) =>
                                state.isStreaming ? null : _send(),
                            style: theme.textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: 'Ketik pesan...',
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: EcosystemSpacing.x2),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (state.isStreaming
                                        ? colors.tokens.danger
                                        : colors.accents.assistant)
                                    .withValues(alpha: 0.36),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: FilledButton(
                            onPressed: state.isStreaming
                                ? () => ref
                                    .read(assistantControllerProvider.notifier)
                                    .stop()
                                : _send,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                              elevation: 0,
                              backgroundColor: state.isStreaming
                                  ? colors.tokens.danger
                                  : colors.accents.assistant,
                              foregroundColor: colors.tokens.bg,
                            ),
                            child: Icon(
                              state.isStreaming
                                  ? Icons.stop_rounded
                                  : Icons.send_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.entry, required this.typing});

  final ChatEntry entry;
  final bool typing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isUser = entry.isUser;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.82;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.tokens.surfaceAlt,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            isUser ? EcosystemRadii.bubble : 4,
          ),
          topRight: const Radius.circular(EcosystemRadii.bubble),
          bottomLeft: const Radius.circular(EcosystemRadii.bubble),
          bottomRight: Radius.circular(
            isUser ? 4 : EcosystemRadii.bubble,
          ),
        ),
        border: Border.all(color: colors.tokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
    );

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: bubble,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RemAvatar(),
        const SizedBox(width: 10),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth - 42),
            child: bubble,
          ),
        ),
      ],
    );
  }
}

class _RemAvatar extends StatelessWidget {
  const _RemAvatar();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.tokens.bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        'R',
        style: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 15,
          height: 1,
          color: colors.accents.assistant,
        ),
      ),
    );
  }
}
