import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../application/live2d_bridge.dart';
import '../application/live2d_host.dart';

class Live2DStage extends ConsumerStatefulWidget {
  const Live2DStage({super.key, this.onEvent});

  final void Function(Map<String, dynamic> event)? onEvent;

  @override
  ConsumerState<Live2DStage> createState() => _Live2DStageState();
}

class _Live2DStageState extends ConsumerState<Live2DStage> {
  String? _url;
  String? _error;
  bool _ready = false;
  WebViewLive2DBridge? _bridge;
  StateController<Live2DBridge?>? _bridgeController;

  @override
  void initState() {
    super.initState();
    _bridgeController = ref.read(live2dBridgeProvider.notifier);
    Live2DHost.ensureStarted().then((url) {
      if (mounted) setState(() => _url = url);
    }).catchError((Object error) {
      if (mounted) setState(() => _error = 'Panggung karakter gagal dimulai.');
    });
  }

  @override
  void dispose() {
    final controller = _bridgeController;
    if (controller != null && controller.state == _bridge) {
      controller.state = null;
    }
    super.dispose();
  }

  void _handleEvent(String raw) {
    Map<String, dynamic> event;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      event = decoded;
    } on FormatException {
      return;
    }

    final type = event['type'];
    if (type == 'ready') {
      setState(() => _ready = true);
    } else if (type == 'modelError') {
      setState(() => _error = 'Model gagal dimuat. Chat tetap bisa dipakai.');
    }
    widget.onEvent?.call(event);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_url == null && _error == null)
          const Center(child: LoadingSkeleton(width: 160, height: 18))
        else if (_error != null)
          _Fallback(error: _error!)
        else
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_url!)),
            initialSettings: InAppWebViewSettings(
              transparentBackground: true,
              javaScriptEnabled: true,
              disableVerticalScroll: true,
              disableHorizontalScroll: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              supportZoom: false,
            ),
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint('Rem console: ${consoleMessage.message}');
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                _error = 'Panggung gagal dimuat ($code).';
              });
            },
            onWebViewCreated: (controller) {
              controller.addJavaScriptHandler(
                handlerName: 'remEvent',
                callback: (args) {
                  if (args.isNotEmpty && args.first is String) {
                    _handleEvent(args.first as String);
                  }
                  return null;
                },
              );
            },
            onLoadStop: (controller, url) async {
              final bridge = WebViewLive2DBridge(controller);
              _bridge = bridge;
              ref.read(live2dBridgeProvider.notifier).state = bridge;
              await bridge.init();
            },
          ),
        if (!_ready && _error == null)
          Positioned(
            left: EcosystemSpacing.x3,
            bottom: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EcosystemSpacing.x3,
                vertical: EcosystemSpacing.x1,
              ),
              decoration: BoxDecoration(
                color: colors.tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(EcosystemRadii.sm),
                border: Border.all(color: colors.tokens.border),
              ),
              child: Text(
                'Menyiapkan Rem…',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EcosystemSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accents.assistant.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.face_retouching_natural_rounded,
                size: 44,
                color: colors.accents.assistant,
              ),
            ),
            const SizedBox(height: EcosystemSpacing.x3),
            Text(
              'Rem mode teks',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: EcosystemSpacing.x1),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
