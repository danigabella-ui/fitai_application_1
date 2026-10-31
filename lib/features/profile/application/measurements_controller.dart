import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/measurement_repository.dart';
import '../domain/measurement.dart';

/// Az összes mérés, a legfrissebb elöl. Bármelyik képernyő figyelheti.
final measurementsProvider =
    AsyncNotifierProvider<MeasurementsController, List<Measurement>>(
  MeasurementsController.new,
);

class MeasurementsController extends AsyncNotifier<List<Measurement>> {
  @override
  Future<List<Measurement>> build() {
    return ref.watch(measurementRepositoryProvider).getAll();
  }

  /// Új mérés (ugyanarra a napra a meglévő kiegészítése).
  Future<void> addOrMerge(Measurement measurement) async {
    final repository = ref.read(measurementRepositoryProvider);
    await repository.addOrMerge(measurement);
    state = AsyncData(await repository.getAll());
  }

  /// Meglévő mérés módosítása.
  Future<void> replace(String originalId, Measurement measurement) async {
    final repository = ref.read(measurementRepositoryProvider);
    await repository.replace(originalId, measurement);
    state = AsyncData(await repository.getAll());
  }

  Future<void> delete(String id) async {
    final repository = ref.read(measurementRepositoryProvider);
    await repository.delete(id);
    state = AsyncData(await repository.getAll());
  }
}
