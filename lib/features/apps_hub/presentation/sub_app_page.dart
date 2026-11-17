import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/ecosystem_scaffold.dart';
import '../../../core/widgets/empty_state.dart';

class SubAppPage extends StatelessWidget {
  const SubAppPage({super.key, required this.appId});

  final String appId;

  @override
  Widget build(BuildContext context) {
    return EcosystemScaffold(
      title: _titleFor(appId),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Hampir siap',
        message: 'Aplikasi $appId akan dibangun pada fase berikutnya.',
        action: FilledButton.tonal(
          onPressed: () => context.go('/apps'),
          child: const Text('Kembali ke Apps'),
        ),
      ),
    );
  }

  String _titleFor(String id) {
    switch (id) {
      case 'daily-os':
        return 'Daily OS';
      case 'ideku':
        return 'IdeKu';
      case 'kronik':
        return 'Kronik';
      case 'cucimoney':
        return 'CuciMoney';
      case 'linkku':
        return 'LinkKu';
      case 'assistant':
        return 'Asisten';
      default:
        return 'EcosystemKu';
    }
  }
}
