import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/apps_hub/presentation/apps_hub_page.dart';
import '../../features/apps_hub/presentation/sub_app_page.dart';
import '../../features/assistant/presentation/assistant_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/shell/shell_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/apps',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant',
                builder: (context, state) => const AssistantPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/apps',
                builder: (context, state) => const AppsHubPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/app/:appId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            SubAppPage(appId: state.pathParameters['appId'] ?? ''),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

final _rootNavigatorKey = GlobalKey<NavigatorState>();
