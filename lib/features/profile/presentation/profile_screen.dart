import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../settings/application/backup_status_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import 'profile_details_view.dart';

enum _ProfileView { details, measurements }

/// Profil fül: felül a kapcsoló („Adataim” és „Mérések”), alatta a
/// kiválasztott nézet.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _ProfileView _view = _ProfileView.details;

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SegmentedButton<_ProfileView>(
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: _ProfileView.details,
                  label: Text('Adataim'),
                ),
                ButtonSegment(
                  value: _ProfileView.measurements,
                  label: Text('Mérések'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) =>
                  setState(() => _view = selection.first),
            ),
          ),
          Expanded(
            child: switch (_view) {
              _ProfileView.details => const ProfileDetailsView(),
              _ProfileView.measurements => const EmptyState(
                  icon: Icons.straighten,
                  title: 'Itt lesznek a méréseid',
                  message: 'Testsúly és körméretek dátummal, idősorosan. '
                      'Hamarosan érkezik.',
                ),
            },
          ),
        ],
      ),
    );
  }
}
