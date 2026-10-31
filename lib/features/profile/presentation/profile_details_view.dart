import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../shared/widgets/dialogs.dart';
import '../application/measurements_controller.dart';
import '../application/profile_controller.dart';
import '../domain/measurement.dart';
import '../domain/user_profile.dart';
import 'profile_sections.dart';
import 'profile_wizard_screen.dart';
import 'section_edit_screen.dart';

/// A Profil fül „Adataim” nézete: a szakaszok kártyái és a válaszstílus.
class ProfileDetailsView extends ConsumerWidget {
  const ProfileDetailsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // A legutóbbi mérés, amelyben van testsúly (az Alapadatok kártyára).
    final Measurement? latestWeight = ref.watch(measurementsProvider).maybeWhen(
          data: (measurements) {
            for (final measurement in measurements) {
              if (measurement.weightKg != null) return measurement;
            }
            return null;
          },
          orElse: () => null,
        );

    return ref.watch(profileProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nem sikerült beolvasni a profilt: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
          data: (stored) {
            final profile = stored ?? UserProfile.empty;
            const sections = ProfileSection.values;
            final filled = sections.where((s) => s.isFilledIn(profile)).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Ha a profil nagyrészt üres, emlékeztető kártya.
                if (filled < sections.length / 2) ...[
                  _FillReminderCard(profile: profile),
                  const SizedBox(height: 12),
                ],
                for (final section in sections) ...[
                  _SectionCard(
                    section: section,
                    profile: profile,
                    latestWeight: section == ProfileSection.basics
                        ? latestWeight
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                _ResponseStyleCard(profile: profile),
              ],
            );
          },
        );
  }
}

/// Egy szakasz kártyája. Koppintásra megnyílik a szerkesztőoldal.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.profile,
    this.latestWeight,
  });

  final ProfileSection section;
  final UserProfile profile;

  /// A legutóbbi testsúlyt tartalmazó mérés (csak az Alapadatoknál).
  final Measurement? latestWeight;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileSectionEditScreen(section: section, profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = section.summaryOf(profile);
    final filled = lines.isNotEmpty;

    final header = Row(
      children: [
        Icon(section.icon, color: scheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(section.title, style: theme.textTheme.titleLarge),
        ),
        if (filled)
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant)
        else
          Text(
            'Kitöltés',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );

    final Widget body;
    if (!filled) {
      body = Text(
        'Még nincs kitöltve',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    } else if (section == ProfileSection.macros) {
      body = _MacroTiles(profile: profile);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
              child: Text(
                lines[i],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: i == 0
                    ? theme.textTheme.bodyLarge
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
              ),
            ),
        ],
      );
    }

    // A ki nem töltött szakasz keretes, kitöltés nélküli kártya,
    // hogy ránézésre látszódjon, mi hiányzik még.
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: filled ? null : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: filled
            ? BorderSide.none
            : BorderSide(color: scheme.outline, width: 1.2),
      ),
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: body,
              ),
              if (latestWeight != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 10),
                  child: _WeightLine(measurement: latestWeight!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A legutóbbi testsúly a mérésekből, a mérés dátumával.
/// Itt nem szerkeszthető: mindig a Mérések fülről jön.
class _WeightLine extends StatelessWidget {
  const _WeightLine({required this.measurement});

  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weight =
        measurement.weightKg!.toStringAsFixed(1).replaceAll('.', ',');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_weight_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$weight kg',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' · a ${huShortDateAdjective(measurement.date)} '
                        'mérésből',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// A négy makrócél kis csempéken, alatta a forrás megjegyzésével.
class _MacroTiles extends StatelessWidget {
  const _MacroTiles({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String value(int? number, String unit) =>
        number == null ? '–' : '$number$unit';

    final tiles = [
      (value(profile.calorieTarget, ''), 'kcal'),
      (value(profile.proteinTargetG, ' g'), 'fehérje'),
      (value(profile.carbTargetG, ' g'), 'szénhidrát'),
      (value(profile.fatTargetG, ' g'), 'zsír'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tiles[i].$1,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        tiles[i].$2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'A Yazióban beállított céljaid, kézzel átmásolva.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A válaszstílus közvetlenül a kártyán állítható, azonnal mentődik.
class _ResponseStyleCard extends ConsumerWidget {
  const _ResponseStyleCard({required this.profile});

  final UserProfile profile;

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    ResponseStyle style,
  ) async {
    try {
      await ref
          .read(profileProvider.notifier)
          .save(profile.copyWith(responseStyle: style));
    } catch (error) {
      if (context.mounted) {
        showAppMessage(context, 'Nem sikerült menteni: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: scheme.primary, size: 22),
                const SizedBox(width: 10),
                Text('Válaszstílus', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<ResponseStyle>(
              expandedInsets: EdgeInsets.zero,
              segments: [
                for (final style in ResponseStyle.values)
                  ButtonSegment(value: style, label: Text(style.label)),
              ],
              selected: {profile.responseStyle},
              onSelectionChanged: (selection) =>
                  _select(context, ref, selection.first),
            ),
            const SizedBox(height: 10),
            Text(
              profile.responseStyle.help,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Emlékeztető, amíg a profil nagyrészt üres.
class _FillReminderCard extends StatelessWidget {
  const _FillReminderCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Töltsd ki a profilod',
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Az AI ebből dolgozik: minél többet tud rólad, annál '
              'pontosabban tud tervezni.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileWizardScreen(initial: profile),
                  ),
                );
              },
              child: const Text('Kitöltés lépésenként'),
            ),
          ],
        ),
      ),
    );
  }
}
