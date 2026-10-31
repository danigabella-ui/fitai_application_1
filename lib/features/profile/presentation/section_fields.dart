import 'package:flutter/material.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../core/utils/number_input.dart';
import '../../../shared/widgets/choice_fields.dart';
import '../domain/user_profile.dart';
import 'profile_draft.dart';
import 'profile_sections.dart';

/// Egy profilszakasz beviteli mezői. A szerkesztőoldal és a vezetett
/// kitöltés is ezt használja, így a kettő mindig ugyanúgy néz ki.
///
/// Ahol lehet, választható mezők vannak (gombok, legördülő lista,
/// időválasztó), hogy az AI egyértelmű adatot kapjon. Szöveget csak ott
/// kell beírni, ahol másképp nem megy.
class SectionFields extends StatelessWidget {
  const SectionFields({
    super.key,
    required this.section,
    required this.draft,
    required this.onChanged,
  });

  final ProfileSection section;
  final ProfileDraft draft;

  /// Akkor hívódik, ha egy nem szöveges mező (pl. választógomb) változott,
  /// és a képernyőt újra kell rajzolni.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final List<Widget> fields = switch (section) {
      ProfileSection.basics => _basics(),
      ProfileSection.goal => _goal(context),
      ProfileSection.lifestyle => _lifestyle(),
      ProfileSection.training => _training(),
      ProfileSection.nutrition => _nutrition(),
      ProfileSection.schedule => _schedule(),
      ProfileSection.macros => _macros(),
    };

    final legacy = draft.legacyFor(section);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in legacy) ...[
          _LegacyBox(
            item: item,
            onClear: () {
              item.clear();
              onChanged();
            },
          ),
          const SizedBox(height: 16),
        ],
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 22),
          fields[i],
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Szakaszok
  // ---------------------------------------------------------------------------

  List<Widget> _basics() {
    return [
      _SingleLineField(
        controller: draft.birthYear,
        label: 'Születési év',
        hint: 'pl. 1995',
        keyboardType: TextInputType.number,
        validator: numberValidator(
          min: 1920,
          max: DateTime.now().year - 10,
          wholeNumber: true,
        ),
      ),
      LabeledField(
        label: 'Nem',
        child: SegmentedButton<Sex>(
          expandedInsets: EdgeInsets.zero,
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: Sex.male, label: Text('Férfi')),
            ButtonSegment(value: Sex.female, label: Text('Nő')),
          ],
          selected: draft.sex == null ? const <Sex>{} : {draft.sex!},
          onSelectionChanged: (selection) {
            draft.sex = selection.isEmpty ? null : selection.first;
            onChanged();
          },
        ),
      ),
      _SingleLineField(
        controller: draft.height,
        label: 'Magasság',
        hint: 'pl. 180',
        suffix: 'cm',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: numberValidator(min: 100, max: 250, unit: 'cm'),
      ),
    ];
  }

  List<Widget> _goal(BuildContext context) {
    final deadline = draft.goalDeadline;
    final forSport = draft.goalTypes.contains(GoalType.sport);

    return [
      LabeledField(
        label: 'Mit szeretnél elérni? (több is választható)',
        child: MultiChoiceChips<GoalType>(
          options: GoalType.values,
          selected: draft.goalTypes,
          labelOf: (v) => v.label,
          onChanged: onChanged,
        ),
      ),
      if (forSport)
        _Dropdown<Sport>(
          label: 'Melyik sportra készülsz?',
          options: Sport.values,
          value: draft.goalSport,
          labelOf: (v) => v.label,
          onChanged: (value) {
            draft.goalSport = value;
            onChanged();
          },
        ),
      if (forSport && draft.goalSport == Sport.other)
        _SingleLineField(
          controller: draft.goalSportOther,
          label: 'Melyik sport?',
          hint: 'pl. jégkorong',
        ),
      LabeledField(
        label: 'Határidő (nem kötelező)',
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => _pickDeadline(context),
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  deadline == null
                      ? 'Határidő megadása'
                      : huFullDate(deadline),
                ),
              ),
            ),
            if (deadline != null)
              IconButton(
                tooltip: 'Határidő törlése',
                onPressed: () {
                  draft.goalDeadline = null;
                  onChanged();
                },
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    ];
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 5, 12, 31);
    final current = draft.goalDeadline;
    final initial =
        current != null && !current.isBefore(today) && !current.isAfter(lastDate)
            ? current
            : today.add(const Duration(days: 90));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: lastDate,
      helpText: 'Határidő',
    );
    if (picked == null) return;
    draft.goalDeadline = picked;
    onChanged();
  }

  List<Widget> _lifestyle() {
    final working = draft.workType != WorkType.notWorking;

    return [
      _Dropdown<WorkType>(
        label: 'A munkád jellege',
        options: WorkType.values,
        value: draft.workType,
        labelOf: (v) => v.label,
        onChanged: (value) {
          draft.workType = value;
          onChanged();
        },
      ),
      if (working) ...[
        LabeledField(
          label: 'Munkarend',
          child: SingleChoiceChips<WorkSchedule>(
            options: WorkSchedule.values,
            selected: draft.workSchedule,
            labelOf: (v) => v.label,
            onChanged: (value) {
              draft.workSchedule = value;
              onChanged();
            },
          ),
        ),
        LabeledField(
          label: 'Munkanapok',
          child: _WeekdayPicker(selected: draft.workDays, onChanged: onChanged),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TimeField(
                label: 'Munka kezdete',
                minutes: draft.workStart,
                onChanged: (value) {
                  draft.workStart = value;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: 'Munka vége',
                minutes: draft.workEnd,
                onChanged: (value) {
                  draft.workEnd = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
      ],
      LabeledField(
        label: 'Mentális terhelés',
        child: SingleChoiceChips<LoadLevel>(
          options: LoadLevel.values,
          selected: draft.mentalLoad,
          labelOf: (v) => v.label,
          onChanged: (value) {
            draft.mentalLoad = value;
            onChanged();
          },
        ),
      ),
      LabeledField(
        label: 'Mozgás a munkán és az edzéseken kívül',
        helper: 'Gyaloglás, biciklizés, kerti munka és hasonlók.',
        child: SingleChoiceChips<ActivityLevel>(
          options: ActivityLevel.values,
          selected: draft.dailyActivity,
          labelOf: (v) => v.label,
          onChanged: (value) {
            draft.dailyActivity = value;
            onChanged();
          },
        ),
      ),
    ];
  }

  List<Widget> _training() {
    return [
      LabeledField(
        label: 'Tapasztalat',
        child: SingleChoiceChips<ExperienceLevel>(
          options: ExperienceLevel.values,
          selected: draft.experienceLevel,
          labelOf: (v) => '${v.label} (${v.detail})',
          onChanged: (value) {
            draft.experienceLevel = value;
            onChanged();
          },
        ),
      ),
      LabeledField(
        label: 'Heti hány napot tudsz edzeni?',
        helper: 'Egy átlagos héten. Ha egy héten kevesebb jön össze, '
            'a Naptár alkalmazkodik.',
        child: SingleChoiceChips<int>(
          options: const [1, 2, 3, 4, 5, 6, 7],
          selected: draft.trainingDays,
          labelOf: (v) => '$v',
          onChanged: (value) {
            draft.trainingDays = value;
            onChanged();
          },
        ),
      ),
      LabeledField(
        label: 'Egy edzés hossza',
        child: SingleChoiceChips<int>(
          options: sessionLengthOptions,
          selected: draft.sessionMinutes,
          labelOf: sessionLabel,
          onChanged: (value) {
            draft.sessionMinutes = value;
            onChanged();
          },
        ),
      ),
      LabeledField(
        label: 'Hol edzel? (több is választható)',
        child: MultiChoiceChips<TrainingLocation>(
          options: TrainingLocation.values,
          selected: draft.trainingLocations,
          labelOf: (v) => v.label,
          onChanged: onChanged,
        ),
      ),
      LabeledField(
        label: 'Elérhető eszközök (több is választható)',
        child: MultiChoiceChips<Equipment>(
          options: Equipment.values,
          selected: draft.equipmentItems,
          labelOf: (v) => v.label,
          onChanged: onChanged,
        ),
      ),
      LabeledField(
        label: 'Más sportot is űzöl? (több is választható)',
        child: MultiChoiceChips<Sport>(
          options: Sport.values,
          selected: draft.otherSports,
          labelOf: (v) => v.label,
          onChanged: onChanged,
        ),
      ),
    ];
  }

  List<Widget> _nutrition() {
    return [
      LabeledField(
        label: 'Étrend',
        child: SingleChoiceChips<DietType>(
          options: DietType.values,
          selected: draft.dietType,
          labelOf: (v) => v.label,
          onChanged: (value) {
            draft.dietType = value;
            onChanged();
          },
        ),
      ),
      LabeledField(
        label: 'Allergia, intolerancia (több is választható)',
        child: MultiChoiceChips<Allergy>(
          options: Allergy.values,
          selected: draft.allergies,
          labelOf: (v) => v.label,
          onChanged: onChanged,
        ),
      ),
      if (draft.allergies.contains(Allergy.other))
        _SingleLineField(
          controller: draft.allergyOther,
          label: 'Egyéb allergia',
          hint: 'pl. zeller',
        ),
      _SingleLineField(
        controller: draft.dislikedFoods,
        label: 'Amit nem eszel',
        hint: 'pl. gomba, máj',
      ),
      LabeledField(
        label: 'Napi étkezések száma',
        child: SingleChoiceChips<int>(
          options: mealsPerDayOptions,
          selected: draft.mealsPerDay,
          labelOf: (v) => '$v',
          onChanged: (value) {
            draft.mealsPerDay = value;
            onChanged();
          },
        ),
      ),
      LabeledField(
        label: 'Mennyi időd van főzni egy hétköznap?',
        child: SingleChoiceChips<CookingTime>(
          options: CookingTime.values,
          selected: draft.cookingTime,
          labelOf: (v) => v.label,
          onChanged: (value) {
            draft.cookingTime = value;
            onChanged();
          },
        ),
      ),
      LabeledField(
        label: 'Főzöl előre több napra (meal prep)?',
        child: SingleChoiceChips<MealPrep>(
          options: MealPrep.values,
          selected: draft.mealPrep,
          labelOf: (v) => v.label,
          onChanged: (value) {
            draft.mealPrep = value;
            onChanged();
          },
        ),
      ),
      _SingleLineField(
        controller: draft.budget,
        label: 'Heti kajakeret',
        hint: 'pl. 25000',
        suffix: 'Ft',
        keyboardType: TextInputType.number,
        validator: numberValidator(
          min: 0,
          max: 1000000,
          unit: 'Ft',
          wholeNumber: true,
        ),
      ),
    ];
  }

  List<Widget> _schedule() {
    final weekend = draft.weekendDifferent;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TimeField(
              label: weekend ? 'Kelés hétköznap' : 'Kelés',
              minutes: draft.wake,
              onChanged: (value) {
                draft.wake = value;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TimeField(
              label: weekend ? 'Lefekvés hétköznap' : 'Lefekvés',
              minutes: draft.sleep,
              onChanged: (value) {
                draft.sleep = value;
                onChanged();
              },
            ),
          ),
        ],
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Hétvégén máskor kelek vagy fekszem'),
        value: weekend,
        onChanged: (value) {
          draft.weekendDifferent = value;
          onChanged();
        },
      ),
      if (weekend)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TimeField(
                label: 'Kelés hétvégén',
                minutes: draft.weekendWake,
                onChanged: (value) {
                  draft.weekendWake = value;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: 'Lefekvés hétvégén',
                minutes: draft.weekendSleep,
                onChanged: (value) {
                  draft.weekendSleep = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
      LabeledField(
        label: 'Mikor tudsz edzeni? (több is választható)',
        child: MultiChoiceChips<DayPart>(
          options: DayPart.values,
          selected: draft.trainingTimes,
          labelOf: (v) => v.label,
          onChanged: onChanged,
        ),
      ),
    ];
  }

  List<Widget> _macros() {
    const keyboard = TextInputType.number;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SingleLineField(
              controller: draft.calories,
              label: 'Kalória',
              hint: 'pl. 2450',
              suffix: 'kcal',
              keyboardType: keyboard,
              validator: numberValidator(
                min: 800,
                max: 6000,
                unit: 'kcal',
                wholeNumber: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SingleLineField(
              controller: draft.protein,
              label: 'Fehérje',
              hint: 'pl. 180',
              suffix: 'g',
              keyboardType: keyboard,
              validator: numberValidator(
                min: 0,
                max: 500,
                unit: 'g',
                wholeNumber: true,
              ),
            ),
          ),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SingleLineField(
              controller: draft.carbs,
              label: 'Szénhidrát',
              hint: 'pl. 260',
              suffix: 'g',
              keyboardType: keyboard,
              validator: numberValidator(
                min: 0,
                max: 1000,
                unit: 'g',
                wholeNumber: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SingleLineField(
              controller: draft.fat,
              label: 'Zsír',
              hint: 'pl. 75',
              suffix: 'g',
              keyboardType: keyboard,
              validator: numberValidator(
                min: 0,
                max: 400,
                unit: 'g',
                wholeNumber: true,
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

// -----------------------------------------------------------------------------
// Építőelemek
// -----------------------------------------------------------------------------

/// Legördülő lista. Az első elem („Nincs megadva”) törli a választást.
class _Dropdown<T extends Object> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<T> options;
  final T? value;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<T?>(value: null, child: const Text('Nincs megadva')),
        for (final option in options)
          DropdownMenuItem<T?>(value: option, child: Text(labelOf(option))),
      ],
      onChanged: onChanged,
    );
  }
}

/// A hét napjai egy sorban (H, K, Sze …); több is kijelölhető.
/// A [selected] halmazt közvetlenül módosítja (1 = hétfő … 7 = vasárnap).
class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});

  final Set<int> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var day = 1; day <= 7; day++)
          FilterChip(
            label: Text(huWeekdayShortNames[day - 1]),
            showCheckmark: false,
            selected: selected.contains(day),
            onSelected: (isSelected) {
              if (isSelected) {
                selected.add(day);
              } else {
                selected.remove(day);
              }
              onChanged();
            },
          ),
      ],
    );
  }
}

/// Időpont választása órával, fölötte felirattal. Az érték az éjféltől
/// eltelt percek száma; az X gomb törli.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int? minutes;
  final ValueChanged<int?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final current = minutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 7, minute: 0)
          : TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: label,
    );
    if (picked == null) return;
    onChanged(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final current = minutes;
    return LabeledField(
      label: label,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => _pick(context),
              icon: const Icon(Icons.schedule),
              label: Text(current == null ? 'Megadás' : huClock(current)),
            ),
          ),
          if (current != null)
            IconButton(
              tooltip: 'Törlés',
              visualDensity: VisualDensity.compact,
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

/// Egy korábban beírt szabad szöveg, törlés gombbal.
class _LegacyBox extends StatelessWidget {
  const _LegacyBox({required this.item, required this.onClear});

  final LegacyText item;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Korábban beírt szöveg (${item.label.toLowerCase()})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.text, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  'Állítsd be a lenti választókkal, utána törölheted.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Törlés')),
        ],
      ),
    );
  }
}

/// Egysoros beviteli mező, fölötte a felirattal, benne halvány példával.
class _SingleLineField extends StatelessWidget {
  const _SingleLineField({
    required this.controller,
    required this.label,
    this.hint,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        errorMaxLines: 2,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
