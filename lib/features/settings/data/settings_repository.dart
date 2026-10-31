import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:sembast/sembast.dart';
   

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

/// Beállítások olvasása és írása az adatbázisban.
class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;

  static const String _apiKeyKey = 'gemini_api_key';

  Future<String?> getApiKey() async {
    final value = await Stores.settings.record(_apiKeyKey).get(_database.db);
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  Future<void> setApiKey(String key) async {
    await Stores.settings.record(_apiKeyKey).put(_database.db, key.trim());
  }

  Future<void> deleteApiKey() async {
    await Stores.settings.record(_apiKeyKey).delete(_database.db);
  }
}
