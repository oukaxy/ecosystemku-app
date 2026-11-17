import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/security/secure_keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/ecosystem_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../data/profile_repository.dart';
import '../settings_providers.dart';

class ProfileSection extends ConsumerStatefulWidget {
  const ProfileSection({super.key});

  @override
  ConsumerState<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<ProfileSection> {
  late final TextEditingController _name;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;

    if (!_dirty && _name.text.isEmpty && profile != null) {
      _name.text = profile.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Profil'),
        const SizedBox(height: EcosystemSpacing.x2),
        EcosystemCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama panggilan', style: theme.textTheme.bodySmall),
              const SizedBox(height: EcosystemSpacing.x1),
              TextField(
                controller: _name,
                onChanged: (_) => setState(() => _dirty = true),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: EcosystemSpacing.x3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dipakai untuk sapaan di Apps dan asisten.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: _dirty ? () => _save(context) : null,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(profileRepositoryProvider).save(name: _name.text);
    refreshSnapshots(ref);
    ref.invalidate(profileProvider);
    if (!mounted) return;
    setState(() => _dirty = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Profil disimpan.')),
    );
  }
}

class AiKeysSection extends ConsumerStatefulWidget {
  const AiKeysSection({super.key});

  @override
  ConsumerState<AiKeysSection> createState() => _AiKeysSectionState();
}

class _AiKeysSectionState extends ConsumerState<AiKeysSection> {
  final _controllers = {
    for (final provider in AiProvider.values)
      provider: TextEditingController(),
  };
  bool _visible = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Kunci AI'),
        const SizedBox(height: EcosystemSpacing.x2),
        EcosystemCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kunci hanya tersimpan di perangkat (secure storage) '
                'dan tidak pernah ikut backup.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: EcosystemSpacing.x3),
              for (final provider in AiProvider.values) ...[
                _KeyRow(
                  provider: provider,
                  controller: _controllers[provider]!,
                  visible: _visible,
                ),
                const SizedBox(height: EcosystemSpacing.x2),
              ],
              const SizedBox(height: EcosystemSpacing.x1),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tanpa kunci, fitur AI memakai mode server.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: Text(_visible ? 'Sembunyikan' : 'Tampilkan'),
                  ),
                ],
              ),
              const SizedBox(height: EcosystemSpacing.x1),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => _deleteAll(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.tokens.danger,
                    ),
                    child: const Text('Hapus semua kunci'),
                  ),
                  const SizedBox(width: EcosystemSpacing.x2),
                  FilledButton(
                    onPressed: () => _saveKeys(context),
                    child: const Text('Simpan kunci'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveKeys(BuildContext context) async {
    final keys = ref.read(secureKeysProvider);
    final messenger = ScaffoldMessenger.of(context);
    var saved = 0;
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty || value.startsWith('•')) continue;
      await keys.save(entry.key, value);
      saved++;
    }
    for (final controller in _controllers.values) {
      controller.clear();
    }
    ref.invalidate(maskedKeyProvider);
    if (!mounted) return;
    setState(() {});
    messenger.showSnackBar(
      SnackBar(content: Text(saved == 0 ? 'Tidak ada kunci baru.' : 'Kunci disimpan.')),
    );
  }

  Future<void> _deleteAll(BuildContext context) async {
    final keys = ref.read(secureKeysProvider);
    final messenger = ScaffoldMessenger.of(context);
    await keys.deleteAll();
    ref.invalidate(maskedKeyProvider);
    if (!mounted) return;
    setState(() {});
    messenger.showSnackBar(
      const SnackBar(content: Text('Semua kunci dihapus.')),
    );
  }
}

class _KeyRow extends ConsumerWidget {
  const _KeyRow({
    required this.provider,
    required this.controller,
    required this.visible,
  });

  final AiProvider provider;
  final TextEditingController controller;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final masked = ref.watch(maskedKeyProvider(provider)).valueOrNull;

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            providerLabel(provider),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: !visible,
            autocorrect: false,
            enableSuggestions: false,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              hintText: masked ?? 'Belum diatur',
              hintStyle:
                  theme.textTheme.bodySmall?.copyWith(color: colors.tokens.textSubtle),
            ),
          ),
        ),
      ],
    );
  }

  String providerLabel(AiProvider provider) => switch (provider) {
        AiProvider.sumopod => 'Sumopod',
        AiProvider.groq => 'Groq',
        AiProvider.fish => 'Fish',
      };
}
