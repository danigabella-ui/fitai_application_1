import 'package:flutter/material.dart';

import '../../../shared/widgets/choice_fields.dart';
import '../domain/check_in.dart';

/// Egy csúszka 1–7-ig, fölötte a neve és az aktuális érték felirata,
/// alatta a két vég jelentése.
///
/// Amíg a [value] null (még nem érintették), a csúszka szürke, és nem
/// mutat értéket. Koppintásra vagy húzásra kap színt.
class MetricSlider extends StatelessWidget {
  const MetricSlider({
    super.key,
    required this.metric,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final CheckInMetric metric;
  final int? value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final current = value;

    final baseTheme = SliderTheme.of(context);
    final sliderTheme = current != null
        ? baseTheme
        : baseTheme.copyWith(
            activeTrackColor: scheme.outlineVariant,
            inactiveTrackColor: scheme.outlineVariant,
            thumbColor: scheme.outline,
            activeTickMarkColor: scheme.outline,
            inactiveTickMarkColor: scheme.outline,
            overlayColor: scheme.outline.withValues(alpha: 0.12),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(metric.label, style: theme.textTheme.titleMedium),
            ),
            Text(
              current == null
                  ? 'Nincs megadva'
                  : '$current – ${metric.levelLabel(current)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: current == null ? muted : scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: sliderTheme,
          child: Slider(
            value: (current ?? 4).toDouble(),
            min: CheckInMetric.minValue.toDouble(),
            max: CheckInMetric.maxValue.toDouble(),
            divisions: CheckInMetric.maxValue - CheckInMetric.minValue,
            // A hüvelykujj megérintése is számít, akkor is, ha nem mozdul.
            onChangeStart: enabled ? (v) => onChanged(v.round()) : null,
            onChanged: enabled ? (v) => onChanged(v.round()) : null,
            semanticFormatterCallback: (v) =>
                '${v.round()}, ${metric.levelLabel(v.round())}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  metric.levels.first,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
              Expanded(
                child: Text(
                  metric.levels.last,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Egy 1–7-es érték hét kis szeletben (mint a sérülésnapló
/// terhelhetőség-sávja).
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.value, this.width = 84});

  final int value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Row(
        children: [
          for (var i = 0; i < CheckInMetric.maxValue; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: i < value ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Egy fájdalomhely az űrlapon: koppintásra módosítható, az X-szel
/// eltávolítható.
class PainSpotTile extends StatelessWidget {
  const PainSpotTile({
    super.key,
    required this.spot,
    required this.onTap,
    required this.onRemove,
  });

  final PainSpot spot;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.healing, color: scheme.primary),
        title: Text(spot.placeLabel),
        subtitle: Text(spot.intensity.label),
        onTap: onTap,
        trailing: IconButton(
          tooltip: 'Eltávolítás',
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

/// Megnyitja a fájdalomhely választóját (testrész, oldal, erősség).
/// A [takenKeys] a listában már szereplő helyek: ugyanaz a hely nem
/// adható meg kétszer. Null, ha a felhasználó bezárta a lapot.
Future<PainSpot?> showPainSpotSheet(
  BuildContext context, {
  PainSpot? initial,
  required Set<String> takenKeys,
}) {
  return showModalBottomSheet<PainSpot>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PainSpotSheet(initial: initial, takenKeys: takenKeys),
  );
}

class _PainSpotSheet extends StatefulWidget {
  const _PainSpotSheet({required this.initial, required this.takenKeys});

  final PainSpot? initial;
  final Set<String> takenKeys;

  @override
  State<_PainSpotSheet> createState() => _PainSpotSheetState();
}

class _PainSpotSheetState extends State<_PainSpotSheet> {
  late BodyArea? _area = widget.initial?.area;
  late InjurySide? _side = widget.initial?.side;
  late PainIntensity? _intensity = widget.initial?.intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final area = _area;
    final side = _side;
    final intensity = _intensity;
    final needsSide = area != null && bodyAreaHasSides(area);

    // Kész fájdalomhely, ha minden szükséges adat megvan.
    final PainSpot? result =
        area != null && intensity != null && (!needsSide || side != null)
            ? PainSpot(
                area: area,
                side: needsSide ? side : null,
                intensity: intensity,
              )
            : null;
    final duplicate = result != null && widget.takenKeys.contains(result.key);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? 'Hol fáj?' : 'Fájdalom módosítása',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Testrész',
            child: SingleChoiceChips<BodyArea>(
              options: BodyArea.values,
              selected: _area,
              labelOf: (v) => v.label,
              onChanged: (value) => setState(() {
                _area = value;
                if (value != null && !bodyAreaHasSides(value)) _side = null;
              }),
            ),
          ),
          if (needsSide) ...[
            const SizedBox(height: 20),
            LabeledField(
              label: 'Melyik oldal?',
              child: SingleChoiceChips<InjurySide>(
                options: InjurySide.values,
                selected: _side,
                labelOf: (v) => v.label,
                onChanged: (value) => setState(() => _side = value),
              ),
            ),
          ],
          const SizedBox(height: 20),
          LabeledField(
            label: 'Mennyire erős?',
            child: SingleChoiceChips<PainIntensity>(
              options: PainIntensity.values,
              selected: _intensity,
              labelOf: (v) => v.label,
              onChanged: (value) => setState(() => _intensity = value),
            ),
          ),
          if (duplicate) ...[
            const SizedBox(height: 12),
            Text(
              'Ez a hely már szerepel a listában.',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: result == null || duplicate
                ? null
                : () => Navigator.of(context).pop(result),
            child: Text(widget.initial == null ? 'Hozzáadás' : 'Kész'),
          ),
        ],
      ),
    );
  }
}
