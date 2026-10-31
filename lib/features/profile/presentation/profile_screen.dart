import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../settings/presentation/settings_screen.dart';

/// Profil fül: személyes adatok, célok és mérések.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Beállítások',
            icon: const Icon(Icons.settings_outlined),
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
      body: const EmptyState(
        icon: Icons.person_outline,
        title: 'Itt lesz a profilod',
        message: 'Az adataid, a célod és a mérések idősorosan.',
      ),
    );
  }
}
