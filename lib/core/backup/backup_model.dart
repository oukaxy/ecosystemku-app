import 'dart:typed_data';

enum BackupImportMode { merge, replace }

/// Drift generates snake_case SQL columns while the legacy web backup
/// contract uses camelCase keys. Convert at the backup boundary.
String sqlKeyToCamel(String key) {
  final parts = key.split('_');
  if (parts.length <= 1) return key;
  final rest = [
    for (final part in parts.skip(1))
      part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
  ].join();
  return '${parts.first}$rest';
}

String camelKeyToSql(String key) =>
    key.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrivateLinksNeedPin extends BackupException {
  PrivateLinksNeedPin()
      : super('Atur PIN atau lewati link privat sebelum mengekspor.');
}

class BackupManifest {
  const BackupManifest({
    required this.schema,
    required this.app,
    required this.appVersion,
    required this.exportedAt,
    required this.counts,
    required this.includesSavings,
    required this.includesPrivateLinks,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final counts = <String, int>{};
    final rawCounts = json['counts'];
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final value = entry.value;
        if (value is num) counts['${entry.key}'] = value.toInt();
      }
    }
    return BackupManifest(
      schema: (json['schema'] as num?)?.toInt() ?? 0,
      app: json['app'] as String? ?? '',
      appVersion: json['appVersion'] as String? ?? '',
      exportedAt: json['exportedAt'] as String? ?? '',
      counts: counts,
      includesSavings: json['includesSavings'] == true,
      includesPrivateLinks: json['includesPrivateLinks'] == true,
    );
  }

  final int schema;
  final String app;
  final String appVersion;
  final String exportedAt;
  final Map<String, int> counts;
  final bool includesSavings;
  final bool includesPrivateLinks;

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'app': app,
        'appVersion': appVersion,
        'exportedAt': exportedAt,
        'counts': counts,
        'includesSavings': includesSavings,
        'includesPrivateLinks': includesPrivateLinks,
      };
}

class BackupInspection {
  const BackupInspection({
    required this.manifest,
    required this.domains,
    required this.warnings,
  });

  final BackupManifest manifest;
  final Set<String> domains;
  final List<String> warnings;
}

class BackupImportResult {
  const BackupImportResult({
    required this.manifest,
    required this.mode,
    required this.autoBackup,
    required this.warnings,
    required this.imported,
  });

  final BackupManifest manifest;
  final BackupImportMode mode;
  final Uint8List autoBackup;
  final List<String> warnings;
  final Map<String, int> imported;
}
