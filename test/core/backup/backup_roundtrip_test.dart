import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ecosystemku/core/backup/backup_model.dart';
import 'package:ecosystemku/core/backup/backup_service.dart';
import 'package:ecosystemku/core/db/clock.dart';
import 'package:ecosystemku/core/db/daos/backup_dao.dart';
import 'package:ecosystemku/core/db/database.dart';
import 'package:ecosystemku/core/security/link_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = BackupService(
      db: db,
      dao: BackupDao(db),
      crypto: LinkCrypto(),
      clock: _FixedClock(DateTime(2026, 11, 17, 10)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed() async {
    await db.into(db.ideas).insert(
          IdeasCompanion.insert(
            id: 'i1',
            title: 'Ide awal',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: 'a1',
            name: 'Tunai',
            balance: const Value(50000),
          ),
        );
    await db.into(db.financeTransactions).insert(
          FinanceTransactionsCompanion.insert(
            id: 't1',
            bookId: 'b1',
            title: 'Makan',
            amount: const Value(15000),
            date: '2026-11-17',
            createdAt: 1,
          ),
        );
    await db.into(db.savingsPots).insert(
          SavingsPotsCompanion.insert(wishId: 'w1', saved: const Value(25000)),
        );
    await db.into(db.savedLinks).insert(
          SavedLinksCompanion.insert(
            id: 'l1',
            url: 'https://publik.test',
            title: 'Publik',
            ts: 1,
          ),
        );
    await db.into(db.linkCategories).insert(
          LinkCategoriesCompanion.insert(id: 'pc1', name: 'Pribadi', isPrivate: const Value(true)),
        );
    await db.into(db.savedLinks).insert(
          SavedLinksCompanion.insert(
            id: 'p1',
            url: 'https://rahasia.test',
            title: 'Rahasia',
            ts: 2,
            isPrivate: const Value(true),
            privateCatId: const Value('pc1'),
          ),
        );
  }

  test('export includes savings and encrypts private links', () async {
    await seed();

    final bytes = await service.exportBytes(pin: '1234');
    final inspection = await service.inspect(bytes);

    expect(inspection.manifest.schema, 3);
    expect(inspection.manifest.counts['ideas'], 1);
    expect(inspection.manifest.counts['links'], 2);
    expect(inspection.manifest.includesPrivateLinks, isTrue);
    expect(inspection.warnings, isEmpty);

    final archive = ZipDecoder().decodeBytes(bytes);
    final linkku = jsonDecode(
      utf8.decode(
        archive.findFile('linkku-2026-11-17.json')!.content as List<int>,
      ),
    ) as Map<String, dynamic>;
    expect(linkku['ep'], isA<String>());
    expect(
      (linkku['L'] as List).map((e) => e['id']),
      isNot(contains('p1')),
    );

    final cucimoney = jsonDecode(
      utf8.decode(
        archive.findFile('cucimoney-2026-11-17.json')!.content as List<int>,
      ),
    ) as Map<String, dynamic>;
    expect((cucimoney['savings'] as Map)['pots'], hasLength(1));
  });

  test('export refuses private links without PIN', () async {
    await seed();

    expect(
      () => service.exportBytes(),
      throwsA(isA<PrivateLinksNeedPin>()),
    );
  });

  test('replace round-trip restores all domains', () async {
    await seed();
    final bytes = await service.exportBytes(pin: '1234');

    await BackupDao(db).clearTables(backupTableNames);
    expect(await db.select(db.ideas).get(), isEmpty);

    final result = await service.import(
      bytes,
      mode: BackupImportMode.replace,
      pin: '1234',
    );

    expect(result.imported['ideas'], 1);
    expect(result.imported['transactions'], 1);
    expect(result.imported['links'], 2);
    expect(result.autoBackup, isNotEmpty);
    expect(result.warnings, isEmpty);

    expect((await db.select(db.ideas).get()).single.title, 'Ide awal');
    expect((await db.select(db.savingsPots).get()).single.saved, 25000);
    expect((await db.select(db.savedLinks).get()), hasLength(2));
    expect(
      (await db.select(db.savedLinks).get())
          .firstWhere((link) => link.id == 'p1')
          .isPrivate,
      isTrue,
    );
  });

  test('merge keeps a newer local row', () async {
    await seed();
    final bytes = await service.exportBytes(pin: '1234');
    await db.customStatement(
      'UPDATE ideas SET title = ?, updatedAt = ? WHERE id = ?',
      ['Versi lokal', 999, 'i1'],
    );

    await service.import(bytes, mode: BackupImportMode.merge, pin: '1234');

    final ideas = await db.select(db.ideas).get();
    expect(ideas, hasLength(1));
    expect(ideas.single.title, 'Versi lokal');
  });

  test('replace removes rows absent from backup', () async {
    await seed();
    final bytes = await service.exportBytes(pin: '1234');
    await db.into(db.ideas).insert(
          IdeasCompanion.insert(
            id: 'extra',
            title: 'Ekstra',
            createdAt: 5,
            updatedAt: 5,
          ),
        );

    await service.import(bytes, mode: BackupImportMode.replace, pin: '1234');

    final ideas = await db.select(db.ideas).get();
    expect(ideas.map((idea) => idea.id), isNot(contains('extra')));
  });

  test('corrupt ZIP throws without changing data', () async {
    await seed();
    final before = (await db.select(db.ideas).get()).length;

    await expectLater(
      service.import(
        Uint8List.fromList([1, 2, 3, 4]),
        mode: BackupImportMode.replace,
      ),
      throwsA(isA<BackupException>()),
    );

    expect((await db.select(db.ideas).get()).length, before);
  });

  test('API keys never enter backup bytes', () async {
    await seed();
    final bytes = await service.exportBytes(pin: '1234');
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive.files) {
      final content = file.content;
      if (content is List<int>) {
        expect(utf8.decode(content), isNot(contains('gsk_super_secret')));
      }
    }
  });
}
