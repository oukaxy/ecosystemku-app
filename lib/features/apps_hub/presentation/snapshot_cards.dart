import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/badge_pill.dart';
import '../../../core/widgets/ecosystem_card.dart';
import '../../../core/widgets/loading_skeleton.dart';

class FinanceSnapshotCard extends ConsumerStatefulWidget {
  const FinanceSnapshotCard({super.key});

  @override
  ConsumerState<FinanceSnapshotCard> createState() =>
      _FinanceSnapshotCardState();
}

class _FinanceSnapshotCardState extends ConsumerState<FinanceSnapshotCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final accent = colors.accents.cucimoney;
    final async = ref.watch(financeSummaryProvider);

    return EcosystemCard(
      accent: accent,
      onTap: () => context.go('/app/cucimoney'),
      semanticLabel: 'Ringkasan CuciMoney',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentIconBadge(
                icon: Icons.account_balance_wallet_outlined,
                accent: accent,
              ),
              const SizedBox(width: EcosystemSpacing.x2),
              Expanded(
                child: Text('Total Saldo', style: theme.textTheme.bodySmall),
              ),
              IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: colors.tokens.textMuted,
                ),
                tooltip: _hidden ? 'Tampilkan saldo' : 'Sembunyikan saldo',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (async.isLoading && !async.hasValue) ...[
            const LoadingSkeleton(width: 180, height: 30),
            const SizedBox(height: EcosystemSpacing.x2),
            const LoadingSkeleton(width: 130, height: 12),
          ] else if (async.hasError) ...[
            _SnapshotError(onRetry: () => ref.invalidate(financeSummaryProvider)),
          ] else ...[
            Text(
              _hidden
                  ? '••••••'
                  : formatRupiah(async.valueOrNull?.balance ?? 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displayMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: EcosystemSpacing.x2),
            Divider(color: colors.tokens.border, height: 1),
            const SizedBox(height: EcosystemSpacing.x2),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Pengeluaran Hari Ini: ',
                      style: theme.textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: formatRupiah(async.valueOrNull?.expenseToday ?? 0),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.tokens.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: EcosystemSpacing.x2),
                BadgePill(label: 'CuciMoney+', accent: accent),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class DailyOsSnapshotCard extends ConsumerWidget {
  const DailyOsSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final accent = colors.accents.dailyOs;
    final async = ref.watch(dailyOsSummaryProvider);

    return EcosystemCard(
      accent: accent,
      onTap: () => context.go('/app/daily-os'),
      semanticLabel: 'Ringkasan Daily OS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentIconBadge(
                icon: Icons.check_circle_outline,
                accent: accent,
                size: 24,
                radius: 8,
              ),
              const SizedBox(width: EcosystemSpacing.x2),
              Expanded(
                child: Text('Daily OS', style: theme.textTheme.titleMedium),
              ),
              if (!async.hasError && !(async.isLoading && !async.hasValue))
                BadgePill(
                  label: '${async.valueOrNull?.streak ?? 0} Hari Streak',
                  accent: accent,
                  icon: Icons.local_fire_department_rounded,
                ),
            ],
          ),
          const SizedBox(height: EcosystemSpacing.x3),
          if (async.isLoading && !async.hasValue) ...[
            const LoadingSkeleton(width: 140, height: 14),
            const SizedBox(height: EcosystemSpacing.x2),
            const LoadingSkeleton(height: 6),
          ] else if (async.hasError) ...[
            _SnapshotError(onRetry: () => ref.invalidate(dailyOsSummaryProvider)),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${async.valueOrNull?.habitsDone ?? 0}/${async.valueOrNull?.habitsTotal ?? 0} Habit Selesai',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.tokens.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  formatPercent(
                    async.valueOrNull?.habitsDone ?? 0,
                    async.valueOrNull?.habitsTotal ?? 0,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: EcosystemSpacing.x1),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progress(
                  async.valueOrNull?.habitsDone ?? 0,
                  async.valueOrNull?.habitsTotal ?? 0,
                ),
                minHeight: 6,
                backgroundColor: colors.tokens.surfaceAlt,
                color: accent,
              ),
            ),
            const SizedBox(height: EcosystemSpacing.x3),
            Divider(color: colors.tokens.border, height: 1),
            const SizedBox(height: EcosystemSpacing.x2),
            Row(
              children: [
                Expanded(
                  child: Text('Tugas Harian', style: theme.textTheme.bodySmall),
                ),
                BadgePill(
                  label:
                      '${_pending(async.valueOrNull?.todosDone ?? 0, async.valueOrNull?.todosTotal ?? 0)} To-Do Pending',
                  accent: accent,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double _progress(int done, int total) => total <= 0 ? 0 : done / total;

  int _pending(int done, int total) {
    final pending = total - done;
    return pending < 0 ? 0 : pending;
  }
}

class IdekuSnapshotCard extends ConsumerWidget {
  const IdekuSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = AppColors.of(context).accents.ideku;
    final async = ref.watch(idekuSummaryProvider);

    return EcosystemCard(
      padding: const EdgeInsets.all(EcosystemSpacing.x3),
      accent: accent,
      onTap: () => context.go('/app/ideku'),
      semanticLabel: 'Ringkasan IdeKu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentIconBadge(
                icon: Icons.lightbulb_outline,
                accent: accent,
                size: 24,
                radius: 8,
              ),
              const SizedBox(width: EcosystemSpacing.x1),
              Expanded(
                child: Text('IdeKu', style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: EcosystemSpacing.x2),
          if (async.isLoading && !async.hasValue)
            const LoadingSkeleton(width: 70, height: 24)
          else if (async.hasError)
            _SnapshotError(onRetry: () => ref.invalidate(idekuSummaryProvider))
          else ...[
            Text(
              '${async.valueOrNull?.open ?? 0} Proses',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'Fokus: ${async.valueOrNull?.latestTitle ?? 'Belum ada ide'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class KronikSnapshotCard extends ConsumerWidget {
  const KronikSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = AppColors.of(context).accents.kronik;
    final async = ref.watch(kronikSummaryProvider);

    return EcosystemCard(
      padding: const EdgeInsets.all(EcosystemSpacing.x3),
      accent: accent,
      onTap: () => context.go('/app/kronik'),
      semanticLabel: 'Ringkasan Kronik',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentIconBadge(
                icon: Icons.menu_book_outlined,
                accent: accent,
                size: 24,
                radius: 8,
              ),
              const SizedBox(width: EcosystemSpacing.x1),
              Expanded(
                child: Text('Kronik', style: theme.textTheme.titleMedium),
              ),
              if (!async.hasError && !(async.isLoading && !async.hasValue))
                BadgePill(label: 'Fokus', accent: accent),
            ],
          ),
          const SizedBox(height: EcosystemSpacing.x2),
          if (async.isLoading && !async.hasValue)
            const LoadingSkeleton(height: 34)
          else if (async.hasError)
            _SnapshotError(onRetry: () => ref.invalidate(kronikSummaryProvider))
          else ...[
            Text(
              async.valueOrNull?.isEmpty ?? true
                  ? 'Belum ada catatan hari ini.'
                  : '“${async.valueOrNull?.title}”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Lora',
                fontStyle: FontStyle.italic,
                fontSize: 12.5,
                height: 1.35,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: EcosystemSpacing.x1),
            Text('Jurnal Hari Ini', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _SnapshotError extends StatelessWidget {
  const _SnapshotError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Gagal memuat',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.tokens.danger),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: const Text('Coba lagi'),
        ),
      ],
    );
  }
}
