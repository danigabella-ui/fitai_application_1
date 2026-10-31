import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/utils/number_input.dart';
import '../domain/user_profile.dart';
import 'profile_sections.dart';

/// A profil szerkesztés alatt álló változata: a beviteli mezők tartalma.
///
/// Mentéskor az [applyTo] írja be egy szakasz mezőit a profilba. A többi
/// szakasz adatai ilyenkor változatlanok maradnak.
class ProfileDraft {
  ProfileDraft(UserProfile p)
      : birthYear = _text(p.birthYear?.toString()),
        height = _text(formatDecimal(p.heightCm)),
        goal = _text(p.goal),
        lifestyle = _text(p.lifestyle),
        trainingExperience = _text(p.trainingExperience),
        equipment = _text(p.equipment),
        dietaryNotes = _text(p.dietaryNotes),
        cookingHabits = _text(p.cookingHabits),
        foodBudget = _text(p.foodBudget),
        injuries = _text(p.injuries),
        dailySchedule = _text(p.dailySchedule),
        calories = _text(p.calorieTarget?.toString()),
        protein = _text(p.proteinTargetG?.toString()),
        carbs = _text(p.carbTargetG?.toString()),
        fat = _text(p.fatTargetG?.toString()),
        sex = p.sex,
        goalDeadline = p.goalDeadline,
        trainingDays = p.trainingDaysPerWeek;

  static TextEditingController _text(String? value) =>
      TextEditingController(text: value ?? '');

  final TextEditingController birthYear;
  final TextEditingController height;
  final TextEditingController goal;
  final TextEditingController lifestyle;
  final TextEditingController trainingExperience;
  final TextEditingController equipment;
  final TextEditingController dietaryNotes;
  final TextEditingController cookingHabits;
  final TextEditingController foodBudget;
  final TextEditingController injuries;
  final TextEditingController dailySchedule;
  final TextEditingController calories;
  final TextEditingController protein;
  final TextEditingController carbs;
  final TextEditingController fat;

  Sex? sex;
  DateTime? goalDeadline;
  int? trainingDays;

  void dispose() {
    for (final controller in [
      birthYear,
      height,
      goal,
      lifestyle,
      trainingExperience,
      equipment,
      dietaryNotes,
      cookingHabits,
      foodBudget,
      injuries,
      dailySchedule,
      calories,
      protein,
      carbs,
      fat,
    ]) {
      controller.dispose();
    }
  }

  /// A [base] profil másolata, benne a [section] szakasz mezőivel úgy,
  /// ahogy most az űrlapon állnak. Csak érvényes (ellenőrzött) űrlap
  /// után hívjuk meg.
  UserProfile applyTo(UserProfile base, ProfileSection section) {
    String? text(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    switch (section) {
      case ProfileSection.basics:
        return base.copyWith(
          birthYear: parseWholeNumber(birthYear.text),
          sex: sex,
          heightCm: parseDecimal(height.text),
        );
      case ProfileSection.goal:
        return base.copyWith(goal: text(goal), goalDeadline: goalDeadline);
      case ProfileSection.lifestyle:
        return base.copyWith(lifestyle: text(lifestyle));
      case ProfileSection.training:
        return base.copyWith(
          trainingExperience: text(trainingExperience),
          trainingDaysPerWeek: trainingDays,
          equipment: text(equipment),
        );
      case ProfileSection.nutrition:
        return base.copyWith(
          dietaryNotes: text(dietaryNotes),
          cookingHabits: text(cookingHabits),
          foodBudget: text(foodBudget),
        );
      case ProfileSection.injuries:
        return base.copyWith(injuries: text(injuries));
      case ProfileSection.schedule:
        return base.copyWith(dailySchedule: text(dailySchedule));
      case ProfileSection.macros:
        return base.copyWith(
          calorieTarget: parseWholeNumber(calories.text),
          proteinTargetG: parseWholeNumber(protein.text),
          carbTargetG: parseWholeNumber(carbs.text),
          fatTargetG: parseWholeNumber(fat.text),
        );
    }
  }

  /// Igaz, ha az űrlapon a [section] szakasz eltér a [base] profiltól.
  bool hasChanges(UserProfile base, ProfileSection section) =>
      !mapEquals(applyTo(base, section).toMap(), base.toMap());
}
