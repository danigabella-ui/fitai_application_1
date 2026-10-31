import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/choice_fields.dart';
import '../../../shared/widgets/dialogs.dart';
import '../application/injuries_controller.dart';
import '../domain/injury.dart';
import 'injury_widgets.dart';

/// Új sérülés rögzítése, vagy egy meglévő alapadatainak módosítása
/// és törlése. Új sérülésnél a jelenlegi állapot is megadható.
class InjuryEditScreen extends ConsumerStatefulWidget {
  const InjuryEditScreen({super.key, this.existing});

  /// A módosított sérülés; null, ha újat rögzítünk.
  final Injury? existing;

  @override
  ConsumerState<InjuryEditScreen> createState() => _InjuryEditScreenState();
}

class _InjuryEditScreenState extends ConsumerState<InjuryEditScreen> {
  late BodyArea? _area = widget.existing?.area;
  late InjurySide? _side = widget.existing?.side;
  late InjuryType? _type = widget.existing?.type;
  late DateTime? _startDate = widget.existing?.startDate;
  late InjuryStatus _status = widget.existing?.status ?? InjuryStatus.active;

  // Új sérülésnél: a jelenlegi állapot
  LoadCapacity? _capacity;
  final Set<Movement> _problems = {};
  final _noteController = TextEditingController();

  bool _dirty = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

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
    final area = _area;
    if (area == null) {
      showAppMessage(context, 'Válaszd ki, melyik testrész sérült.');
      return;
    }

    final existing = widget.existing;
    final note = _noteController.text.trim();
    final hasState = _capacity != null || _problems.isNotEmpty || note.isNotEmpty;
    final now = DateTime.now();

    final injury = existing == null
        ? Injury(
            area: area,
            side: _side,
            type: _type,
            startDate: _startDate,
            status: _status,
            createdAt: now,
            updates: [
              if (hasState)
                InjuryUpdate(
                  date: DateTime(now.year, now.month, now.day),
                  capacity: _capacity,
                  problemMovements: {..._problems},
                  medicalNote: note.isEmpty ? null : note,
                ),
            ],
          )
        : existing.copyWith(
            area: area,
            side: _side,
            type: _type,
            startDate: _startDate,
            status: _status,
          );

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
    showMessageWith(messenger, 'Sérülés elmentve.');
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Törlöd ezt a sérülést?',
      message: 'Az összes állapotfrissítése is törlődik. Ezt nem lehet '
          'visszavonni. Ha meggyógyult, inkább állítsd „Gyógyult” '
          'állapotúra: így az AI továbbra is tudja, hogy ott korábban gond volt.',
      confirmLabel: 'Törlés',
    );
    if (!confirmed || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    try {
      await ref.read(injuriesProvider.notifier).delete(id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, 'Nem sikerült törölni: $error');
      return;
    }

    // Vissza a Profil fülre (a sérülés oldala már nem létezik).
    navigator.popUntil((route) => route.isFirst);
    showMessageWith(messenger, 'Sérülés törölve.');
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
          title: Text(_isEdit ? 'Sérülés adatai' : 'Új sérülés'),
        ),
        body: AppBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              LabeledField(
                label: 'Melyik testrész?',
                child: SingleChoiceChips<BodyArea>(
                  options: BodyArea.values,
                  selected: _area,
                  labelOf: (v) => v.label,
                  onChanged: (value) => _changed(() => _area = value),
                ),
              ),
              const SizedBox(height: 22),
              LabeledField(
                label: 'Melyik oldal?',
                child: SingleChoiceChips<InjurySide>(
                  options: InjurySide.values,
                  selected: _side,
                  labelOf: (v) => v.label,
                  onChanged: (value) => _changed(() => _side = value),
                ),
              ),
              const SizedBox(height: 22),
              LabeledField(
                label: 'Típus',
                child: SingleChoiceChips<InjuryType>(
                  options: InjuryType.values,
                  selected: _type,
                  labelOf: (v) => v.label,
                  onChanged: (value) => _changed(() => _type = value),
                ),
              ),
              const SizedBox(height: 22),
              PastDateField(
                label: 'Mikor kezdődött (vagy mikor volt a műtét)?',
                date: _startDate,
                allowClear: true,
                onChanged: (value) => _changed(() => _startDate = value),
              ),
              const SizedBox(height: 22),
              LabeledField(
                label: 'Állapot',
                child: SingleChoiceChips<InjuryStatus>(
                  options: InjuryStatus.values,
                  selected: _status,
                  labelOf: (v) => v.label,
                  // Az állapot mindig ki van választva.
                  onChanged: (value) {
                    if (value != null) _changed(() => _status = value);
                  },
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 28),
                Text('Jelenlegi állapot', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Nem kötelező, de ebből indul az idővonal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                InjuryUpdateFields(
                  capacity: _capacity,
                  onCapacityChanged: (value) =>
                      _changed(() => _capacity = value),
                  problems: _problems,
                  onChanged: () => _changed(() {}),
                  noteController: _noteController,
                ),
              ],
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
                  label: const Text('Sérülés törlése'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
