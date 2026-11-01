import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../application/checkin_controller.dart';
import '../domain/check_in.dart';
import 'checkin_edit_screen.dart';
import 'checkin_form.dart';
import 'checkin_injury_link.dart';
import 'checkin_widgets.dart';

/// Check-In fül: a reggeli gyors állapotfelmérés.
///
/// Ha ma még nincs kitöltve, felül az űrlap látszik; ha már igen, egy
/// összefoglaló kártya Módosítás gombbal. Alatta az előző 7 nap, ahol
/// bármelyik nap pótolható vagy javítható.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  late final AppLifecycleListener _lifecycle;
  Timer? _dayTimer;

  @override
  void initState() {
    super.initState();
    // Napváltás figyelése: ha az app éjfélen át nyitva maradt, vagy reggel
    // a háttérből jön elő, az új nap jelenjen meg.
    _lifecycle = AppLifecycleListener(
      onResume: _refreshDay,
      onShow: _refreshDay,
    );
    _dayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshDay(),
    );
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _refreshDay() {
    if (!mounted) return;
    ref.read(currentDayProvider.notifier).refresh();
  }

  /// Megnyitja egy nap kitöltését, pótlását vagy javítását.
  Future<void> _openEditor(DateTime day, CheckIn? existing) async {
    final saved = await Navigator.of(context).push<CheckIn>(
      MaterialPageRoute<CheckIn>(
        builder: (_) => CheckInEditScreen(day: day, existing: existing),
      ),
    );
    if (saved == null || !mounted) return;
    await _afterSave(saved, previous: existing);
  }

  Future<void> _afterSave(CheckIn saved, {CheckIn? previous}) async {
    if (!mounted) return;
    showAppMessage(context, 'Check-in elmentve.');
    // A sérülés frissítését csak a mai fájdalomnál ajánljuk fel.
    if (!CheckIn.isSameDay(saved.date, DateTime.now())) return;
    await offerInjuryUpdates(context, checkIn: saved, previous: previous);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(currentDayProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          GradientHeader(
            title: 'Check-In',
            subtitle: huLongDate(today),
          ),
          Expanded(
            child: ref.watch(checkInsProvider).when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Nem sikerült beolvasni a check-ineket: $error',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                  data: (recent) => _buildContent(context, recent),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, RecentCheckIns recent) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final todayCheckIn = recent.todayCheckIn;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (todayCheckIn != null)
          _TodaySummaryCard(
            checkIn: todayCheckIn,
            onEdit: () => _openEditor(recent.today, todayCheckIn),
          )
        else ...[
          Text('Hogy vagy ma reggel?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Állítsd be mind a négy csúszkát, a többi nem kötelező.',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 20),
          CheckInForm(
            // Új napon új, üres űrlap indul.
            key: ValueKey(CheckIn.dayKeyOf(recent.today)),
            day: recent.today,
            onSaved: (saved) => _afterSave(saved),
          ),
        ],
        const SizedBox(height: 32),
        Text(
          'Előző ${RecentCheckIns.historyDays} nap',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Koppints egy napra a pótláshoz vagy a javításhoz.',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        for (final day in recent.pastDays) ...[
          _HistoryCard(
            day: day,
            today: recent.today,
            checkIn: recent.forDay(day),
            onTap: () => _openEditor(day, recent.forDay(day)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// A mai, már kitöltött check-in összefoglalója.
class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.checkIn, required this.onEdit});

  final CheckIn checkIn;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final filledAt = checkIn.filledAt;
    final watch = checkIn.watchSleepScore;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text('Mai check-in', style: theme.textTheme.titleLarge),
                ),
                if (filledAt != null && checkIn.filledOnTheDay)
                  Text(
                    'Kitöltve ${huClock(filledAt.hour * 60 + filledAt.minute)}-kor',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            for (final metric in CheckInMetric.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        metric.label,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    ScoreBar(value: checkIn.valueOf(metric)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${checkIn.valueOf(metric)} – '
                        '${metric.levelLabel(checkIn.valueOf(metric))}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (watch != null) ...[
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Apple Watch alváspont: ',
                      style: TextStyle(color: muted),
                    ),
                    TextSpan(
                      text: '$watch',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 10),
            if (checkIn.pains.isEmpty)
              Text(
                'Nincs fájdalom.',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              )
            else
              for (final pain in checkIn.pains)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.healing, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pain.label,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Módosítás'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Egy korábbi nap sora: a négy érték röviden, vagy „Nincs kitöltve”.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.day,
    required this.today,
    required this.checkIn,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final CheckIn? checkIn;
  final VoidCallback onTap;

  String get _dayName {
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    if (CheckIn.isSameDay(day, yesterday)) return 'Tegnap';
    final weekday = huWeekday(day);
    return weekday[0].toUpperCase() + weekday.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final current = checkIn;

    return Card(
      margin: EdgeInsets.zero,
      color: current == null ? scheme.surfaceContainerLow : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: _dayName),
                          TextSpan(
                            text: '   ${huShortDate(day)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: current == null ? muted : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (current == null)
                      Text(
                        'Nincs kitöltve. Koppints a pótláshoz.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          for (final metric in CheckInMetric.values)
                            _MiniStat(
                              label: metric.label,
                              value: '${current.valueOf(metric)}',
                            ),
                          if (current.watchSleepScore != null)
                            _MiniStat(
                              label: 'Watch',
                              value: '${current.watchSleepScore}',
                            ),
                          if (current.pains.isNotEmpty)
                            _MiniStat(
                              label: 'Fájdalom:',
                              value: current.pains.length == 1
                                  ? current.pains.first.placeLabel
                                  : '${current.pains.length} hely',
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                current == null ? Icons.add : Icons.chevron_right,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kis felirat + érték, pl. „Alvás 5”.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      style: theme.textTheme.bodyMedium,
    );
  }
}
