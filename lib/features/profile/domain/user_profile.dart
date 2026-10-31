import 'dart:convert';

import '../../../core/utils/map_utils.dart';
import 'profile_options.dart';

export 'profile_options.dart';

enum Sex { male, female }

/// Milyen terjedelemben válaszoljon az AI.
enum ResponseStyle { concise, detailed }

/// A felhasználó személyre szabható profilja.
/// Minden mező opcionális: az AI azzal dolgozik, ami ki van töltve.
class UserProfile {
  const UserProfile({
    this.birthYear,
    this.sex,
    this.heightCm,
    this.goalTypes = const <GoalType>{},
    this.goalSport,
    this.goalSportOther,
    this.goalDeadline,
    this.workType,
    this.workSchedule,
    this.workDays = const <int>{},
    this.workStartMinutes,
    this.workEndMinutes,
    this.mentalLoad,
    this.dailyActivity,
    this.experienceLevel,
    this.trainingDaysPerWeek,
    this.sessionMinutes,
    this.trainingLocations = const <TrainingLocation>{},
    this.equipmentItems = const <Equipment>{},
    this.otherSports = const <Sport>{},
    this.dietType,
    this.allergies = const <Allergy>{},
    this.allergyOther,
    this.dislikedFoods,
    this.mealsPerDay,
    this.cookingTime,
    this.mealPrep,
    this.weeklyFoodBudget,
    this.injuryAreas = const <BodyArea>{},
    this.injuries,
    this.wakeMinutes,
    this.sleepMinutes,
    this.weekendDifferent = false,
    this.weekendWakeMinutes,
    this.weekendSleepMinutes,
    this.trainingTimes = const <DayPart>{},
    this.calorieTarget,
    this.proteinTargetG,
    this.carbTargetG,
    this.fatTargetG,
    this.goal,
    this.lifestyle,
    this.trainingExperience,
    this.equipment,
    this.dietaryNotes,
    this.cookingHabits,
    this.foodBudget,
    this.dailySchedule,
    this.responseStyle = ResponseStyle.concise,
  });

  /// Üres profil az első indításhoz.
  static const UserProfile empty = UserProfile();

  // Alapadatok
  final int? birthYear;
  final Sex? sex;
  final double? heightCm;

  // Cél
  final Set<GoalType> goalTypes;
  final Sport? goalSport;
  final String? goalSportOther;
  final DateTime? goalDeadline;

  // Életmód és munka (a munkaidő és az időpontok percben, éjféltől számolva)
  final WorkType? workType;
  final WorkSchedule? workSchedule;
  final Set<int> workDays;
  final int? workStartMinutes;
  final int? workEndMinutes;
  final LoadLevel? mentalLoad;
  final ActivityLevel? dailyActivity;

  // Edzési háttér
  final ExperienceLevel? experienceLevel;
  final int? trainingDaysPerWeek;
  final int? sessionMinutes;
  final Set<TrainingLocation> trainingLocations;
  final Set<Equipment> equipmentItems;
  final Set<Sport> otherSports;

  // Étkezés
  final DietType? dietType;
  final Set<Allergy> allergies;
  final String? allergyOther;
  final String? dislikedFoods;
  final int? mealsPerDay;
  final CookingTime? cookingTime;
  final MealPrep? mealPrep;
  final int? weeklyFoodBudget;

  // Sérülések (korábbi mezők: a sérülésnapló váltotta fel őket, az új
  // felületen csak megjeleníthetők és törölhetők)
  final Set<BodyArea> injuryAreas;
  final String? injuries;

  // Napirend
  final int? wakeMinutes;
  final int? sleepMinutes;
  final bool weekendDifferent;
  final int? weekendWakeMinutes;
  final int? weekendSleepMinutes;
  final Set<DayPart> trainingTimes;

  // Makrócélok a Yazio alapján (a felhasználó adja meg)
  final int? calorieTarget;
  final int? proteinTargetG;
  final int? carbTargetG;
  final int? fatTargetG;

  // Korábbi szabad szöveges mezők. Az új felületen már nem írhatók, csak
  // megjeleníthetők és törölhetők, hogy a korábban beírt szöveg ne vesszen el.
  final String? goal;
  final String? lifestyle;
  final String? trainingExperience;
  final String? equipment;
  final String? dietaryNotes;
  final String? cookingHabits;
  final String? foodBudget;
  final String? dailySchedule;

  // Válaszstílus
  final ResponseStyle responseStyle;

  /// Jelölő érték a [copyWith]-hez: "ezt a mezőt hagyd változatlanul".
  /// Erre azért van szükség, hogy egy mezőt null-ra (üresre) is
  /// lehessen állítani, ne csak új értékre.
  static const Object _keep = Object();

  /// Másolat a profilról, a megadott mezőkkel módosítva.
  /// A meg nem adott mezők változatlanok maradnak; a null érték törli a
  /// mezőt (a halmazoknál és a kapcsolóknál a null változatlant jelent).
  UserProfile copyWith({
    Object? birthYear = _keep,
    Object? sex = _keep,
    Object? heightCm = _keep,
    Set<GoalType>? goalTypes,
    Object? goalSport = _keep,
    Object? goalSportOther = _keep,
    Object? goalDeadline = _keep,
    Object? workType = _keep,
    Object? workSchedule = _keep,
    Set<int>? workDays,
    Object? workStartMinutes = _keep,
    Object? workEndMinutes = _keep,
    Object? mentalLoad = _keep,
    Object? dailyActivity = _keep,
    Object? experienceLevel = _keep,
    Object? trainingDaysPerWeek = _keep,
    Object? sessionMinutes = _keep,
    Set<TrainingLocation>? trainingLocations,
    Set<Equipment>? equipmentItems,
    Set<Sport>? otherSports,
    Object? dietType = _keep,
    Set<Allergy>? allergies,
    Object? allergyOther = _keep,
    Object? dislikedFoods = _keep,
    Object? mealsPerDay = _keep,
    Object? cookingTime = _keep,
    Object? mealPrep = _keep,
    Object? weeklyFoodBudget = _keep,
    Set<BodyArea>? injuryAreas,
    Object? injuries = _keep,
    Object? wakeMinutes = _keep,
    Object? sleepMinutes = _keep,
    bool? weekendDifferent,
    Object? weekendWakeMinutes = _keep,
    Object? weekendSleepMinutes = _keep,
    Set<DayPart>? trainingTimes,
    Object? calorieTarget = _keep,
    Object? proteinTargetG = _keep,
    Object? carbTargetG = _keep,
    Object? fatTargetG = _keep,
    Object? goal = _keep,
    Object? lifestyle = _keep,
    Object? trainingExperience = _keep,
    Object? equipment = _keep,
    Object? dietaryNotes = _keep,
    Object? cookingHabits = _keep,
    Object? foodBudget = _keep,
    Object? dailySchedule = _keep,
    ResponseStyle? responseStyle,
  }) {
    T? pick<T>(Object? value, T? current) =>
        identical(value, _keep) ? current : value as T?;

    return UserProfile(
      birthYear: pick<int>(birthYear, this.birthYear),
      sex: pick<Sex>(sex, this.sex),
      heightCm: pick<double>(heightCm, this.heightCm),
      goalTypes: goalTypes ?? this.goalTypes,
      goalSport: pick<Sport>(goalSport, this.goalSport),
      goalSportOther: pick<String>(goalSportOther, this.goalSportOther),
      goalDeadline: pick<DateTime>(goalDeadline, this.goalDeadline),
      workType: pick<WorkType>(workType, this.workType),
      workSchedule: pick<WorkSchedule>(workSchedule, this.workSchedule),
      workDays: workDays ?? this.workDays,
      workStartMinutes: pick<int>(workStartMinutes, this.workStartMinutes),
      workEndMinutes: pick<int>(workEndMinutes, this.workEndMinutes),
      mentalLoad: pick<LoadLevel>(mentalLoad, this.mentalLoad),
      dailyActivity: pick<ActivityLevel>(dailyActivity, this.dailyActivity),
      experienceLevel: pick<ExperienceLevel>(experienceLevel, this.experienceLevel),
      trainingDaysPerWeek: pick<int>(trainingDaysPerWeek, this.trainingDaysPerWeek),
      sessionMinutes: pick<int>(sessionMinutes, this.sessionMinutes),
      trainingLocations: trainingLocations ?? this.trainingLocations,
      equipmentItems: equipmentItems ?? this.equipmentItems,
      otherSports: otherSports ?? this.otherSports,
      dietType: pick<DietType>(dietType, this.dietType),
      allergies: allergies ?? this.allergies,
      allergyOther: pick<String>(allergyOther, this.allergyOther),
      dislikedFoods: pick<String>(dislikedFoods, this.dislikedFoods),
      mealsPerDay: pick<int>(mealsPerDay, this.mealsPerDay),
      cookingTime: pick<CookingTime>(cookingTime, this.cookingTime),
      mealPrep: pick<MealPrep>(mealPrep, this.mealPrep),
      weeklyFoodBudget: pick<int>(weeklyFoodBudget, this.weeklyFoodBudget),
      injuryAreas: injuryAreas ?? this.injuryAreas,
      injuries: pick<String>(injuries, this.injuries),
      wakeMinutes: pick<int>(wakeMinutes, this.wakeMinutes),
      sleepMinutes: pick<int>(sleepMinutes, this.sleepMinutes),
      weekendDifferent: weekendDifferent ?? this.weekendDifferent,
      weekendWakeMinutes: pick<int>(weekendWakeMinutes, this.weekendWakeMinutes),
      weekendSleepMinutes: pick<int>(weekendSleepMinutes, this.weekendSleepMinutes),
      trainingTimes: trainingTimes ?? this.trainingTimes,
      calorieTarget: pick<int>(calorieTarget, this.calorieTarget),
      proteinTargetG: pick<int>(proteinTargetG, this.proteinTargetG),
      carbTargetG: pick<int>(carbTargetG, this.carbTargetG),
      fatTargetG: pick<int>(fatTargetG, this.fatTargetG),
      goal: pick<String>(goal, this.goal),
      lifestyle: pick<String>(lifestyle, this.lifestyle),
      trainingExperience: pick<String>(trainingExperience, this.trainingExperience),
      equipment: pick<String>(equipment, this.equipment),
      dietaryNotes: pick<String>(dietaryNotes, this.dietaryNotes),
      cookingHabits: pick<String>(cookingHabits, this.cookingHabits),
      foodBudget: pick<String>(foodBudget, this.foodBudget),
      dailySchedule: pick<String>(dailySchedule, this.dailySchedule),
      responseStyle: responseStyle ?? this.responseStyle,
    );
  }

  /// Igaz, ha a két profil minden adata egyezik.
  bool sameAs(UserProfile other) =>
      jsonEncode(toMap()) == jsonEncode(other.toMap());

  Map<String, Object?> toMap() => {
        'birthYear': birthYear,
        'sex': sex?.name,
        'heightCm': heightCm,
        'goalTypes': enumSetToList(goalTypes),
        'goalSport': goalSport?.name,
        'goalSportOther': goalSportOther,
        'goalDeadline': goalDeadline?.toIso8601String(),
        'workType': workType?.name,
        'workSchedule': workSchedule?.name,
        'workDays': intSetToList(workDays),
        'workStartMinutes': workStartMinutes,
        'workEndMinutes': workEndMinutes,
        'mentalLoad': mentalLoad?.name,
        'dailyActivity': dailyActivity?.name,
        'experienceLevel': experienceLevel?.name,
        'trainingDaysPerWeek': trainingDaysPerWeek,
        'sessionMinutes': sessionMinutes,
        'trainingLocations': enumSetToList(trainingLocations),
        'equipmentItems': enumSetToList(equipmentItems),
        'otherSports': enumSetToList(otherSports),
        'dietType': dietType?.name,
        'allergies': enumSetToList(allergies),
        'allergyOther': allergyOther,
        'dislikedFoods': dislikedFoods,
        'mealsPerDay': mealsPerDay,
        'cookingTime': cookingTime?.name,
        'mealPrep': mealPrep?.name,
        'weeklyFoodBudget': weeklyFoodBudget,
        'injuryAreas': enumSetToList(injuryAreas),
        'injuries': injuries,
        'wakeMinutes': wakeMinutes,
        'sleepMinutes': sleepMinutes,
        'weekendDifferent': weekendDifferent,
        'weekendWakeMinutes': weekendWakeMinutes,
        'weekendSleepMinutes': weekendSleepMinutes,
        'trainingTimes': enumSetToList(trainingTimes),
        'calorieTarget': calorieTarget,
        'proteinTargetG': proteinTargetG,
        'carbTargetG': carbTargetG,
        'fatTargetG': fatTargetG,
        'goal': goal,
        'lifestyle': lifestyle,
        'trainingExperience': trainingExperience,
        'equipment': equipment,
        'dietaryNotes': dietaryNotes,
        'cookingHabits': cookingHabits,
        'foodBudget': foodBudget,
        'dailySchedule': dailySchedule,
        'responseStyle': responseStyle.name,
      };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        birthYear: readInt(map['birthYear']),
        sex: enumByName(Sex.values, map['sex']),
        heightCm: readDouble(map['heightCm']),
        goalTypes: readEnumSet(GoalType.values, map['goalTypes']),
        goalSport: enumByName(Sport.values, map['goalSport']),
        goalSportOther: readString(map['goalSportOther']),
        goalDeadline: readDate(map['goalDeadline']),
        workType: enumByName(WorkType.values, map['workType']),
        workSchedule: enumByName(WorkSchedule.values, map['workSchedule']),
        workDays: readIntSet(map['workDays']),
        workStartMinutes: readInt(map['workStartMinutes']),
        workEndMinutes: readInt(map['workEndMinutes']),
        mentalLoad: enumByName(LoadLevel.values, map['mentalLoad']),
        dailyActivity: enumByName(ActivityLevel.values, map['dailyActivity']),
        experienceLevel: enumByName(ExperienceLevel.values, map['experienceLevel']),
        trainingDaysPerWeek: readInt(map['trainingDaysPerWeek']),
        sessionMinutes: readInt(map['sessionMinutes']),
        trainingLocations: readEnumSet(TrainingLocation.values, map['trainingLocations']),
        equipmentItems: readEnumSet(Equipment.values, map['equipmentItems']),
        otherSports: readEnumSet(Sport.values, map['otherSports']),
        dietType: enumByName(DietType.values, map['dietType']),
        allergies: readEnumSet(Allergy.values, map['allergies']),
        allergyOther: readString(map['allergyOther']),
        dislikedFoods: readString(map['dislikedFoods']),
        mealsPerDay: readInt(map['mealsPerDay']),
        cookingTime: enumByName(CookingTime.values, map['cookingTime']),
        mealPrep: enumByName(MealPrep.values, map['mealPrep']),
        weeklyFoodBudget: readInt(map['weeklyFoodBudget']),
        injuryAreas: readEnumSet(BodyArea.values, map['injuryAreas']),
        injuries: readString(map['injuries']),
        wakeMinutes: readInt(map['wakeMinutes']),
        sleepMinutes: readInt(map['sleepMinutes']),
        weekendDifferent: readBool(map['weekendDifferent']),
        weekendWakeMinutes: readInt(map['weekendWakeMinutes']),
        weekendSleepMinutes: readInt(map['weekendSleepMinutes']),
        trainingTimes: readEnumSet(DayPart.values, map['trainingTimes']),
        calorieTarget: readInt(map['calorieTarget']),
        proteinTargetG: readInt(map['proteinTargetG']),
        carbTargetG: readInt(map['carbTargetG']),
        fatTargetG: readInt(map['fatTargetG']),
        goal: readString(map['goal']),
        lifestyle: readString(map['lifestyle']),
        trainingExperience: readString(map['trainingExperience']),
        equipment: readString(map['equipment']),
        dietaryNotes: readString(map['dietaryNotes']),
        cookingHabits: readString(map['cookingHabits']),
        foodBudget: readString(map['foodBudget']),
        dailySchedule: readString(map['dailySchedule']),
        responseStyle: enumByName(ResponseStyle.values, map['responseStyle']) ??
            ResponseStyle.concise,
      );
}
