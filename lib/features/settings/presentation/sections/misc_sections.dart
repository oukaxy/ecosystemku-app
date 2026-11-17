import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/ecosystem_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../apps_hub/domain/app_catalog.dart' show hesychUrl;
import '../../data/settings_repository.dart';
import '../../application/settings_providers.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final setting = ref.watch(themeSettingProvider).valueOrNull ??
        ThemeSetting.system;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tampilan'),
        const SizedBox(height: EcosystemSpacing.x2),
        EcosystemCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tema aplikasi', style: theme.textTheme.bodySmall),
              const SizedBox(height: EcosystemSpacing.x1),
              Row(
                children: [
                  for (final option in ThemeSetting.values)
                    Expanded(
                      child: RadioListTile<ThemeSetting>(
                        value: option,
                        groupValue: setting,
                        onChanged: (value) async {
                          if (value == null) return;
                          await ref
                              .read(settingsRepositoryProvider)
                              .setTheme(value);
                          refreshSnapshots(ref);
                          ref.invalidate(themeSettingProvider);
                        },
                        title: Text(
                          optionLabel(option),
                          style: theme.textTheme.bodyMedium,
                        ),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              Text(
                'Warna aksen mengikuti pilihan tema.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.tokens.textSubtle),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String optionLabel(ThemeSetting option) => switch (option) {
        ThemeSetting.system => 'Sistem',
        ThemeSetting.dark => 'Gelap',
        ThemeSetting.light => 'Terang',
      };
}

class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habitTime = ref.watch(settingsValueProvider(SettingsRepository.habitTimeKey))
            .valueOrNull ??
        '07:00';
    final todoTime = ref.watch(settingsValueProvider(SettingsRepository.todoTimeKey))
            .valueOrNull ??
        '20:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Notifikasi'),
        const SizedBox(height: EcosystemSpacing.x2),
        EcosystemCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jadwal pengingat disimpan di sini; '
                'notifikasi terjadwal menyusul.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: EcosystemSpacing.x3),
              _TimeRow(
                label: 'Habit harian',
                value: habitTime,
                onPicked: (value) => _save(ref, SettingsRepository.habitTimeKey, value),
              ),
              const SizedBox(height: EcosystemSpacing.x2),
              _TimeRow(
                label: 'Pengingat todo',
                value: todoTime,
                onPicked: (value) => _save(ref, SettingsRepository.todoTimeKey, value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save(WidgetRef ref, String key, String value) async {
    await ref.read(settingsRepositoryProvider).set(key, value);
    ref.invalidate(settingsValueProvider(key));
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final String value;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        TextButton(
          onPressed: () async {
            final initial = _parse(value);
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
            );
            if (picked != null && context.mounted) {
              onPicked(picked.format(context));
            }
          },
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.accents.assistant,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  TimeOfDay _parse(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 7;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, this.version = '1.0.0'});

  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tentang'),
        const SizedBox(height: EcosystemSpacing.x2),
        EcosystemCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EcosystemKu', style: theme.textTheme.titleMedium),
              Text(
                'Versi $version — data lokal, tanpa cloud.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: EcosystemSpacing.x2),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _open('https://ecosystemku.vercel.app'),
                    icon: const Icon(Icons.language_rounded, size: 18),
                    label: const Text('Web versi lama'),
                  ),
                  const SizedBox(width: EcosystemSpacing.x2),
                  TextButton.icon(
                    onPressed: () => _open(hesychUrl),
                    icon: const Icon(Icons.public_rounded, size: 18),
                    label: const Text('Hesych'),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.tokens.textMuted,
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

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
