import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';

/// Az elmentett Gemini API-kulcs (null, ha nincs megadva).
/// Bármelyik képernyő figyelheti, és azonnal értesül a változásról.
final apiKeyProvider =
    AsyncNotifierProvider<ApiKeyController, String?>(ApiKeyController.new);

class ApiKeyController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() {
    return ref.watch(settingsRepositoryProvider).getApiKey();
  }

  Future<void> save(String key) async {
    final trimmed = key.trim();
    await ref.read(settingsRepositoryProvider).setApiKey(trimmed);
    state = AsyncData(trimmed);
  }

  Future<void> delete() async {
    await ref.read(settingsRepositoryProvider).deleteApiKey();
    state = const AsyncData(null);
  }
}
