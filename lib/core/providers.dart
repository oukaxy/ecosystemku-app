import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup/backup_service.dart';
import 'db/clock.dart';
import 'db/daos/backup_dao.dart';
import 'db/daos/daily_os_dao.dart';
import 'db/daos/finance_dao.dart';
import 'db/daos/ideku_dao.dart';
import 'db/daos/kronik_dao.dart';
import 'db/daos/linkku_dao.dart';
import 'db/daos/meta_dao.dart';
import 'db/database.dart';
import 'security/link_crypto.dart';
import 'security/secure_keys.dart';
import 'security/secure_store.dart';
import '../features/cucimoney/data/finance_repository.dart';
import '../features/cucimoney/data/finance_summary.dart';
import '../features/daily_os/data/daily_os_repository.dart';
import '../features/daily_os/data/daily_os_summary.dart';
import '../features/ideku/data/ideku_repository.dart';
import '../features/ideku/data/ideku_summary.dart';
import '../features/kronik/data/kronik_repository.dart';
import '../features/kronik/data/kronik_summary.dart';
import '../features/linkku/data/linkku_repository.dart';
import '../features/linkku/data/linkku_summary.dart';
import '../features/settings/data/profile_repository.dart';
import '../features/settings/data/settings_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(_openDatabase());
  ref.onDispose(db.close);
  return db;
});

LazyDatabase _openDatabase() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'ecosystemku.sqlite'));
      return NativeDatabase.createInBackground(file);
    });

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final secureStoreProvider = Provider<SecureStore>((ref) => FlutterSecureStore());
final secureKeysProvider = Provider<SecureKeys>(
  (ref) => SecureKeys(ref.watch(secureStoreProvider)),
);
final linkCryptoProvider = Provider<LinkCrypto>((ref) => LinkCrypto());

final backupDaoProvider = Provider<BackupDao>(
  (ref) => BackupDao(ref.watch(databaseProvider)),
);
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    db: ref.watch(databaseProvider),
    dao: ref.watch(backupDaoProvider),
    crypto: ref.watch(linkCryptoProvider),
    clock: ref.watch(clockProvider),
  ),
);

final metaDaoProvider = Provider<MetaDao>(
  (ref) => MetaDao(ref.watch(databaseProvider)),
);
final dailyOsDaoProvider = Provider<DailyOsDao>(
  (ref) => DailyOsDao(ref.watch(databaseProvider)),
);
final idekuDaoProvider = Provider<IdekuDao>(
  (ref) => IdekuDao(ref.watch(databaseProvider)),
);
final kronikDaoProvider = Provider<KronikDao>(
  (ref) => KronikDao(ref.watch(databaseProvider)),
);
final financeDaoProvider = Provider<FinanceDao>(
  (ref) => FinanceDao(ref.watch(databaseProvider)),
);
final linkkuDaoProvider = Provider<LinkkuDao>(
  (ref) => LinkkuDao(ref.watch(databaseProvider)),
);

final dailyOsRepositoryProvider = Provider<DailyOsRepository>(
  (ref) => DailyOsRepository(ref.watch(dailyOsDaoProvider)),
);
final idekuRepositoryProvider = Provider<IdekuRepository>(
  (ref) => IdekuRepository(ref.watch(idekuDaoProvider)),
);
final kronikRepositoryProvider = Provider<KronikRepository>(
  (ref) => KronikRepository(ref.watch(kronikDaoProvider)),
);
final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(financeDaoProvider)),
);
final linkkuRepositoryProvider = Provider<LinkkuRepository>(
  (ref) => LinkkuRepository(ref.watch(linkkuDaoProvider)),
);
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(metaDaoProvider)),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(metaDaoProvider)),
);

final refreshTickProvider = StateProvider<int>((ref) => 0);

final dailyOsSummaryProvider = FutureProvider<DailyOsSummary>((ref) async {
  ref.watch(refreshTickProvider);
  final now = ref.watch(clockProvider).now();
  return ref.watch(dailyOsRepositoryProvider).summary(now);
});

final idekuSummaryProvider = FutureProvider<IdekuSummary>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(idekuRepositoryProvider).summary();
});

final kronikSummaryProvider = FutureProvider<KronikSummary>((ref) async {
  ref.watch(refreshTickProvider);
  final now = ref.watch(clockProvider).now();
  return ref.watch(kronikRepositoryProvider).summary(now);
});

final financeSummaryProvider = FutureProvider<FinanceSummary>((ref) async {
  ref.watch(refreshTickProvider);
  final now = ref.watch(clockProvider).now();
  return ref.watch(financeRepositoryProvider).summary(now);
});

final linkkuSummaryProvider = FutureProvider<LinkkuSummary>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(linkkuRepositoryProvider).summary();
});

final profileProvider = FutureProvider<UserProfile>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(profileRepositoryProvider).load();
});

final themeSettingProvider = FutureProvider<ThemeSetting>((ref) async {
  ref.watch(refreshTickProvider);
  return ref.watch(settingsRepositoryProvider).theme();
});

void refreshSnapshots(WidgetRef ref) {
  ref.read(refreshTickProvider.notifier).state++;
}
