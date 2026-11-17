import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/date.dart';
import '../../../core/widgets/app_tile.dart';
import '../../../core/widgets/ecosystem_scaffold.dart';
import '../../../core/widgets/section_header.dart';
import '../domain/app_catalog.dart';
import 'snapshot_cards.dart';

class AppsHubPage extends ConsumerWidget {
  const AppsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final greeting = GreetingData(
      now: ref.watch(clockProvider).now(),
      name: profile?.name ?? 'Pengguna',
    );

    return EcosystemScaffold(
      body: RefreshIndicator(
        color: colors.accents.assistant,
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _Header(greeting: greeting, initial: greeting.name.isEmpty ? 'P' : greeting.name.substring(0, 1)),
            const SizedBox(height: EcosystemSpacing.x6),
            SectionHeader(
              title: 'Snapshot Hari Ini',
              trailing: Text(
                'Ringkasan Lintas App',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: EcosystemSpacing.x3),
            const FinanceSnapshotCard(),
            const SizedBox(height: EcosystemSpacing.x3),
            const DailyOsSnapshotCard(),
            const SizedBox(height: EcosystemSpacing.x3),
            IntrinsicHeight(
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Expanded(child: IdekuSnapshotCard()),
                  SizedBox(width: EcosystemSpacing.x3),
                  Expanded(child: KronikSnapshotCard()),
                ],
              ),
            ),
            const SizedBox(height: EcosystemSpacing.x6),
            SectionHeader(
              title: 'Aplikasi EcosystemKu',
              trailing: Text(
                '${appCatalog.length} Modul',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: EcosystemSpacing.x3),
            const _AppGrid(),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    refreshSnapshots(ref);
    try {
      await Future.wait([
        ref.read(financeSummaryProvider.future),
        ref.read(dailyOsSummaryProvider.future),
        ref.read(idekuSummaryProvider.future),
        ref.read(kronikSummaryProvider.future),
      ]);
    } catch (_) {
      // Each card renders its own error state.
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.initial});

  final GreetingData greeting;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting.dateLabel, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                greeting.headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.displaySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: EcosystemSpacing.x3),
        Stack(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.tokens.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: colors.tokens.border),
              ),
              child: Text(
                initial.toUpperCase(),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.tokens.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.tokens.bg, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AppGrid extends StatelessWidget {
  const _AppGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 6 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appCatalog.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 92,
            crossAxisSpacing: EcosystemSpacing.x2,
            mainAxisSpacing: EcosystemSpacing.x2,
          ),
          itemBuilder: (context, index) {
            final app = appCatalog[index];
            return AppTile(
              label: app.name,
              icon: app.icon,
              accent: app.accent,
              external: app.target.kind == AppTargetKind.external,
              onTap: () => _open(context, app),
            );
          },
        );
      },
    );
  }

  Future<void> _open(BuildContext context, EcosystemApp app) async {
    final target = app.target;
    switch (target.kind) {
      case AppTargetKind.tab:
      case AppTargetKind.route:
        context.go(target.location);
        break;
      case AppTargetKind.external:
        final opened = await launchUrl(
          Uri.parse(target.location),
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak bisa membuka tautan.')),
          );
        }
        break;
    }
  }
}
