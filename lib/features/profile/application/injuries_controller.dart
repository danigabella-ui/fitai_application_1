import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/injury_repository.dart';
import '../domain/injury.dart';

/// A sérülésnapló. Bármelyik képernyő figyelheti.
final injuriesProvider =
    AsyncNotifierProvider<InjuriesController, List<Injury>>(
  InjuriesController.new,
);

class InjuriesController extends AsyncNotifier<List<Injury>> {
  @override
  Future<List<Injury>> build() {
    return ref.watch(injuryRepositoryProvider).getAll();
  }

  /// Elmenti a sérülést (újat vagy módosítottat); visszaadja az azonosítót.
  Future<String> save(Injury injury) async {
    final repository = ref.read(injuryRepositoryProvider);
    final id = await repository.save(injury);
    state = AsyncData(await repository.getAll());
    return id;
  }

  Future<void> delete(String id) async {
    final repository = ref.read(injuryRepositoryProvider);
    await repository.delete(id);
    state = AsyncData(await repository.getAll());
  }
}
