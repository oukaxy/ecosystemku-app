import 'package:flutter/material.dart';


enum AppTargetKind { tab, route, external }

class AppTarget {
  const AppTarget(this.kind, this.location);

  final AppTargetKind kind;
  final String location;
}

class EcosystemApp {
  const EcosystemApp({
    required this.id,
    required this.name,
    required this.icon,
    required this.accent,
    required this.target,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color accent;
  final AppTarget target;
}

const hesychUrl = 'https://www.hesych.com/app.html';

const appCatalog = <EcosystemApp>[
  EcosystemApp(
    id: 'daily-os',
    name: 'Daily OS',
    icon: Icons.check_circle_outline,
    accent: Color(0xFF2F8F83),
    target: AppTarget(AppTargetKind.route, '/app/daily-os'),
  ),
  EcosystemApp(
    id: 'ideku',
    name: 'IdeKu',
    icon: Icons.lightbulb_outline,
    accent: Color(0xFF6366F1),
    target: AppTarget(AppTargetKind.route, '/app/ideku'),
  ),
  EcosystemApp(
    id: 'kronik',
    name: 'Kronik',
    icon: Icons.menu_book_outlined,
    accent: Color(0xFFC9A84C),
    target: AppTarget(AppTargetKind.route, '/app/kronik'),
  ),
  EcosystemApp(
    id: 'cucimoney',
    name: 'CuciMoney+',
    icon: Icons.account_balance_wallet_outlined,
    accent: Color(0xFF2F5D8A),
    target: AppTarget(AppTargetKind.route, '/app/cucimoney'),
  ),
  EcosystemApp(
    id: 'linkku',
    name: 'LinkKu',
    icon: Icons.link_rounded,
    accent: Color(0xFF8B5CF6),
    target: AppTarget(AppTargetKind.route, '/app/linkku'),
  ),
  EcosystemApp(
    id: 'assistant',
    name: 'Asisten',
    icon: Icons.auto_awesome_outlined,
    accent: Color(0xFF5B9CF6),
    target: AppTarget(AppTargetKind.tab, '/assistant'),
  ),
  EcosystemApp(
    id: 'hesych',
    name: 'Hesych',
    icon: Icons.public_rounded,
    accent: Color(0xFF6B6A67),
    target: AppTarget(AppTargetKind.external, hesychUrl),
  ),
];
