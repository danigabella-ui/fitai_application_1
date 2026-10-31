import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../core/utils/number_input.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/dialogs.dart';
import '../application/measurements_controller.dart';
import '../domain/measurement.dart';

/// Új mérés rögzítése, vagy egy meglévő szerkesztése és törlése.
class MeasurementEditScreen extends ConsumerStatefulWidget {
  const MeasurementEditScreen({super.key, this.existing});

  /// A szerkesztett mérés; null, ha új mérést rögzítünk.
  final Measurement? existing;

  @override
  ConsumerState<MeasurementEditScreen> createState() =>
      _MeasurementEditScreenState();
}

class _MeasurementEditScreenState extends ConsumerState<MeasurementEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<MeasurementField, TextEditingController> _controllers;
  late final Map<MeasurementField, String> _initialTexts;
  late DateTime _date;
  late final DateTime _initialDate;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
    _date = existing == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(existing.date.year, existing.date.month, existing.date.day);
    _initialDate = _date;
    _controllers = {
      for (final field in MeasurementField.values)
        field: TextEditingController(
          text: _format(existing?.valueOf(field)),
        ),
    };
    _initialTexts = {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _format(double? value) =>
      value == null ? '' : value.toStringAsFixed(1).replaceAll('.', ',');

  bool get _hasChanges =>
      _date != _initialDate ||
      MeasurementField.values.any(
        (field) => _controllers[field]!.text != _initialTexts[field],
      );

  Measurement _buildMeasurement() => Measurement.fromValues(_date, {
        for (final field in MeasurementField.values)
          field: parseDecimal(_controllers[field]!.text),
      });

  String get _originalId {
    final existing = widget.existing!;
    return existing.id ?? existing.dayKey;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(2000);
    final initial =
        _date.isAfter(today) || _date.isBefore(firstDate) ? today : _date;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: today,
      helpText: 'A mérés napja',
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final measurement = _buildMeasurement();
    if (!measurement.hasAnyValue) {
      showAppMessage(
        context,
        _isEdit
            ? 'Üres mérést nem lehet menteni. Ha nincs rá szükség, töröld.'
            : 'Tölts ki legalább egy mezőt.',
      );
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(measurementsProvider.notifier);

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await controller.replace(_originalId, measurement);
      } else {
        await controller.addOrMerge(measurement);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, 'Nem sikerült menteni: $error');
      return;
    }

    navigator.pop();
    showMessageWith(messenger, 'Mérés elmentve.');
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Törlöd ezt a mérést?',
      message: 'A ${huShortDateAdjective(existing.date)} mérés minden értéke '
          'törlődik. Ezt nem lehet visszavonni.',
      confirmLabel: 'Törlés',
    );
    if (!confirmed || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    try {
      await ref.read(measurementsProvider.notifier).delete(_originalId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, 'Nem sikerült törölni: $error');
      return;
    }

    navigator.pop();
    showMessageWith(messenger, 'Mérés törölve.');
  }

  Future<void> _handleBack() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await showConfirmDialog(
      context,
      title: 'Elveted a módosításokat?',
      message: 'Ha most kilépsz, a változtatásaid nem mentődnek el.',
      confirmLabel: 'Elvetem',
    );
    if (!discard || !mounted) return;
    Navigator.of(context).pop();
  }

  /// Ugyanarra a napra már rögzített másik mérés (ha van).
  Measurement? _sameDayMeasurement(List<Measurement> all) {
    final key = Measurement.dayKeyOf(_date);
    final ownId = widget.existing == null ? null : _originalId;
    for (final measurement in all) {
      final id = measurement.id ?? measurement.dayKey;
      if (measurement.dayKey == key && id != ownId) return measurement;
    }
    return null;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year ? huLongDate(date) : huFullDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final all = ref.watch(measurementsProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <Measurement>[],
        );
    final sameDay = _sameDayMeasurement(all);

    return PopScope<Object?>(
      // A visszalépést mi kezeljük, hogy rá tudjunk kérdezni.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Mérés szerkesztése' : 'Új mérés'),
        ),
        body: AppBackground(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (!_isEdit) ...[
                  Text(
                    'Csak azt töltsd ki, amit most mértél. '
                    'A tizedesvessző is jó (82,4).',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Dátum',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(_dateLabel(_date)),
                ),
                if (sameDay != null) ...[
                  const SizedBox(height: 12),
                  _SameDayNotice(existing: sameDay),
                ],
                const SizedBox(height: 20),
                _field(MeasurementField.weight, sameDay),
                const SizedBox(height: 24),
                Text('Körméretek (cm)', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (var i = 0;
                    i < MeasurementField.circumferences.length;
                    i += 2) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          MeasurementField.circumferences[i],
                          sameDay,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: i + 1 < MeasurementField.circumferences.length
                            ? _field(
                                MeasurementField.circumferences[i + 1],
                                sameDay,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Mentés'),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    onPressed: _saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Mérés törlése'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(MeasurementField field, Measurement? sameDay) {
    final existingValue = sameDay?.valueOf(field);
    final example = field == MeasurementField.weight ? 'pl. 82,4' : '–';

    return TextFormField(
      controller: _controllers[field],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: numberValidator(
        min: field.min,
        max: field.max,
        unit: field.unit,
      ),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: existingValue == null
            ? example
            : '${_format(existingValue)} (megvan)',
        suffixText: field.unit,
        errorMaxLines: 3,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Figyelmeztetés: erre a napra már van mérés, az új értékek kiegészítik.
class _SameDayNotice extends StatelessWidget {
  const _SameDayNotice({required this.existing});

  final Measurement existing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fields = existing.filledFields
        .map((field) => field.label.toLowerCase())
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: scheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Erre a napra már van mérésed ($fields). Amit most kitöltesz, '
              'kiegészíti azt. Ha ugyanazt a mezőt újra kitöltöd, az új '
              'érték lép a helyére.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
