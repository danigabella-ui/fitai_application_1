import 'package:flutter/material.dart';

import '../../../shared/widgets/choice_fields.dart';
import '../domain/injury.dart';

/// A sérülés címe, pl. „Térd, bal” vagy „Váll, mindkét oldal”.
String injuryTitle(Injury injury) {
  final area = injury.area?.label ?? 'Ismeretlen testrész';
  return switch (injury.side) {
    null => area,
    InjurySide.both => '$area, mindkét oldal',
    InjurySide side => '$area, ${side.label.toLowerCase()}',
  };
}

/// Az állapot kis címkéje (Aktív / Rehabilitáció / Gyógyult).
class InjuryStatusChip extends StatelessWidget {
  const InjuryStatusChip({super.key, required this.status});

  final InjuryStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (status) {
      InjuryStatus.active => (scheme.primary, scheme.onPrimary),
      InjuryStatus.rehab => (scheme.primaryContainer, scheme.onPrimaryContainer),
      InjuryStatus.healed => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A terhelhetőség négy szeletben, mellette a felirattal.
class CapacityBar extends StatelessWidget {
  const CapacityBar({super.key, required this.capacity});

  final LoadCapacity? capacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final level = capacity == null ? -1 : capacity!.index;

    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Row(
            children: [
              for (var i = 0; i < LoadCapacity.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= level ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            capacity?.label ?? 'Terhelhetőség nincs megadva',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Egy állapotfrissítés mezői: terhelhetőség, gondot okozó mozgások és
/// orvosi utasítás. Az új sérülés és a frissítés űrlapja is ezt használja.
class InjuryUpdateFields extends StatelessWidget {
  const InjuryUpdateFields({
    super.key,
    required this.capacity,
    required this.onCapacityChanged,
    required this.problems,
    required this.onChanged,
    required this.noteController,
  });

  final LoadCapacity? capacity;
  final ValueChanged<LoadCapacity?> onCapacityChanged;

  /// A gondot okozó mozgások; a választók közvetlenül módosítják.
  final Set<Movement> problems;
  final VoidCallback onChanged;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Mennyire terhelhető most?',
          child: SingleChoiceChips<LoadCapacity>(
            options: LoadCapacity.values,
            selected: capacity,
            labelOf: (v) => v.label,
            onChanged: onCapacityChanged,
          ),
        ),
        const SizedBox(height: 22),
        LabeledField(
          label: 'Mi okoz még gondot? (több is választható)',
          child: MultiChoiceChips<Movement>(
            options: Movement.values,
            selected: problems,
            labelOf: (v) => v.label,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 22),
        TextFormField(
          controller: noteController,
          minLines: 1,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'Orvosi vagy gyógytornász utasítás (nem kötelező)',
            hintText: 'pl. június végéig nincs futás',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
