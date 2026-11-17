import 'package:flutter/material.dart';

@immutable
class EcosystemTokens {
  const EcosystemTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.danger,
    required this.success,
    required this.warning,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textSubtle;
  final Color danger;
  final Color success;
  final Color warning;

  static const dark = EcosystemTokens(
    bg: Color(0xFF0F0E0C),
    surface: Color(0xFF1A1917),
    surfaceAlt: Color(0xFF232220),
    border: Color(0x0FFFFFFF),
    text: Color(0xFFF0EFE9),
    textMuted: Color(0xFF9A9994),
    textSubtle: Color(0xFF6B6A67),
    danger: Color(0xFFF87171),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
  );

  static const light = EcosystemTokens(
    bg: Color(0xFFF5F4F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEEDE9),
    border: Color(0x12000000),
    text: Color(0xFF0F0E0C),
    textMuted: Color(0xFF6B6A67),
    textSubtle: Color(0xFF9A9994),
    danger: Color(0xFFEF4444),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
  );
}

@immutable
class EcosystemAccents {
  const EcosystemAccents({
    required this.assistant,
    required this.dailyOs,
    required this.ideku,
    required this.kronik,
    required this.cucimoney,
    required this.linkku,
  });

  final Color assistant;
  final Color dailyOs;
  final Color ideku;
  final Color kronik;
  final Color cucimoney;
  final Color linkku;

  static const standard = EcosystemAccents(
    assistant: Color(0xFF5B9CF6),
    dailyOs: Color(0xFF2F8F83),
    ideku: Color(0xFF6366F1),
    kronik: Color(0xFFC9A84C),
    cucimoney: Color(0xFF2F5D8A),
    linkku: Color(0xFF8B5CF6),
  );
}

abstract final class EcosystemRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
}

abstract final class EcosystemSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x6 = 24;
  static const double x8 = 32;
}

abstract final class EcosystemDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);
}

Duration resolveDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

const String kApiBase = String.fromEnvironment(
  'ECOSYSTEMKU_API_BASE',
  defaultValue: 'https://ecosystemku.vercel.app',
);
