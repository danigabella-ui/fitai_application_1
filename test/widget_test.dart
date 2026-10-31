import 'package:fitai_application_1/app.dart';
import 'package:fitai_application_1/core/database/app_database.dart';
import 'package:fitai_application_1/core/database/database_provider.dart';
import 'package:fitai_application_1/features/profile/data/profile_repository.dart';
import 'package:fitai_application_1/features/profile/domain/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

/// Elindítja az appot egy memóriában futó adatbázissal, és megvárja,
/// hogy az első adatok beolvasódjanak.
Future<void> _startApp(WidgetTester tester, AppDatabase database) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const FitAgentApp(),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

void main() {
  testWidgets('Első indításkor az üdvözlőképernyő jelenik meg',
      (tester) async {
    final database = await tester.runAsync(
      () => AppDatabase.open(newDatabaseFactoryMemory()),
    );

    await _startApp(tester, database!);

    expect(find.text('Kezdjük'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Elmentett profillal a négy fül jelenik meg', (tester) async {
    final database = await tester.runAsync(() async {
      final db = await AppDatabase.open(newDatabaseFactoryMemory());
      await ProfileRepository(db).saveProfile(UserProfile.empty);
      return db;
    });

    await _startApp(tester, database!);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });
}
