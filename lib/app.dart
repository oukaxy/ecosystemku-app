import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';

class EcosystemApp extends StatelessWidget {
  const EcosystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcosystemKu',
      debugShowCheckedModeBanner: false,
      theme: EcosystemTheme.light(),
      darkTheme: EcosystemTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _BootstrapPage(),
    );
  }
}

class _BootstrapPage extends StatelessWidget {
  const _BootstrapPage();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EcosystemSpacing.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EcosystemKu', style: TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 36,
                color: colors.tokens.text,
              )),
              const SizedBox(height: EcosystemSpacing.x2),
              Text(
                'Asisten, Apps, dan Setelan sedang disiapkan.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
