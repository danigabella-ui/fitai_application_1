import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../settings/application/backup_status_controller.dart';
import '../../settings/presentation/settings_screen.dart';

/// Profil fül: személyes adatok, célok és mérések.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupOverdue = ref.watch(backupStatusProvider).maybeWhen(
          data: (status) => status.isOverdue,
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(
            title: 'Profil',
            subtitle: 'Adatok és mérések',
            actions: [
              IconButton(
                tooltip: 'Beállítások',
                icon: Badge(
                  isLabelVisible: backupOverdue,
                  child: const Icon(Icons.settings_outlined),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const Expanded(
            child: EmptyState(
              icon: Icons.person_outline,
              title: 'Itt lesz a profilod',
              message: 'Az adataid, a célod és a mérések idősorosan.',
            ),
          ),
        ],
      ),
    );
  }
}
