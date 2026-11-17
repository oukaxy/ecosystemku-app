class AssistantTagResult {
  const AssistantTagResult({
    required this.text,
    required this.expression,
    this.openApp,
  });

  final String text;
  final String expression;
  final String? openApp;
}

/// Parses Rem's `[EXPR:x]` and `[OPEN:app]` tags.
///
/// Valid expressions are the 13 Rem expressions plus `none`. Unknown names
/// and the legacy `navi`/`wait`/`bound` names map to `none`. A dangling
/// partial tag at the end of a streaming buffer (`[EXP`, `[EXPR:hap`) is
/// stripped so half-written tags never reach the chat bubble.
abstract final class AssistantTags {
  static const Set<String> validExpressions = {
    'happy', 'smile', 'shame', 'sad', 'cry', 'angry', 'surprise',
    'serious', 'proud', 'doubt', 'puzzle', 'upset', 'appeal', 'none',
  };

  static const Set<String> legacyAliases = {'navi', 'wait', 'bound'};

  static final _exprTag = RegExp(r'\[EXPR:([a-zA-Z]+)\]');
  static final _openTag = RegExp(r'\[OPEN:([a-zA-Z0-9_-]+)\]');
  static final _danglingTag = RegExp(r'\[(?:EXPR|OPEN)?:?[^\]]*$');

  static AssistantTagResult parse(String raw) {
    var text = raw;
    String? expression;
    String? openApp;

    final exprMatches = _exprTag.allMatches(text).toList();
    if (exprMatches.isNotEmpty) {
      final name = exprMatches.last.group(1)!.toLowerCase();
      expression = normalizeExpression(name);
      text = text.replaceAll(_exprTag, '');
    }
    final openMatches = _openTag.allMatches(text).toList();
    if (openMatches.isNotEmpty) {
      openApp = openMatches.last.group(1)!.toLowerCase();
      text = text.replaceAll(_openTag, '');
    }
    text = text.replaceAll(_danglingTag, '').trim();
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ');

    return AssistantTagResult(
      text: text,
      expression: expression ?? 'none',
      openApp: openApp,
    );
  }

  static String normalizeExpression(String name) {
    final lowered = name.toLowerCase().trim();
    if (legacyAliases.contains(lowered)) return 'none';
    if (validExpressions.contains(lowered)) return lowered;
    return 'none';
  }
}
