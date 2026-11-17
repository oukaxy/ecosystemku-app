import 'package:flutter/material.dart';

import 'tokens.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.tokens, required this.accents});

  final EcosystemTokens tokens;
  final EcosystemAccents accents;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    EcosystemTokens? tokens,
    EcosystemAccents? accents,
  }) =>
      AppColors(
        tokens: tokens ?? this.tokens,
        accents: accents ?? this.accents,
      );

  @override
  AppColors lerp(covariant AppColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

abstract final class EcosystemTheme {
  static ThemeData dark() => _build(EcosystemTokens.dark, Brightness.dark);

  static ThemeData light() => _build(EcosystemTokens.light, Brightness.light);

  static ThemeData _build(EcosystemTokens t, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: EcosystemAccents.standard.assistant,
      brightness: brightness,
    ).copyWith(
      primary: EcosystemAccents.standard.assistant,
      onPrimary: Colors.white,
      secondary: EcosystemAccents.standard.assistant,
      onSecondary: Colors.white,
      error: t.danger,
      onError: Colors.white,
      surface: t.surface,
      onSurface: t.text,
      surfaceContainerHighest: t.surfaceAlt,
      outline: t.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      canvasColor: t.bg,
      dividerColor: t.border,
      textTheme: _textTheme(t),
      extensions: [
        AppColors(tokens: t, accents: EcosystemAccents.standard),
      ],
      iconTheme: IconThemeData(color: t.textMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg,
        foregroundColor: t.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: EcosystemAccents.standard.assistant.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? EcosystemAccents.standard.assistant
                : t.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? EcosystemAccents.standard.assistant
                : t.textMuted,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceAlt,
        hintStyle: TextStyle(color: t.textSubtle, fontFamily: 'DMSans'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcosystemRadii.sm),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcosystemRadii.sm),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcosystemRadii.sm),
          borderSide: BorderSide(color: EcosystemAccents.standard.assistant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surfaceAlt,
        contentTextStyle: TextStyle(color: t.text, fontFamily: 'DMSans'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EcosystemRadii.sm),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(EcosystemRadii.lg)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(EcosystemTokens t) => TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 36,
          height: 1.05,
          letterSpacing: -0.4,
          color: t.text,
        ),
        displayMedium: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 28,
          height: 1.15,
          letterSpacing: -0.3,
          color: t.text,
        ),
        displaySmall: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 24,
          height: 1.18,
          letterSpacing: -0.2,
          color: t.text,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 22,
          height: 1.15,
          color: t.text,
        ),
        titleLarge: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: t.text,
        ),
        titleMedium: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: t.text,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 15,
          height: 1.45,
          color: t.text,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 13.5,
          height: 1.45,
          color: t.text,
        ),
        bodySmall: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          height: 1.4,
          color: t.textMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: t.text,
        ),
        labelMedium: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: t.textMuted,
        ),
        labelSmall: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: t.textMuted,
        ),
      );
}
