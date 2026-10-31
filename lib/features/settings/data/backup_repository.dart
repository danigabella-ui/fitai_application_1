import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';
import 'settings_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(ref.watch(appDatabaseProvider));
});

/// Egy beolvasott, még vissza nem állított mentés.
class BackupData {
  const BackupData({
    required this.exportedAt,
    required this.stores,
    required this.settings,
  });

  final DateTime? exportedAt;

  /// Tárolónév -> (rekordkulcs -> adat)
  final Map<String, Map<String, Map<String, Object?>>> stores;

  /// Beállítások (a csak ezen a készüléken érvényesek nélkül).
  final Map<String, String> settings;

  int countOf(String storeName) => stores[storeName]?.length ?? 0;
}

/// Az összes adat mentése egy JSON-fájlba, és visszaállítása onnan.
///
/// Az API-kulcs és a többi, csak ezen a készüléken érvényes beállítás
/// szándékosan NEM kerül a mentésbe, így a mentésfájl biztonságosan
/// tárolható pl. iCloudban.
class BackupRepository {
  BackupRepository(this._database);

  final AppDatabase _database;

  static const String _appId = 'fitai';
  static const int _formatVersion = 1;

  /// A mentett tárolók, név szerint.
  static final Map<String, StoreRef<String, Map<String, Object?>>> _stores = {
    'profile': Stores.profile,
    'measurements': Stores.measurements,
    'injuries': Stores.injuries,
    'check_ins': Stores.checkIns,
    'chat_messages': Stores.chatMessages,
  };

  /// A teljes adatbázis JSON-szövegként.
  Future<String> exportJson() async {
    final db = _database.db;

    final stores = <String, Object?>{};
    for (final entry in _stores.entries) {
      final records = await entry.value.find(db);
      stores[entry.key] = {
        for (final record in records) record.key: record.value,
      };
    }

    final settingsRecords = await Stores.settings.find(db);
    final settings = {
      for (final record in settingsRecords)
        if (!SettingsRepository.deviceOnlyKeys.contains(record.key))
          record.key: record.value,
    };

    return const JsonEncoder.withIndent('  ').convert({
      'app': _appId,
      'version': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'stores': stores,
      'settings': settings,
    });
  }

  /// Beolvassa és ellenőrzi a mentésfájl szövegét, de még nem írja az
  /// adatbázisba. Hibás fájl esetén [FormatException]-t dob.
  BackupData parse(String text) {
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const FormatException('A fájl nem olvasható mentésként.');
    }

    if (decoded is! Map || decoded['app'] != _appId) {
      throw const FormatException('Ez a fájl nem FitAI-mentés.');
    }
    final version = decoded['version'];
    if (version is! int || version > _formatVersion) {
      throw const FormatException(
        'Ez a mentés az app egy újabb verziójából származik.',
      );
    }

    final rawStores = decoded['stores'];
    if (rawStores is! Map) {
      throw const FormatException('A mentésből hiányoznak az adatok.');
    }

    final stores = <String, Map<String, Map<String, Object?>>>{};
    for (final name in _stores.keys) {
      final rawRecords = rawStores[name];
      final records = <String, Map<String, Object?>>{};
      if (rawRecords is Map) {
        rawRecords.forEach((key, value) {
          if (key is String && value is Map) {
            records[key] = Map<String, Object?>.from(value);
          }
        });
      }
      stores[name] = records;
    }

    final settings = <String, String>{};
    final rawSettings = decoded['settings'];
    if (rawSettings is Map) {
      rawSettings.forEach((key, value) {
        if (key is String &&
            value is String &&
            !SettingsRepository.deviceOnlyKeys.contains(key)) {
          settings[key] = value;
        }
      });
    }

    final exportedAt = decoded['exportedAt'];
    return BackupData(
      exportedAt: exportedAt is String ? DateTime.tryParse(exportedAt) : null,
      stores: stores,
      settings: settings,
    );
  }

  /// Visszaállítja a mentést: az appban lévő adatokat a mentés tartalmára
  /// cseréli. A csak ezen a készüléken érvényes beállítások (pl. API-kulcs)
  /// érintetlenek maradnak.
  Future<void> restore(BackupData backup) async {
    await _database.db.transaction((txn) async {
      for (final entry in _stores.entries) {
        final store = entry.value;
        await store.delete(txn);
        final records = backup.stores[entry.key] ?? const {};
        for (final record in records.entries) {
          await store.record(record.key).put(txn, record.value);
        }
      }

      await Stores.settings.delete(
        txn,
        finder: Finder(
          filter: Filter.not(
            Filter.inList(
              Field.key,
              SettingsRepository.deviceOnlyKeys.toList(),
            ),
          ),
        ),
      );
      for (final setting in backup.settings.entries) {
        await Stores.settings.record(setting.key).put(txn, setting.value);
      }
    });
  }
}
