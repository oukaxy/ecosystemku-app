import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/backup/backup_model.dart';
import '../../../../core/db/clock.dart';
import '../../../../core/db/daos/backup_dao.dart';
import '../../../../core/db/database.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/ecosystem_card.dart';
import '../../../../core/widgets/section_header.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Backup'),
        const SizedBox(height: EcosystemSpacing.x2),
        EcosystemCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ZIP v3 kompatibel dengan web lama. Kunci AI tidak ikut; '
                'link privat terenkripsi dengan PIN.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: EcosystemSpacing.x3),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _export(context, ref),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.ios_share_rounded, size: 18),
                          SizedBox(width: EcosystemSpacing.x2),
                          Text('Ekspor sekarang'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: EcosystemSpacing.x2),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _import(context, ref),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_open_outlined, size: 18),
                          SizedBox(width: EcosystemSpacing.x2),
                          Text('Impor'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final service = ref.read(backupServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    String? pin;
    try {
      pin = await _askPin(context, title: 'PIN link privat (boleh kosong)');
      final bytes = await service.exportBytes(pin: (pin == null || pin.isEmpty) ? null : pin);
      final name = 'ecosystemku-backup-${todayString(SystemClock())}.zip';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'application/zip',
            name: name,
          ),
        ],
        subject: 'Backup EcosystemKu',
      );
    } on PrivateLinksNeedPin {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ada link privat: isi PIN atau hapus dulu PIN-nya.'),
        ),
      );
    } on BackupException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ekspor gagal. Coba lagi.')),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final service = ref.read(backupServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );
      final file = picked?.files.single;
      if (file == null || file.bytes == null) return;

      final inspection = await service.inspect(file.bytes!);
      if (!context.mounted) return;
      final mode = await _confirmImport(context, inspection);
      if (mode == null) return;

      String? pin;
      if (inspection.warnings.any((w) => w.contains('PIN'))) {
        if (!context.mounted) return;
        pin = await _askPin(context, title: 'PIN link privat');
      }

      final result = await service.import(
        file.bytes!,
        mode: mode,
        pin: (pin == null || pin.isEmpty) ? null : pin,
      );
      refreshSnapshots(ref);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Impor selesai. ${result.imported.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
          ),
        ),
      );
    } on BackupException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Impor gagal. Data tidak berubah.')),
      );
    }
  }

  Future<String?> _askPin(
    BuildContext context, {
    required String title,
  }) async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration: const InputDecoration(hintText: 'PIN 4-8 digit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    controller.dispose();
    return pin;
  }

  Future<BackupImportMode?> _confirmImport(
    BuildContext context,
    BackupInspection inspection,
  ) {
    final counts = inspection.manifest.counts
        .map((key, value) => MapEntry(key, '$key: $value'))
        .values
        .join('\n');
    return showDialog<BackupImportMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impor backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(counts),
            for (final warning in inspection.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  warning,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Merge menggabungkan by id (yang lebih baru menang). '
              'Replace menghapus data lokal dulu.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, BackupImportMode.replace),
            child: const Text('Replace'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, BackupImportMode.merge),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }
}

class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider).valueOrNull;
    final name = profile?.name ?? 'Pengguna';
    final messenger = ScaffoldMessenger.of(context);
    final typed = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Hapus semua data?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semua habit, todo, ide, jurnal, keuangan, dan tautan '
                'akan dihapus permanen. Ketik "$name" untuk konfirmasi.',
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => TextField(
                  controller: controller,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: name),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: value.text.trim() == name
                    ? () => Navigator.pop(context, value.text.trim())
                    : null,
                child: const Text('Hapus'),
              ),
            ),
          ],
        );
      },
    );

    if (typed != name) return;
    final dao = BackupDao(ref.read(databaseProvider));
    await dao.clearTables(backupTableNames);
    refreshSnapshots(ref);
    ref
      ..invalidate(profileProvider)
      ..invalidate(themeSettingProvider)
      ..invalidate(dailyOsSummaryProvider)
      ..invalidate(financeSummaryProvider)
      ..invalidate(idekuSummaryProvider)
      ..invalidate(kronikSummaryProvider)
      ..invalidate(linkkuSummaryProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Semua data dihapus.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Data'),
        const SizedBox(height: EcosystemSpacing.x2),
        EcosystemCard(
          accent: colors.tokens.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hapus semua data',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: colors.tokens.danger),
              ),
              const SizedBox(height: EcosystemSpacing.x1),
              Text(
                'Kunci AI tidak ikut dihapus.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: EcosystemSpacing.x3),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.tokens.danger,
                ),
                onPressed: () => _deleteAll(context, ref),
                child: const Text('Hapus semua'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
