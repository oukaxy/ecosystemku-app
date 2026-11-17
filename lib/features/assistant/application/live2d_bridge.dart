import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract interface class Live2DBridge {
  Future<void> init({bool muted});
  Future<void> setExpression(String name);
  Future<void> setSpeaking(bool value);
  Future<void> playAudio(String base64, String mime);
  Future<void> stopAudio();
  Future<void> setMuted(bool value);
  Future<void> setPaused(bool value);
  Future<void> tapZone(String zone);
}

final live2dBridgeProvider = StateProvider<Live2DBridge?>((ref) => null);

class WebViewLive2DBridge implements Live2DBridge {
  WebViewLive2DBridge(this.controller);

  final InAppWebViewController controller;

  Future<void> _call(String name, List<Object?> args) async {
    final payload = args.isEmpty ? '' : jsonEncode(args);
    await controller.evaluateJavascript(
      source: 'window.remBridge.$name($payload)',
    );
  }

  @override
  Future<void> init({bool muted = false}) => _call('init', [muted]);

  @override
  Future<void> setExpression(String name) => _call('setExpression', [name]);

  @override
  Future<void> setSpeaking(bool value) => _call('setSpeaking', [value]);

  @override
  Future<void> playAudio(String base64, String mime) =>
      _call('playAudio', [base64, mime]);

  @override
  Future<void> stopAudio() => _call('stopAudio', []);

  @override
  Future<void> setMuted(bool value) => _call('setMuted', [value]);

  @override
  Future<void> setPaused(bool value) => _call('setPaused', [value]);

  @override
  Future<void> tapZone(String zone) => _call('tapZone', [zone]);
}
