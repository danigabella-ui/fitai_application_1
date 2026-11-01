import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';
import '../domain/check_in.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.watch(appDatabaseProvider));
});

/// A reggeli check-inek olvasása és mentése.
class CheckInRepository {
  CheckInRepository(this._database);

  final AppDatabase _database;

  /// Az adott nap check-inje, vagy null, ha még nincs.
  Future<CheckIn?> getForDay(DateTime day) async {
    final map = await Stores.checkIns
        .record(CheckIn.dayKeyOf(day))
        .get(_database.db);
    return map == null ? null : CheckIn.fromMap(map);
  }

  /// A megadott napok check-injei a nap azonosítója szerint
  /// (pl. "2026-10-31"). A ki nem töltött napok kimaradnak.
  Future<Map<String, CheckIn>> getDays(Iterable<DateTime> days) async {
    final keys = [for (final day in days) CheckIn.dayKeyOf(day)];
    final records = await Stores.checkIns.find(
      _database.db,
      finder: Finder(filter: Filter.inList(Field.key, keys)),
    );
    return {
      for (final record in records) record.key: CheckIn.fromMap(record.value),
    };
  }

  /// Mentés; ha aznapra már van check-in, felülírja.
  Future<void> save(CheckIn checkIn) async {
    await Stores.checkIns
        .record(checkIn.dayKey)
        .put(_database.db, checkIn.toMap());
  }

  /// Az utolsó [count] check-in, a legfrissebb elöl.
  Future<List<CheckIn>> getRecent({int count = 14}) async {
    final records = await Stores.checkIns.find(
      _database.db,
      finder: Finder(sortOrders: [SortOrder('date', false)], limit: count),
    );
    return records.map((record) => CheckIn.fromMap(record.value)).toList();
  }
}
