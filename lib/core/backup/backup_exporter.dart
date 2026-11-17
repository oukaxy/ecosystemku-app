import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../db/clock.dart';
import '../db/daos/backup_dao.dart';
import '../db/database.dart';
import '../security/link_crypto.dart';
import 'backup_model.dart' show BackupManifest, PrivateLinksNeedPin, sqlKeyToCamel;
import 'backup_service.dart';

/// Builds the canonical ZIP v3 payload (mahfud 6.1).
class BackupExporter {
  const BackupExporter({
    required this.dao,
    required this.crypto,
    required this.clock,
    required this.appVersion,
  });

  final BackupDao dao;
  final LinkCrypto crypto;
  final Clock clock;
  final String appVersion;

  Future<Uint8List> build({
    String? pin,
    required bool requirePinForPrivate,
  }) async {
    final raw = await dao.readAll(backupTableNames);
    final tables = <String, List<Map<String, Object?>>>{
      for (final entry in raw.entries)
        entry.key: [
          for (final row in entry.value)
            {for (final e in row.entries) sqlKeyToCamel(e.key): e.value},
        ],
    };
    final date = todayString(clock);
    final now = clock.now();

    final links = tables['links'] ?? const [];
    final linkCategories = tables['link_categories'] ?? const [];
    final publicLinks =
        links.where((row) => !_truthy(row['isPrivate'])).toList();
    final privateLinks =
        links.where((row) => _truthy(row['isPrivate'])).toList();
    final publicCategories = linkCategories
        .where((row) => !_truthy(row['isPrivate']))
        .toList();
    final privateCategories = linkCategories
        .where((row) => _truthy(row['isPrivate']))
        .toList();

    String? ep;
    if (privateLinks.isNotEmpty) {
      if (pin != null) {
        ep = await crypto.encryptPrivate(pin, {
          'links': privateLinks,
          'cats': privateCategories,
        });
      } else if (requirePinForPrivate) {
        throw PrivateLinksNeedPin();
      }
    }

    final meta = <String, String>{};
    for (final row in tables['app_meta'] ?? const <Map<String, Object?>>[]) {
      meta['${row['key']}'] = '${row['value']}';
    }

    final profileRows = tables['profile'] ?? const <Map<String, Object?>>[];
    final profile = profileRows.isEmpty ? null : profileRows.first;
    final ideas = tables['ideas'] ?? const [];
    final entries = tables['journal_entries'] ?? const [];
    final transactions = tables['transactions'] ?? const [];
    final habits = tables['habits'] ?? const [];
    final todos = tables['todos'] ?? const [];

    final domainJson = <String, Map<String, dynamic>>{
      'daily-os': {
        'version': 3,
        'habits': habits,
        'todos': todos,
        '_tables': {
          'habit_subtasks': tables['habit_subtasks'] ?? const [],
          'habit_checks': tables['habit_checks'] ?? const [],
          'todo_subtasks': tables['todo_subtasks'] ?? const [],
        },
      },
      'ideku': {
        'ideas': ideas,
        'categories': tables['idea_categories'] ?? const [],
      },
      'kronik': {
        'version': 2,
        'entries': entries,
        if (profile != null && profile['name'] != null)
          'profile': {
            'name': profile['name'],
            'avatar': profile['avatarPath'],
          },
        '_tables': {
          'journal_habit_logs': tables['journal_habit_logs'] ?? const [],
        },
      },
      'cucimoney': {
        '_version': 1,
        '_app': 'cucimoney',
        'db': {
          'books': tables['books'] ?? const [],
          'bookAccounts': tables['book_accounts'] ?? const [],
          'accounts': tables['accounts'] ?? const [],
          'categories': tables['categories_finance'] ?? const [],
          'transactions': transactions,
          'members': tables['members'] ?? const [],
        },
        'masterBudgets': tables['master_budgets'] ?? const [],
        'savings': {
          'pots': tables['savings_pots'] ?? const [],
          'events': tables['savings_events'] ?? const [],
        },
      },
      'linkku': {
        'L': publicLinks,
        'C': publicCategories,
        if (ep != null) 'ep': ep,
        'ts': now.millisecondsSinceEpoch,
        'v': 5,
      },
      'assistant': {
        'muted': meta['assistant.muted'] == 'true',
        'expression': meta['assistant.expression'] ?? 'none',
        'panel': meta['assistant.panel'] == 'true',
        'character': meta['assistant.character'] ?? 'rem',
      },
    };

    final manifest = BackupManifest(
      schema: 3,
      app: BackupService.appId,
      appVersion: appVersion,
      exportedAt: now.toUtc().toIso8601String(),
      counts: {
        'habits': habits.length,
        'todos': todos.length,
        'ideas': ideas.length,
        'journals': entries.length,
        'transactions': transactions.length,
        'links': publicLinks.length + (ep != null ? privateLinks.length : 0),
      },
      includesSavings: true,
      includesPrivateLinks: ep != null,
    );

    final archive = Archive();
    _addJson(archive, 'manifest.json', manifest.toJson());
    for (final entry in domainJson.entries) {
      _addJson(archive, '${entry.key}-$date.json', entry.value);
    }
    return Uint8List.fromList(ZipEncoder().encode(archive) ?? const []);
  }

  void _addJson(Archive archive, String name, Map<String, dynamic> json) {
    final bytes = utf8.encode(jsonEncode(json));
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  bool _truthy(Object? value) => value == true || value == 1;
}
