import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/security/secure_keys.dart';

/// Masked value (last 4 chars) for each AI provider key.
final maskedKeyProvider = FutureProvider.family<String?, AiProvider>(
  (ref, provider) => ref.watch(secureKeysProvider).masked(provider),
);

/// Generic app_meta value lookup for settings rows.
final settingsValueProvider = FutureProvider.family<String?, String>(
  (ref, key) => ref.watch(settingsRepositoryProvider).get(key),
);
