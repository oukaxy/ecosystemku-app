import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final assistantEngineProvider = Provider<AssistantEngine>(
  (ref) => const NoopAssistantEngine(),
);
