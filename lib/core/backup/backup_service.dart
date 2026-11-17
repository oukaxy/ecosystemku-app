import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Variable;

import '../db/clock.dart';
import '../db/daos/backup_dao.dart';
import '../db/database.dart';
import '../security/link_crypto.dart';
import 'backup_exporter.dart';
import 'backup_model.dart' show BackupException, BackupManifest, camelKeyToSql, sqlKeyToCamel;

class BackupService {
  BackupService({
    required this.db,
    required this.dao,
    required this.crypto,
    required this.clock,
  });

  static const appId = 'ecosystemku-flutter';
  static const appVersion = '1.0.0';

  final AppDatabase db;
  final BackupDao dao;
  final LinkCrypto crypto;
  final Clock clock;

  final Map<String, Set<String>> _columnCache = {};

  BackupExporter get _exporter => BackupExporter(
        dao: dao,
        crypto: crypto,
        clock: clock,
        appVersion: appVersion,
      );

  Future<Uint8List> exportBytes({String? pin}) =>
      _exporter.build(pin: pin, requirePinForPrivate: true);

  Future<BackupInspection> inspect(Uint8List bytes) async {
    final archive = _decode(bytes);
    final manifest = _readJson(archive, 'manifest.json');
    if (manifest == null) {
      throw BackupException('Bukan backup v3: manifest.json tidak ditemukan.');
    }
    final parsed = BackupManifest.fromJson(manifest);
    if (parsed.schema != 3) {
      throw BackupException('Versi backup ${parsed.schema} belum didukung.');
    }

    final warnings = <String>[];
    final cucimoney = _readDomain(archive, 'cucimoney');
    if (!parsed.includesSavings || cucimoney?['savings'] == null) {
      warnings.add('savings tidak ada di backup ini.');
    }
    final linkku = _readDomain(archive, 'linkku');
    if (linkku?['ep'] is String) {
      warnings.add('Link privat di backup memerlukan PIN.');
    }

    return BackupInspection(
      manifest: parsed,
      domains: archive.files
          .map((file) => file.name)
          .where((name) => name != 'manifest.json')
          .toSet(),
      warnings: warnings,
    );
  }

  Future<BackupImportResult> import(
    Uint8List bytes, {
    required BackupImportMode mode,
    String? pin,
  }) async {
    final inspection = await inspect(bytes);
    final archive = _decode(bytes);
    final tables = <String, List<Map<String, dynamic>>>{};
    final warnings = <String>[...inspection.warnings];
    final counts = <String, int>{};

    void addAll(String table, dynamic rows) {
      if (rows is! List) return;
      final target = tables.putIfAbsent(table, () => []);
      for (final row in rows) {
        if (row is Map) target.add(Map<String, dynamic>.from(row));
      }
    }

    final daily = _readDomain(archive, 'daily-os');
    if (daily != null) {
      addAll('habits', daily['habits']);
      addAll('todos', daily['todos']);
      _addTables(addAll, daily['_tables']);
      counts['habits'] = (daily['habits'] is List) ? daily['habits'].length : 0;
      counts['todos'] = (daily['todos'] is List) ? daily['todos'].length : 0;
    }

    final ideku = _readDomain(archive, 'ideku');
    if (ideku != null) {
      addAll('ideas', ideku['ideas']);
      addAll('idea_categories', ideku['categories']);
      counts['ideas'] =
          (ideku['ideas'] is List) ? ideku['ideas'].length : 0;
    }

    final kronik = _readDomain(archive, 'kronik');
    if (kronik != null) {
      addAll('journal_entries', kronik['entries']);
      _addTables(addAll, kronik['_tables']);
      final profile = kronik['profile'];
      if (profile is Map) {
        addAll('profile', [
          {
            'id': 1,
            'name': profile['name'],
            'avatarPath': profile['avatar'],
          },
        ]);
      }
      counts['journals'] =
          (kronik['entries'] is List) ? kronik['entries'].length : 0;
    }

    final cucimoney = _readDomain(archive, 'cucimoney');
    if (cucimoney != null) {
      final domainDb = cucimoney['db'];
      if (domainDb is Map) {
        for (final entry in domainDb.entries) {
          addAll(_tableName('${entry.key}'), entry.value);
        }
      }
      addAll('master_budgets', cucimoney['masterBudgets']);
      final savings = cucimoney['savings'];
      if (savings is Map) {
        addAll('savings_pots', savings['pots']);
        addAll('savings_events', savings['events']);
      }
      final trx = (domainDb is Map) ? domainDb['transactions'] : null;
      counts['transactions'] = (trx is List) ? trx.length : 0;
    }

    final linkku = _readDomain(archive, 'linkku');
    var privateLinks = 0;
    if (linkku != null) {
      addAll('links', linkku['L']);
      addAll('link_categories', linkku['C']);
      final ep = linkku['ep'];
      if (ep is String && ep.isNotEmpty) {
        if (pin == null) {
          warnings.add('Link privat dilewati: PIN belum dimasukkan.');
        } else {
          try {
            final privateData = await crypto.decryptPrivate(pin, ep);
            addAll('links', privateData['links']);
            addAll('link_categories', privateData['cats']);
            privateLinks = (privateData['links'] is List)
                ? privateData['links'].length
                : 0;
          } on LinkCryptoException catch (error) {
            warnings.add('Link privat dilewati: ${error.message}');
          }
        }
      }
      final publicLinks = (linkku['L'] is List) ? linkku['L'].length : 0;
      counts['links'] = publicLinks + privateLinks;
    }

    final assistant = _readDomain(archive, 'assistant');
    if (assistant != null) {
      addAll('app_meta', [
        {'key': 'assistant.muted', 'value': '${assistant['muted'] ?? false}'},
        {
          'key': 'assistant.expression',
          'value': '${assistant['expression'] ?? 'none'}',
        },
        {'key': 'assistant.panel', 'value': '${assistant['panel'] ?? false}'},
        {
          'key': 'assistant.character',
          'value': '${assistant['character'] ?? 'rem'}',
        },
      ]);
    }

    final autoBackup = await _exporter.build(
      pin: pin,
      requirePinForPrivate: false,
    );

    await db.transaction(() async {
      if (mode == BackupImportMode.replace) {
        await dao.clearTables(
          backupTableNames.where((t) => !_keptOnReplace.contains(t)).toList(),
        );
      }
      for (final entry in tables.entries) {
        if (entry.key == 'link_security') continue;
        await _mergeRows(entry.key, entry.value);
      }
    });

    return BackupImportResult(
      manifest: inspection.manifest,
      mode: mode,
      autoBackup: autoBackup,
      warnings: warnings,
      imported: counts,
    );
  }

  static const _keptOnReplace = {'profile', 'reminders', 'app_meta'};
  static const _alwaysReplace = {'profile'};

  Archive _decode(Uint8List bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw BackupException('File backup rusak atau bukan ZIP.');
    }
  }

  Map<String, dynamic>? _readJson(Archive archive, String name) {
    final file = archive.findFile(name);
    if (file == null) return null;
    final content = file.content;
    if (content is! List<int>) return null;
    try {
      final decoded = jsonDecode(utf8.decode(content));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      throw BackupException('Isi $name tidak valid.');
    }
  }

  Map<String, dynamic>? _readDomain(Archive archive, String prefix) {
    for (final file in archive.files) {
      if (file.name.startsWith('$prefix-') && file.name.endsWith('.json')) {
        return _readJson(archive, file.name);
      }
    }
    return null;
  }

  void _addTables(
    void Function(String, dynamic) addAll,
    dynamic raw,
  ) {
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      addAll('${entry.key}', entry.value);
    }
  }

  String _tableName(String key) => switch (key) {
        'bookAccounts' => 'book_accounts',
        'categories' => 'categories_finance',
        _ => key,
      };

  Future<void> _mergeRows(
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    final columns = await _columns(table);
    if (columns.isEmpty) return;

    for (final raw in rows) {
      final row = <String, Object?>{};
      final camelRow = <String, Object?>{};
      for (final entry in raw.entries) {
        var sqlName = entry.key;
        if (!columns.contains(sqlName)) sqlName = camelKeyToSql(entry.key);
        if (!columns.contains(sqlName)) continue;
        row[sqlName] = _sqlValue(entry.value);
        camelRow[sqlKeyToCamel(sqlName)] = entry.value;
      }
      if (row.isEmpty) continue;

      final id = row['id'];
      if (id != null && !_alwaysReplace.contains(table)) {
        final existing = await db
            .customSelect(
              'SELECT * FROM "$table" WHERE id = ?',
              variables: [Variable(id)],
            )
            .getSingleOrNull();
        if (existing != null) {
          final existingCamel = <String, Object?>{
            for (final e in existing.data.entries) sqlKeyToCamel(e.key): e.value,
          };
          if (!_isNewer(camelRow, existingCamel)) continue;
        }
      }
      await _upsert(table, row);
    }
  }

  Future<void> _upsert(String table, Map<String, Object?> row) async {
    final keys = row.keys.toList(growable: false);
    final columns = keys.map((key) => '"$key"').join(', ');
    final placeholders = List.filled(keys.length, '?').join(', ');
    await db.customStatement(
      'INSERT OR REPLACE INTO "$table" ($columns) VALUES ($placeholders)',
      keys.map((key) => row[key]).toList(growable: false),
    );
  }

  Future<Set<String>> _columns(String table) async {
    final cached = _columnCache[table];
    if (cached != null) return cached;
    final rows = await db.customSelect('PRAGMA table_info("$table")').get();
    final columns = rows
        .map((row) => '${row.data['name']}')
        .where((name) => name.isNotEmpty)
        .toSet();
    _columnCache[table] = columns;
    return columns;
  }

  bool _isNewer(Map<String, Object?> incoming, Map<String, Object?> existing) {
    int stamp(Map<String, Object?> row) {
      for (final key in const ['updatedAt', 'ts', 'createdAt']) {
        final value = row[key];
        if (value is num) return value.toInt();
      }
      return 0;
    }

    return stamp(incoming) > stamp(existing);
  }

  Object? _sqlValue(Object? value) {
    if (value is bool) return value ? 1 : 0;
    if (value is Map || value is List) return jsonEncode(value);
    return value;
  }

}
