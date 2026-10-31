import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';
import '../domain/measurement.dart';

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepository(ref.watch(appDatabaseProvider));
});

/// A mérések olvasása, mentése és törlése.
///
/// Minden mérés a napja alatt tárolódik (pl. "2026-10-31"), így naponta
/// egy mérés van.
class MeasurementRepository {
  MeasurementRepository(this._database);

  final AppDatabase _database;

  /// Az összes mérés, a legfrissebb elöl.
  Future<List<Measurement>> getAll() async {
    final records = await Stores.measurements.find(
      _database.db,
      finder: Finder(sortOrders: [SortOrder('date', false)]),
    );
    return records
        .map((record) => Measurement.fromMap(record.key, record.value))
        .toList();
  }

  /// Új mérés mentése. Ha arra a napra már van mérés, az új értékek
  /// kiegészítik (azonos mezőnél felülírják) a meglévőt.
  Future<void> addOrMerge(Measurement measurement) async {
    await _database.db.transaction((txn) async {
      await _mergeInto(txn, measurement);
    });
  }

  /// Egy meglévő mérés módosítása. Ha a dátuma más napra került, és azon
  /// a napon már van mérés, a kettő összeolvad.
  Future<void> replace(String originalId, Measurement measurement) async {
    await _database.db.transaction((txn) async {
      if (originalId == measurement.dayKey) {
        await Stores.measurements
            .record(originalId)
            .put(txn, measurement.toMap());
      } else {
        await Stores.measurements.record(originalId).delete(txn);
        await _mergeInto(txn, measurement);
      }
    });
  }

  Future<void> delete(String id) async {
    await Stores.measurements.record(id).delete(_database.db);
  }

  Future<void> _mergeInto(DatabaseClient client, Measurement measurement) async {
    final key = measurement.dayKey;
    final record = Stores.measurements.record(key);
    final existing = await record.get(client);
    final merged = existing == null
        ? measurement
        : Measurement.fromMap(key, existing).mergedWith(measurement);
    await record.put(client, merged.toMap());
  }
}
