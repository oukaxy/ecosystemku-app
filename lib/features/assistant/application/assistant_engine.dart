import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live2d_bridge.dart';

abstract interface class AssistantEngine {
  Future<void> attach();

  Future<void> setVisible(bool visible);
}

class NoopAssistantEngine implements AssistantEngine {
  const NoopAssistantEngine();

  @override
  Future<void> attach() async {}

  @override
  Future<void> setVisible(bool visible) async {}
}

class Live2DAssistantEngine implements AssistantEngine {
  Live2DAssistantEngine(this._ref);

  final Ref _ref;

  @override
  Future<void> attach() async {}

  @override
  Future<void> setVisible(bool visible) async {
    final bridge = _ref.read(live2dBridgeProvider);
    if (bridge == null) return;
    await bridge.setPaused(!visible);
    if (!visible) {
      await bridge.stopAudio();
    }
  }
}

final assistantEngineProvider = Provider<AssistantEngine>(
  (ref) => Live2DAssistantEngine(ref),
);
