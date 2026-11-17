import 'package:ecosystemku/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark tokens match the design spec', () {
    const t = EcosystemTokens.dark;
    expect(t.bg, const Color(0xFF0F0E0C));
    expect(t.surface, const Color(0xFF1A1917));
    expect(t.surfaceAlt, const Color(0xFF232220));
    expect(t.border, const Color(0x0FFFFFFF));
    expect(t.text, const Color(0xFFF0EFE9));
    expect(t.textMuted, const Color(0xFF9A9994));
    expect(t.textSubtle, const Color(0xFF6B6A67));
    expect(t.danger, const Color(0xFFF87171));
    expect(t.success, const Color(0xFF4ADE80));
    expect(t.warning, const Color(0xFFFBBF24));
  });

  test('light tokens match the design spec', () {
    const t = EcosystemTokens.light;
    expect(t.bg, const Color(0xFFF5F4F2));
    expect(t.surface, const Color(0xFFFFFFFF));
    expect(t.surfaceAlt, const Color(0xFFEEEDE9));
    expect(t.text, const Color(0xFF0F0E0C));
  });

  test('app accents match the design spec', () {
    const a = EcosystemAccents.standard;
    expect(a.assistant, const Color(0xFF5B9CF6));
    expect(a.dailyOs, const Color(0xFF2F8F83));
    expect(a.ideku, const Color(0xFF6366F1));
    expect(a.kronik, const Color(0xFFC9A84C));
    expect(a.cucimoney, const Color(0xFF2F5D8A));
    expect(a.linkku, const Color(0xFF8B5CF6));
  });

  test('radii and spacing follow the token scale', () {
    expect(EcosystemRadii.sm, 12);
    expect(EcosystemRadii.md, 16);
    expect(EcosystemRadii.lg, 20);
    expect(
      [
        EcosystemSpacing.x1,
        EcosystemSpacing.x2,
        EcosystemSpacing.x3,
        EcosystemSpacing.x4,
        EcosystemSpacing.x6,
        EcosystemSpacing.x8,
      ],
      [4, 8, 12, 16, 24, 32],
    );
  });
}
