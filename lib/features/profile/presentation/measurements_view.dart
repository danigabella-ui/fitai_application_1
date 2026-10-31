import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/hu_dates.dart';
import '../application/measurements_controller.dart';
import '../domain/measurement.dart';
import 'measurement_edit_screen.dart';

/// A Profil fül „Mérések” nézete: Új mérés gomb és a korábbi mérések,
/// a legfrissebb elöl.
class MeasurementsView extends ConsumerWidget {
  const MeasurementsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ref.watch(measurementsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nem sikerült beolvasni a méréseket: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
          data: (measurements) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              FilledButton.icon(
                onPressed: () => openMeasurementEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Új mérés'),
              ),
              const SizedBox(height: 12),
              if (measurements.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
                  child: Text(
                    'Még nincs mérésed. Az első mérés után itt követheted, '
                    'hogyan változnak az értékeid.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (var i = 0; i < measurements.length; i++) ...[
                _MeasurementCard(
                  measurement: measurements[i],
                  older: measurements.sublist(i + 1),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
  }
}

/// Megnyitja a mérés űrlapját: új mérést, vagy a megadott mérés
/// szerkesztését.
void openMeasurementEditor(BuildContext context, [Measurement? existing]) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MeasurementEditScreen(existing: existing),
    ),
  );
}

/// Egy mérés kártyája: a kitöltött értékek, mellettük a változás az
/// előző ugyanilyen méréshez képest.
class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.measurement, required this.older});

  final Measurement measurement;

  /// A korábbi mérések, a legfrissebb elöl.
  final List<Measurement> older;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final date = measurement.date;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openMeasurementEditor(context, measurement),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: huShortDate(date)),
                    TextSpan(
                      text: ' · ${huWeekday(date)}',
                      style: TextStyle(color: muted),
                    ),
                  ],
                ),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                },
                children: [
                  for (final field in measurement.filledFields)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            field.label,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            '${_oneDecimal(measurement.valueOf(field)!)} '
                            '${field.unit}',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            _changeText(field),
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pl. "−0,6 · 1 hete", vagy "első mérés", ha még nincs korábbi adat.
  String _changeText(MeasurementField field) {
    final current = measurement.valueOf(field)!;
    for (final previous in older) {
      final value = previous.valueOf(field);
      if (value == null) continue;
      final delta = ((current - value) * 10).round() / 10;
      final days = _daysBetween(previous.date, measurement.date);
      return '${_signed(delta)} · ${_ago(days)}';
    }
    return 'első mérés';
  }

  static String _oneDecimal(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  /// Előjeles érték valódi mínuszjellel: "−0,6", "+0,5", "±0".
  static String _signed(double delta) {
    if (delta == 0) return '±0';
    final sign = delta < 0 ? '\u2212' : '+';
    return '$sign${_oneDecimal(delta.abs())}';
  }

  /// A két mérés között eltelt idő: "3 napja", "1 hete", "4 hete".
  static String _ago(int days) {
    if (days < 7) return '$days napja';
    return '${(days / 7).round()} hete';
  }

  static int _daysBetween(DateTime from, DateTime to) {
    // UTC-ben számolunk, hogy az óraátállítás ne zavarja.
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }
}
