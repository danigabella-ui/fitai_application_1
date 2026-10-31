import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

/// Beállítások olvasása és írása az adatbázisban (kulcs-érték párok).
class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;

  static const String apiKeyKey = 'gemini_api_key';
  static const String lastBackupAtKey = 'last_backup_at';
  static const String firstUsedAtKey = 'first_used_at';

  /// Csak ezen a készüléken érvényes beállítások.
  /// Ezek nem kerülnek bele a mentésbe, és visszaállításkor sem változnak.
  static const Set<String> deviceOnlyKeys = {
    apiKeyKey,
    lastBackupAtKey,
    firstUsedAtKey,
  };

  Future<String?> getString(String key) async {
    final value = await Stores.settings.record(key).get(_database.db);
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  Future<void> setString(String key, String value) async {
    await Stores.settings.record(key).put(_database.db, value);
  }

  Future<void> delete(String key) async {
    await Stores.settings.record(key).delete(_database.db);
  }

  // API-kulcs

  Future<String?> getApiKey() => getString(apiKeyKey);

  Future<void> setApiKey(String key) => setString(apiKeyKey, key.trim());

  Future<void> deleteApiKey() => delete(apiKeyKey);
}
