import 'package:ecosystemku/core/theme/app_theme.dart';
import 'package:ecosystemku/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark theme uses the spec background and fonts', () {
    final theme = EcosystemTheme.dark();
    expect(theme.scaffoldBackgroundColor, EcosystemTokens.dark.bg);
    expect(theme.textTheme.displayLarge?.fontFamily, 'DMSerifDisplay');
    expect(theme.textTheme.headlineMedium?.fontFamily, 'DMSerifDisplay');
    expect(theme.textTheme.bodyMedium?.fontFamily, 'DMSans');
    expect(theme.textTheme.labelLarge?.fontFamily, 'DMSans');
  });

  test('light theme uses the spec background', () {
    final theme = EcosystemTheme.light();
    expect(theme.scaffoldBackgroundColor, EcosystemTokens.light.bg);
    expect(theme.textTheme.displayMedium?.color, EcosystemTokens.light.text);
  });

  testWidgets('AppColors exposes tokens and accents', (tester) async {
    late AppColors colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: EcosystemTheme.dark(),
        home: Builder(
          builder: (context) {
            colors = AppColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(colors.tokens.bg, EcosystemTokens.dark.bg);
    expect(colors.accents.assistant, EcosystemAccents.standard.assistant);
  });
}
