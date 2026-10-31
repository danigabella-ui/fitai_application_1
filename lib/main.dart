import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast_web/sembast_web.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';

/// Az app belépési pontja.
/// Először megnyitja a helyi adatbázist, utána indítja el az appot.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.open(databaseFactoryWeb);

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const FitAiApp(),
    ),
  );
}
