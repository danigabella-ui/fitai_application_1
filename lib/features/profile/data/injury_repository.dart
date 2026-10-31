import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';
import '../domain/injury.dart';

final injuryRepositoryProvider = Provider<InjuryRepository>((ref) {
  return InjuryRepository(ref.watch(appDatabaseProvider));
});

/// A sérülésnapló olvasása, mentése és törlése.
class InjuryRepository {
  InjuryRepository(this._database);

  final AppDatabase _database;

  /// Az összes sérülés: elöl az aktívak, aztán a rehabilitációban lévők,
  /// végül a gyógyultak; azon belül a legújabb elöl.
  Future<List<Injury>> getAll() async {
    final records = await Stores.injuries.find(_database.db);
    final injuries = [
      for (final record in records) Injury.fromMap(record.key, record.value),
    ];
    injuries.sort((a, b) {
      final byStatus = a.status.index.compareTo(b.status.index);
      if (byStatus != 0) return byStatus;
      final aDate = a.startDate ?? a.createdAt;
      final bDate = b.startDate ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return injuries;
  }

  /// Elmenti a sérülést; az új sérülés azonosítót kap. Visszaadja az
  /// azonosítót.
  Future<String> save(Injury injury) async {
    final id = injury.id;
    if (id == null) {
      return Stores.injuries.add(_database.db, injury.toMap());
    }
    await Stores.injuries.record(id).put(_database.db, injury.toMap());
    return id;
  }

  Future<void> delete(String id) async {
    await Stores.injuries.record(id).delete(_database.db);
  }
}
