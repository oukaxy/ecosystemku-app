import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Live2DHost {
  Live2DHost._();

  static const baseUrl = 'http://localhost:8080/';

  static InAppLocalhostServer? _server;

  static bool get isRunning => _server?.isRunning() ?? false;

  static Future<String> ensureStarted() async {
    final existing = _server;
    if (existing != null && existing.isRunning()) return baseUrl;
    await existing?.close();
    final server = InAppLocalhostServer(
      documentRoot: 'assets/live2d/web',
      port: 8080,
    );
    await server.start();
    _server = server;
    return baseUrl;
  }
}
