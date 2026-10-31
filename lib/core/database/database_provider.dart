import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Az adatbázis elérése az app bármely pontjáról.
/// Az értékét a main.dart adja meg induláskor (overrideWithValue).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'Az adatbázist a main.dart-ban kell megnyitni és átadni.',
  );
});
