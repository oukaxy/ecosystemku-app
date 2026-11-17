import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'features/assistant/application/assistant_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Map<String, dynamic> characterConfig = const {};
  try {
    characterConfig = await loadCharacterConfig();
  } catch (_) {}
  runApp(
    ProviderScope(
      overrides: [
        characterConfigProvider.overrideWithValue(characterConfig),
      ],
      child: const EcosystemApp(),
    ),
  );
}
