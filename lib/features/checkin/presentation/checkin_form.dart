import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/number_input.dart';
import '../../../shared/widgets/dialogs.dart';
import '../application/checkin_controller.dart';
import '../domain/check_in.dart';
import 'checkin_widgets.dart';

/// A check-in űrlapja: négy csúszka, Watch-pontszám és fájdalom.
///
/// A Check-In fülön (mai, még ki nem töltött nap) és a pótlás/javítás
/// képernyőjén is ez jelenik meg. Mentéskor maga ír az adatbázisba, majd
/// az [onSaved]-del jelez.
class CheckInForm extends ConsumerStatefulWidget {
  const CheckInForm({
    super.key,
    required this.day,
    this.existing,
    required this.onSaved,
    this.onDirtyChanged,
  });

  /// Melyik napra szól.
  final DateTime day;

  /// A nap meglévő check-inje; null, ha még nincs.
  final CheckIn? existing;

  final ValueChanged<CheckIn> onSaved;

  /// Jelez, amikor az első módosítás megtörténik (a kilépéskori
  /// elvetés-kérdéshez).
  final ValueChanged<bool>? onDirtyChanged;

  @override
  ConsumerState<CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends ConsumerState<CheckInForm> {
  final _formKey = GlobalKey<FormState>();

  late final Map<CheckInMetric, int?> _values = {
    for (final metric in CheckInMetric.values)
      metric: widget.existing?.valueOf(metric),
  };
  late final TextEditingController _watchController = TextEditingController(
    text: widget.existing?.watchSleepScore?.toString() ?? '',
  );
  late final List<PainSpot> _pains = [...?widget.existing?.pains];
  late bool _hasPain = _pains.isNotEmpty;

  bool _dirty = false;
  bool _saving = false;

  bool get _isToday => CheckIn.isSameDay(widget.day, DateTime.now());

  int get _missing => _values.values.where((v) => v == null).length;

  @override
  void dispose() {
    _watchController.dispose();
    super.dispose();
  }

  void _changed(VoidCallback change) {
    setState(change);
    if (!_dirty) {
      _dirty = true;
      widget.onDirtyChanged?.call(true);
    }
  }

  void _setValue(CheckInMetric metric, int value) {
    if (_values[metric] == value) return;
    _changed(() => _values[metric] = value);
  }

  Future<void> _setHasPain(bool value) async {
    _changed(() {
      _hasPain = value;
      if (!value) _pains.clear();
    });
    // Bekapcsoláskor rögtön megnyílik a helyválasztó.
    if (value && _pains.isEmpty) await _addPain();
  }

  Future<void> _addPain() async {
    final spot = await showPainSpotSheet(
      context,
      takenKeys: {for (final pain in _pains) pain.key},
    );
    if (spot == null || !mounted) return;
    _changed(() => _pains.add(spot));
  }

  Future<void> _editPain(int index) async {
    final current = _pains[index];
    final spot = await showPainSpotSheet(
      context,
      initial: current,
      takenKeys: {
        for (final pain in _pains)
          if (pain.key != current.key) pain.key,
      },
    );
    if (spot == null || !mounted) return;
    _changed(() => _pains[index] = spot);
  }

  void _removePain(int index) {
    _changed(() => _pains.removeAt(index));
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;

    final sleep = _values[CheckInMetric.sleep];
    final energy = _values[CheckInMetric.energy];
    final soreness = _values[CheckInMetric.soreness];
    final stress = _values[CheckInMetric.stress];
    if (sleep == null || energy == null || soreness == null || stress == null) {
      showAppMessage(context, 'Állítsd be mind a négy csúszkát.');
      return;
    }
    if (_hasPain && _pains.isEmpty) {
      showAppMessage(
        context,
        'Add meg, hol fáj, vagy kapcsold ki a fájdalmat.',
      );
      return;
    }

    final checkIn = CheckIn(
      date: DateTime(widget.day.year, widget.day.month, widget.day.day),
      sleepQuality: sleep,
      energy: energy,
      soreness: soreness,
      stress: stress,
      watchSleepScore: parseWholeNumber(_watchController.text),
      pains: _hasPain
          ? List<PainSpot>.unmodifiable(_pains)
          : const <PainSpot>[],
      // Módosításkor az első kitöltés ideje megmarad.
      filledAt: widget.existing?.filledAt ?? DateTime.now(),
    );

    setState(() => _saving = true);
    try {
      await ref.read(checkInsProvider.notifier).save(checkIn);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, 'Nem sikerült menteni: $error');
      return;
    }

    widget.onSaved(checkIn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final missing = _missing;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final metric in CheckInMetric.values) ...[
            MetricSlider(
              metric: metric,
              value: _values[metric],
              enabled: !_saving,
              onChanged: (value) => _setValue(metric, value),
            ),
            const SizedBox(height: 18),
          ],
          const SizedBox(height: 4),
          TextFormField(
            controller: _watchController,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: numberValidator(min: 0, max: 100, wholeNumber: true),
            onChanged: (_) => _changed(() {}),
            decoration: const InputDecoration(
              labelText: 'Apple Watch alváspontszám (nem kötelező)',
              hintText: '0–100',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _isToday ? 'Fáj ma valami?' : 'Fájt valami aznap?',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: const Text('Konkrét fájdalom, nem izomláz.'),
            value: _hasPain,
            onChanged: _saving ? null : (value) => _setHasPain(value),
          ),
          if (_hasPain) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < _pains.length; i++) ...[
              PainSpotTile(
                spot: _pains[i],
                onTap: _saving ? null : () => _editPain(i),
                onRemove: _saving ? null : () => _removePain(i),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _saving ? null : _addPain,
              icon: const Icon(Icons.add),
              label: const Text('Hely hozzáadása'),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving || missing > 0 ? null : _save,
            child: const Text('Mentés'),
          ),
          if (missing > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Még $missing csúszka hiányzik.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}
