import 'package:flutter/widgets.dart';

import '../../../core/utils/number_input.dart';
import '../domain/user_profile.dart';
import 'profile_sections.dart';

/// Egy korábban beírt szabad szöveg, ami még megjelenik a szerkesztéskor,
/// amíg a felhasználó nem törli.
class LegacyText {
  const LegacyText(this.label, this.text, this.clear);

  final String label;
  final String text;
  final VoidCallback clear;
}

/// A profil szerkesztés alatt álló változata: a beviteli mezők tartalma.
///
/// Mentéskor az [applyTo] írja be egy szakasz mezőit a profilba. A többi
/// szakasz adatai ilyenkor változatlanok maradnak.
class ProfileDraft {
  ProfileDraft(UserProfile p)
      : birthYear = _text(p.birthYear?.toString()),
        height = _text(formatDecimal(p.heightCm)),
        goalSportOther = _text(p.goalSportOther),
        allergyOther = _text(p.allergyOther),
        dislikedFoods = _text(p.dislikedFoods),
        budget = _text(p.weeklyFoodBudget?.toString()),
        calories = _text(p.calorieTarget?.toString()),
        protein = _text(p.proteinTargetG?.toString()),
        carbs = _text(p.carbTargetG?.toString()),
        fat = _text(p.fatTargetG?.toString()),
        sex = p.sex,
        goalTypes = {...p.goalTypes},
        goalSport = p.goalSport,
        goalDeadline = p.goalDeadline,
        workType = p.workType,
        workSchedule = p.workSchedule,
        workDays = {...p.workDays},
        workStart = p.workStartMinutes,
        workEnd = p.workEndMinutes,
        mentalLoad = p.mentalLoad,
        dailyActivity = p.dailyActivity,
        experienceLevel = p.experienceLevel,
        trainingDays = p.trainingDaysPerWeek,
        sessionMinutes = p.sessionMinutes,
        trainingLocations = {...p.trainingLocations},
        equipmentItems = {...p.equipmentItems},
        otherSports = {...p.otherSports},
        dietType = p.dietType,
        allergies = {...p.allergies},
        mealsPerDay = p.mealsPerDay,
        cookingTime = p.cookingTime,
        mealPrep = p.mealPrep,
        wake = p.wakeMinutes,
        sleep = p.sleepMinutes,
        weekendDifferent = p.weekendDifferent,
        weekendWake = p.weekendWakeMinutes,
        weekendSleep = p.weekendSleepMinutes,
        trainingTimes = {...p.trainingTimes},
        legacyGoal = p.goal,
        legacyLifestyle = p.lifestyle,
        legacyTrainingExperience = p.trainingExperience,
        legacyEquipment = p.equipment,
        legacyDietaryNotes = p.dietaryNotes,
        legacyCookingHabits = p.cookingHabits,
        legacyFoodBudget = p.foodBudget,
        legacyDailySchedule = p.dailySchedule;

  static TextEditingController _text(String? value) =>
      TextEditingController(text: value ?? '');

  // Szöveges és számmezők
  final TextEditingController birthYear;
  final TextEditingController height;
  final TextEditingController goalSportOther;
  final TextEditingController allergyOther;
  final TextEditingController dislikedFoods;
  final TextEditingController budget;
  final TextEditingController calories;
  final TextEditingController protein;
  final TextEditingController carbs;
  final TextEditingController fat;

  // Választható mezők
  Sex? sex;
  Set<GoalType> goalTypes;
  Sport? goalSport;
  DateTime? goalDeadline;
  WorkType? workType;
  WorkSchedule? workSchedule;
  Set<int> workDays;
  int? workStart;
  int? workEnd;
  LoadLevel? mentalLoad;
  ActivityLevel? dailyActivity;
  ExperienceLevel? experienceLevel;
  int? trainingDays;
  int? sessionMinutes;
  Set<TrainingLocation> trainingLocations;
  Set<Equipment> equipmentItems;
  Set<Sport> otherSports;
  DietType? dietType;
  Set<Allergy> allergies;
  int? mealsPerDay;
  CookingTime? cookingTime;
  MealPrep? mealPrep;
  int? wake;
  int? sleep;
  bool weekendDifferent;
  int? weekendWake;
  int? weekendSleep;
  Set<DayPart> trainingTimes;

  // Korábbi szabad szövegek (csak törölhetők)
  String? legacyGoal;
  String? legacyLifestyle;
  String? legacyTrainingExperience;
  String? legacyEquipment;
  String? legacyDietaryNotes;
  String? legacyCookingHabits;
  String? legacyFoodBudget;
  String? legacyDailySchedule;

  void dispose() {
    for (final controller in [
      birthYear,
      height,
      goalSportOther,
      allergyOther,
      dislikedFoods,
      budget,
      calories,
      protein,
      carbs,
      fat,
    ]) {
      controller.dispose();
    }
  }

  /// A szakasz még meglévő, korábban beírt szabad szövegei.
  List<LegacyText> legacyFor(ProfileSection section) {
    final result = <LegacyText>[];
    void add(String label, String? value, VoidCallback clear) {
      if (value != null && value.trim().isNotEmpty) {
        result.add(LegacyText(label, value.trim(), clear));
      }
    }

    switch (section) {
      case ProfileSection.goal:
        add('Cél', legacyGoal, () => legacyGoal = null);
      case ProfileSection.lifestyle:
        add('Életmód és munka', legacyLifestyle, () => legacyLifestyle = null);
      case ProfileSection.training:
        add(
          'Tapasztalat',
          legacyTrainingExperience,
          () => legacyTrainingExperience = null,
        );
        add('Eszközök', legacyEquipment, () => legacyEquipment = null);
      case ProfileSection.nutrition:
        add(
          'Étkezési szempontok',
          legacyDietaryNotes,
          () => legacyDietaryNotes = null,
        );
        add(
          'Főzési szokások',
          legacyCookingHabits,
          () => legacyCookingHabits = null,
        );
        add('Heti keret', legacyFoodBudget, () => legacyFoodBudget = null);
      case ProfileSection.schedule:
        add('Napirend', legacyDailySchedule, () => legacyDailySchedule = null);
      case ProfileSection.basics:
      case ProfileSection.macros:
        break;
    }
    return result;
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
        final forSport = goalTypes.contains(GoalType.sport);
        final sport = forSport ? goalSport : null;
        return base.copyWith(
          goalTypes: {...goalTypes},
          goalSport: sport,
          goalSportOther: sport == Sport.other ? text(goalSportOther) : null,
          goalDeadline: goalDeadline,
          goal: legacyGoal,
        );
      case ProfileSection.lifestyle:
        final working = workType != WorkType.notWorking;
        return base.copyWith(
          workType: workType,
          workSchedule: working ? workSchedule : null,
          workDays: working ? {...workDays} : <int>{},
          workStartMinutes: working ? workStart : null,
          workEndMinutes: working ? workEnd : null,
          mentalLoad: mentalLoad,
          dailyActivity: dailyActivity,
          lifestyle: legacyLifestyle,
        );
      case ProfileSection.training:
        return base.copyWith(
          experienceLevel: experienceLevel,
          trainingDaysPerWeek: trainingDays,
          sessionMinutes: sessionMinutes,
          trainingLocations: {...trainingLocations},
          equipmentItems: {...equipmentItems},
          otherSports: {...otherSports},
          trainingExperience: legacyTrainingExperience,
          equipment: legacyEquipment,
        );
      case ProfileSection.nutrition:
        return base.copyWith(
          dietType: dietType,
          allergies: {...allergies},
          allergyOther:
              allergies.contains(Allergy.other) ? text(allergyOther) : null,
          dislikedFoods: text(dislikedFoods),
          mealsPerDay: mealsPerDay,
          cookingTime: cookingTime,
          mealPrep: mealPrep,
          weeklyFoodBudget: parseWholeNumber(budget.text),
          dietaryNotes: legacyDietaryNotes,
          cookingHabits: legacyCookingHabits,
          foodBudget: legacyFoodBudget,
        );
      case ProfileSection.schedule:
        return base.copyWith(
          wakeMinutes: wake,
          sleepMinutes: sleep,
          weekendDifferent: weekendDifferent,
          weekendWakeMinutes: weekendDifferent ? weekendWake : null,
          weekendSleepMinutes: weekendDifferent ? weekendSleep : null,
          trainingTimes: {...trainingTimes},
          dailySchedule: legacyDailySchedule,
        );
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
      !applyTo(base, section).sameAs(base);
}
