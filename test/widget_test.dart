import 'package:fitai_application_1/app.dart';
import 'package:fitai_application_1/core/database/app_database.dart';
import 'package:fitai_application_1/core/database/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets('Az app elindul, és a négy fül megjelenik', (tester) async {
    // Tesztben memóriában futó adatbázist használunk.
    final database = await tester.runAsync(
      () => AppDatabase.open(databaseFactoryMemory),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database!)],
        child: const FitAiApp(),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });
}
