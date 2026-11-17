import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/settings_repository.dart';

class EcosystemApp extends ConsumerWidget {
  const EcosystemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSetting = ref.watch(themeSettingProvider).valueOrNull;
    return MaterialApp.router(
      title: 'EcosystemKu',
      debugShowCheckedModeBanner: false,
      theme: EcosystemTheme.light(),
      darkTheme: EcosystemTheme.dark(),
      themeMode: _themeModeOf(themeSetting),
      routerConfig: ref.watch(routerProvider),
    );
  }

  ThemeMode _themeModeOf(ThemeSetting? setting) => switch (setting) {
        ThemeSetting.light => ThemeMode.light,
        ThemeSetting.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
