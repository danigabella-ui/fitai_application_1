import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../shared/widgets/app_background.dart';
import '../application/injuries_controller.dart';
import '../domain/injury.dart';
import 'injury_edit_screen.dart';
import 'injury_update_screen.dart';
import 'injury_widgets.dart';

/// Egy sérülés adatai és az állapotfrissítések idővonala.
class InjuryDetailScreen extends ConsumerWidget {
  const InjuryDetailScreen({super.key, required this.injuryId});

  final String injuryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final injuries = ref.watch(injuriesProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <Injury>[],
        );
    Injury? injury;
    for (final item in injuries) {
      if (item.id == injuryId) injury = item;
    }

    if (injury == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppBackground(
          child: Center(child: Text('Ez a sérülés nem található.')),
        ),
      );
    }
    final current = injury;
    final start = current.startDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(injuryTitle(current)),
        actions: [
          IconButton(
            tooltip: 'Adatok szerkesztése',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InjuryEditScreen(existing: current),
                ),
              );
            },
          ),
        ],
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InjuryStatusChip(status: current.status),
                    const SizedBox(height: 10),
                    _InfoRow(
                      label: 'Típus',
                      value: current.type?.label ?? 'Nincs megadva',
                    ),
                    _InfoRow(
                      label: 'Kezdete',
                      value: start == null
                          ? 'Nincs megadva'
                          : '${huFullDate(start)} (${huElapsed(start)})',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InjuryUpdateScreen(injury: current),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Állapot frissítése'),
            ),
            const SizedBox(height: 24),
            Text('Állapot időben', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            if (current.updates.isEmpty)
              Text(
                'Még nincs állapotfrissítés. Rögzítsd, hol tartasz most, '
                'és később láthatod, hogyan javul.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            for (var i = 0; i < current.updates.length; i++) ...[
              _UpdateCard(
                update: current.updates[i],
                isLatest: i == 0,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          InjuryUpdateScreen(injury: current, editIndex: i),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// Egy állapotfrissítés az idővonalon. Koppintásra szerkeszthető.
class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.update,
    required this.isLatest,
    required this.onTap,
  });

  final InjuryUpdate update;
  final bool isLatest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final problems = [
      for (final movement in Movement.values)
        if (update.problemMovements.contains(movement))
          movement.label.toLowerCase(),
    ];
    final note = update.medicalNote;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: huShortDate(update.date)),
                    TextSpan(
                      text: isLatest
                          ? ' · legutóbbi'
                          : ' · ${huElapsed(update.date)}',
                      style: TextStyle(color: muted),
                    ),
                  ],
                ),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              CapacityBar(capacity: update.capacity),
              if (problems.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Gondot okoz: ${problems.join(', ')}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (note != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.medical_information_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(note, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
