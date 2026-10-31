import 'package:flutter/material.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../core/utils/number_input.dart';
import '../domain/user_profile.dart';
import 'profile_draft.dart';
import 'profile_sections.dart';

/// Egy profilszakasz beviteli mezői. A szerkesztőoldal és a vezetett
/// kitöltés is ezt használja, így a kettő mindig ugyanúgy néz ki.
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
      ProfileSection.lifestyle => [
          _TextArea(
            controller: draft.lifestyle,
            label: 'Életmód és munka',
            hint: 'pl. irodai munka, napi 8 óra ülés; a munka mentálisan '
                'megterhelő; hétvégén sokat gyalogolok',
          ),
        ],
      ProfileSection.training => _training(),
      ProfileSection.nutrition => [
          _TextArea(
            controller: draft.dietaryNotes,
            label: 'Allergiák, amit nem eszel, preferenciák',
            hint: 'pl. nincs allergiám; halat nem eszem; szeretem a csípőset',
          ),
          _TextArea(
            controller: draft.cookingHabits,
            label: 'Főzési szokások',
            hint: 'pl. hétköznap legfeljebb 20 perc főzés; vasárnap '
                'előre főzök 3 napra',
          ),
          _SingleLineField(
            controller: draft.foodBudget,
            label: 'Heti kajakeret',
            hint: 'pl. 25 000 Ft',
          ),
        ],
      ProfileSection.injuries => [
          _TextArea(
            controller: draft.injuries,
            label: 'Sérülések, korlátozások',
            hint: 'pl. bal térd: régi szalagsérülés, mély guggolásnál fáj. '
                'Ha nincs ilyen, hagyd üresen.',
          ),
        ],
      ProfileSection.schedule => [
          _TextArea(
            controller: draft.dailySchedule,
            label: 'Napirend',
            hint: 'pl. kelés 6:30, fekvés 23:00; edzeni hétköznap 18:00 '
                'után tudok, hétvégén bármikor',
          ),
        ],
      ProfileSection.macros => _macros(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          fields[i],
        ],
      ],
    );
  }

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
      _LabeledField(
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
    return [
      _TextArea(
        controller: draft.goal,
        label: 'Mi a célod?',
        hint: 'pl. szálkásodás, izomépítés és visszatérés a focihoz',
      ),
      _LabeledField(
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

  List<Widget> _training() {
    return [
      _TextArea(
        controller: draft.trainingExperience,
        label: 'Tapasztalat',
        hint: 'pl. középhaladó; 3 éve edzek rendszeresen, előtte amatőr foci',
      ),
      _LabeledField(
        label: 'Heti hány napot tudsz edzeni?',
        helper: 'Egy átlagos héten. Ha egy héten kevesebb jön össze, '
            'a Naptár alkalmazkodik.',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var days = 1; days <= 7; days++)
              ChoiceChip(
                label: Text('$days'),
                showCheckmark: false,
                selected: draft.trainingDays == days,
                onSelected: (selected) {
                  draft.trainingDays = selected ? days : null;
                  onChanged();
                },
              ),
          ],
        ),
      ),
      _TextArea(
        controller: draft.equipment,
        label: 'Elérhető eszközök',
        hint: 'pl. edzőterem; otthon kettlebell és gumiszalag',
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

/// Többsoros szöveges mező, ami a beírt szöveggel együtt nő.
class _TextArea extends StatelessWidget {
  const _TextArea({
    required this.controller,
    required this.label,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 3,
      maxLines: 10,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintMaxLines: 4,
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Felirat egy nem szöveges mező (választógombok, dátum) fölött,
/// alatta opcionális szürke magyarázattal.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
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
