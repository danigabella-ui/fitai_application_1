import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/choice_fields.dart';
import '../../../shared/widgets/dialogs.dart';
import '../application/injuries_controller.dart';
import '../domain/injury.dart';
import 'injury_widgets.dart';

/// Új állapotfrissítés egy sérüléshez, vagy egy korábbi módosítása.
/// Itt állítható át a sérülés állapota is (pl. gyógyultra).
class InjuryUpdateScreen extends ConsumerStatefulWidget {
  const InjuryUpdateScreen({super.key, required this.injury, this.editIndex});

  final Injury injury;

  /// A módosított frissítés sorszáma (0 = legfrissebb); null, ha új.
  final int? editIndex;

  @override
  ConsumerState<InjuryUpdateScreen> createState() =>
      _InjuryUpdateScreenState();
}

class _InjuryUpdateScreenState extends ConsumerState<InjuryUpdateScreen> {
  late final InjuryUpdate? _existing = widget.editIndex == null
      ? null
      : widget.injury.updates[widget.editIndex!];

  late DateTime _date = _existing?.date ?? _today();
  late LoadCapacity? _capacity =
      _existing?.capacity ?? widget.injury.latestUpdate?.capacity;
  late final Set<Movement> _problems = {
    ...(_existing?.problemMovements ??
        widget.injury.latestUpdate?.problemMovements ??
        const <Movement>{}),
  };
  late final TextEditingController _noteController =
      TextEditingController(text: _existing?.medicalNote ?? '');
  late InjuryStatus _status = widget.injury.status;

  bool _dirty = false;
  bool _saving = false;

  bool get _isEdit => widget.editIndex != null;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _changed(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    final update = InjuryUpdate(
      date: _date,
      capacity: _capacity,
      problemMovements: {..._problems},
      medicalNote: note.isEmpty ? null : note,
    );

    final updates = [...widget.injury.updates];
    final index = widget.editIndex;
    if (index == null) {
      updates.add(update);
    } else {
      updates[index] = update;
    }

    await _store(
      widget.injury.copyWith(updates: updates, status: _status),
      'Állapot elmentve.',
    );
  }

  Future<void> _delete() async {
    final index = widget.editIndex;
    if (index == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Törlöd ezt a frissítést?',
      message: 'Csak ez az egy állapotfrissítés törlődik, a sérülés megmarad.',
      confirmLabel: 'Törlés',
    );
    if (!confirmed || !mounted) return;

    final updates = [...widget.injury.updates]..removeAt(index);
    await _store(
      widget.injury.copyWith(updates: updates),
      'Frissítés törölve.',
    );
  }

  Future<void> _store(Injury injury, String message) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    try {
      await ref.read(injuriesProvider.notifier).save(injury);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, 'Nem sikerült menteni: $error');
      return;
    }

    navigator.pop();
    showMessageWith(messenger, message);
  }

  Future<void> _handleBack() async {
    if (!_dirty) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Frissítés módosítása' : 'Állapot frissítése'),
        ),
        body: AppBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                injuryTitle(widget.injury),
                style: theme.textTheme.titleLarge,
              ),
              if (!_isEdit && widget.injury.latestUpdate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Az előző állapotból indulunk, csak azt módosítsd, '
                  'ami változott.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PastDateField(
                label: 'Dátum',
                date: _date,
                onChanged: (value) {
                  if (value != null) _changed(() => _date = value);
                },
              ),
              const SizedBox(height: 22),
              InjuryUpdateFields(
                capacity: _capacity,
                onCapacityChanged: (value) => _changed(() => _capacity = value),
                problems: _problems,
                onChanged: () => _changed(() {}),
                noteController: _noteController,
              ),
              const SizedBox(height: 22),
              LabeledField(
                label: 'A sérülés állapota',
                helper: 'Ha már nem okoz gondot, állítsd „Gyógyult”-ra.',
                child: SingleChoiceChips<InjuryStatus>(
                  options: InjuryStatus.values,
                  selected: _status,
                  labelOf: (v) => v.label,
                  onChanged: (value) {
                    if (value != null) _changed(() => _status = value);
                  },
                ),
              ),
              const SizedBox(height: 28),
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
                  label: const Text('Frissítés törlése'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
