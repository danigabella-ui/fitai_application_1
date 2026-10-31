import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';
import '../domain/measurement.dart';

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepository(ref.watch(appDatabaseProvider));
});

/// A mérések olvasása, hozzáadása és törlése.
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

  /// Új mérés mentése; visszaadja az új azonosítót.
  Future<String> add(Measurement measurement) {
    return Stores.measurements.add(_database.db, measurement.toMap());
  }

  Future<void> delete(String id) async {
    await Stores.measurements.record(id).delete(_database.db);
  }
}
