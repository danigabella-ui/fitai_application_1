import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../shared/widgets/dialogs.dart';
import '../application/injuries_controller.dart';
import '../application/profile_controller.dart';
import '../domain/injury.dart';
import '../domain/user_profile.dart';
import 'injury_detail_screen.dart';
import 'injury_edit_screen.dart';
import 'injury_widgets.dart';

/// A Profil fül „Sérülések” nézete: a sérülésnapló.
class InjuriesView extends ConsumerWidget {
  const InjuriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider).maybeWhen(
          data: (profile) => profile,
          orElse: () => null,
        );
    // A profil, ha van benne korábban szövegesen megadott sérülés.
    final legacyProfile = profile != null &&
            ((profile.injuries?.trim().isNotEmpty ?? false) ||
                profile.injuryAreas.isNotEmpty)
        ? profile
        : null;

    return ref.watch(injuriesProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nem sikerült beolvasni a sérüléseket: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
          data: (injuries) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (legacyProfile != null) ...[
                _LegacyInjuryBox(profile: legacyProfile),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InjuryEditScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Új sérülés'),
              ),
              const SizedBox(height: 12),
              if (injuries.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                  child: Text(
                    'Nincs rögzített sérülésed. Ha valami fáj vagy korlátoz, '
                    'itt rögzítheted, és az AI figyelembe veszi.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final injury in injuries) ...[
                _InjuryCard(injury: injury),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
  }
}

/// Egy sérülés kártyája a naplóban. Koppintásra megnyílik az idővonala.
class _InjuryCard extends StatelessWidget {
  const _InjuryCard({required this.injury});

  final Injury injury;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final latest = injury.latestUpdate;
    final start = injury.startDate;

    final details = [
      if (injury.type != null) injury.type!.label,
      if (start != null) '${huShortDate(start)} óta (${huElapsed(start)})',
    ].join(' · ');

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.healing_outlined, color: scheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(injuryTitle(injury), style: theme.textTheme.titleLarge),
            ),
            InjuryStatusChip(status: injury.status),
          ],
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              details,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
        if (latest != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CapacityBar(capacity: latest.capacity),
                if (latest.problemMovements.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Gondot okoz: ${_movements(latest.problemMovements)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Frissítve: ${huShortDate(latest.date)} '
                  '(${huElapsed(latest.date)})',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ],
        if (injury.needsUpdate()) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.update, size: 18, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Több mint ${Injury.staleAfterDays ~/ 7} hete nem '
                    'frissítetted. Hogy áll most?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final id = injury.id;
          if (id == null) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => InjuryDetailScreen(injuryId: id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          // A gyógyult sérülés halványabb, de megmarad.
          child: Opacity(
            opacity: injury.isOpen ? 1 : 0.7,
            child: content,
          ),
        ),
      ),
    );
  }

  static String _movements(Set<Movement> movements) => [
        for (final movement in Movement.values)
          if (movements.contains(movement)) movement.label.toLowerCase(),
      ].join(', ');
}

/// A profilban korábban szövegesen megadott sérülések, törlés gombbal.
class _LegacyInjuryBox extends ConsumerWidget {
  const _LegacyInjuryBox({required this.profile});

  final UserProfile profile;

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileProvider.notifier).save(
            profile.copyWith(injuries: null, injuryAreas: <BodyArea>{}),
          );
    } catch (error) {
      if (context.mounted) {
        showAppMessage(context, 'Nem sikerült törölni: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final areas = [
      for (final area in BodyArea.values)
        if (profile.injuryAreas.contains(area)) area.label.toLowerCase(),
    ].join(', ');
    final text = [
      if (areas.isNotEmpty) 'Testrészek: $areas',
      if (profile.injuries?.trim().isNotEmpty ?? false) profile.injuries!.trim(),
    ].join('\n');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Korábban beírt szöveg (sérülések)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  'Rögzítsd az „Új sérülés” gombbal, utána törölheted.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _clear(context, ref),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
  }
}
