import 'package:ecosystemku/core/theme/app_theme.dart';
import 'package:ecosystemku/core/theme/tokens.dart';
import 'package:ecosystemku/core/widgets/app_snack_bar.dart';
import 'package:ecosystemku/core/widgets/app_tile.dart';
import 'package:ecosystemku/core/widgets/confirm_sheet.dart';
import 'package:ecosystemku/core/widgets/ecosystem_card.dart';
import 'package:ecosystemku/core/widgets/empty_state.dart';
import 'package:ecosystemku/core/widgets/glass_panel.dart';
import 'package:ecosystemku/core/widgets/loading_skeleton.dart';
import 'package:ecosystemku/core/widgets/section_header.dart';
import 'package:ecosystemku/core/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {TextScaler scaler = TextScaler.noScaling}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: scaler),
    child: MaterialApp(
      theme: EcosystemTheme.dark(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('design system widgets render in dark and light themes', (tester) async {
    for (final theme in [EcosystemTheme.dark(), EcosystemTheme.light()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ListView(
              children: [
                const SectionHeader(title: 'Snapshot Hari Ini'),
                EcosystemCard(child: const Text('card')),
                const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Belum ada data',
                  message: 'Tidak ada yang perlu ditampilkan.',
                ),
                const LoadingSkeleton(width: 100),
                const GlassPanel(child: SizedBox(height: 80)),
                AppTile(
                  label: 'Daily OS',
                  icon: Icons.check_circle_outline,
                  accent: EcosystemAccents.standard.dailyOs,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('stat tile shows error and retries', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _host(
        StatTile(
          label: 'Habit',
          value: '0/0',
          error: 'Tidak tersedia',
          onRetry: () => retried = true,
        ),
      ),
    );
    expect(find.text('Tidak tersedia'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
  });

  testWidgets('stat tile shows skeleton while loading', (tester) async {
    await tester.pumpWidget(
      _host(const StatTile(label: 'Saldo', value: '', isLoading: true)),
    );
    expect(find.byType(LoadingSkeleton), findsNWidgets(2));
  });

  testWidgets('confirm sheet returns the chosen value', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: EcosystemTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final future = ConfirmSheet.show(
      ctx,
      title: 'Hapus data?',
      message: 'Tindakan ini tidak bisa dibatalkan.',
      danger: true,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(await future, isTrue);
  });

  testWidgets('snack bar displays the message', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: EcosystemTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    AppSnackBar.show(ctx, 'Tersimpan', kind: SnackKind.success);
    await tester.pump();
    expect(find.text('Tersimpan'), findsOneWidget);
  });

  testWidgets('widgets survive text scale 1.3', (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            const SectionHeader(title: 'Aplikasi EcosystemKu'),
            const StatTile(label: 'Total Saldo', value: 'Rp 3.520.000', sub: '4 akun'),
            AppTile(
              label: 'CuciMoney+',
              icon: Icons.account_balance_wallet_outlined,
              accent: EcosystemAccents.standard.cucimoney,
              onTap: () {},
            ),
          ],
        ),
        scaler: const TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
