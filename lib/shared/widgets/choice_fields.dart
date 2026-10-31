import 'package:flutter/material.dart';

import '../../core/utils/hu_dates.dart';

// Közös beviteli elemek: választógombok, felirat, dátummező.
// A profil és a sérülésnapló űrlapjai is ezeket használják.

/// Egy lehetőség választható gombokból. Újra koppintva a választás törlődik
/// (null értékkel jelez).
class SingleChoiceChips<T> extends StatelessWidget {
  const SingleChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(labelOf(option)),
            showCheckmark: false,
            selected: option == selected,
            onSelected: (isSelected) => onChanged(isSelected ? option : null),
          ),
      ],
    );
  }
}

/// Több lehetőség választható gombokból. A [selected] halmazt közvetlenül
/// módosítja, majd jelez az [onChanged]-dzsel.
class MultiChoiceChips<T> extends StatelessWidget {
  const MultiChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelOf;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(labelOf(option)),
            selected: selected.contains(option),
            onSelected: (isSelected) {
              if (isSelected) {
                selected.add(option);
              } else {
                selected.remove(option);
              }
              onChanged();
            },
          ),
      ],
    );
  }
}

/// Felirat egy nem szöveges mező (választógombok, dátum, idő) fölött,
/// alatta opcionális szürke magyarázattal.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (helper != null) ...[
          const SizedBox(height: 8),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}

/// Múltbeli (vagy mai) dátum választása naptárból, felirattal.
/// Ha [allowClear] igaz, az X gomb törli a dátumot.
class PastDateField extends StatelessWidget {
  const PastDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.allowClear = false,
    this.emptyText = 'Dátum megadása',
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;
  final String emptyText;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(2000);
    final current = date;
    final initial = current == null ||
            current.isAfter(today) ||
            current.isBefore(firstDate)
        ? today
        : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: today,
      helpText: label,
    );
    if (picked == null) return;
    onChanged(DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final current = date;
    return LabeledField(
      label: label,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () => _pick(context),
              icon: const Icon(Icons.event_outlined),
              label: Text(current == null ? emptyText : huFullDate(current)),
            ),
          ),
          if (allowClear && current != null)
            IconButton(
              tooltip: 'Dátum törlése',
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}
