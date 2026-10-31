import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/checkin/presentation/checkin_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/application/backup_status_controller.dart';
import '../../shared/widgets/app_background.dart';
import 'selected_tab.dart';

/// A fő keret: alul a navigációs sáv a négy füllel, felette az aktív képernyő.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  /// A fülek sorrendje itt, a navigációs sávban és az AppTabs-ban
  /// is ugyanaz kell legyen.
  static const List<Widget> _screens = [
    ChatScreen(),
    CalendarScreen(),
    CheckInScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(selectedTabProvider);

    // Ha régen volt mentés, egy kis pötty jelenik meg a Profil fülön.
    final backupOverdue = ref.watch(backupStatusProvider).maybeWhen(
          data: (status) => status.isOverdue,
          orElse: () => false,
        );

    return Scaffold(
      body: AppBackground(
        // Minden fül egyszerre él (megmarad az állapotuk), de csak az
        // aktív látszik; váltáskor finoman áttűnnek egymásba.
        child: Stack(
          children: [
            for (var i = 0; i < _screens.length; i++)
              _AnimatedTab(
                active: i == currentIndex,
                child: _screens[i],
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(selectedTabProvider.notifier).select(index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Naptár',
          ),
          const NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Check-In',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: backupOverdue,
              child: const Icon(Icons.person_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: backupOverdue,
              child: const Icon(Icons.person),
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Egy fül, ami aktiváláskor finoman beúszik, és kikapcsoláskor elhalványul.
class _AnimatedTab extends StatelessWidget {
  const _AnimatedTab({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Ha a telefonon csökkentett mozgás van beállítva, nincs animáció.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 280);

    // Fontos: a TickerMode a fül tartalmát állítja le, nem az áttűnést.
    // Ha az áttűnést is körbevenné, a régi fül animációja megállna, és
    // a szövege ott maradna a képernyőn.
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: duration,
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.02),
            duration: duration,
            curve: Curves.easeOutCubic,
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      ),
    );
  }
}
