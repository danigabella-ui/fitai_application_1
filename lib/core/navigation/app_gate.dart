import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/application/profile_controller.dart';
import '../../features/profile/presentation/welcome_screen.dart';
import '../../shared/widgets/app_background.dart';
import 'main_shell.dart';

/// Eldönti, mi jelenjen meg induláskor: ha még nincs elmentett profil,
/// az üdvözlőképernyő, egyébként az app fő kerete a négy füllel.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(profileProvider).when(
          // Az adatbázis olvasása egy pillanat: addig csak a háttér látszik.
          loading: () => const Scaffold(
            body: AppBackground(child: SizedBox.shrink()),
          ),
          // Ha a profil nem olvasható be, ne zárjuk ki a felhasználót.
          error: (error, stackTrace) => const MainShell(),
          data: (profile) =>
              profile == null ? const WelcomeScreen() : const MainShell(),
        );
  }
}
