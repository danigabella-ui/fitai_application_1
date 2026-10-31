import '../../../core/utils/map_utils.dart';

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
    this.goal,
    this.goalDeadline,
    this.lifestyle,
    this.trainingExperience,
    this.trainingDaysPerWeek,
    this.equipment,
    this.dietaryNotes,
    this.injuries,
    this.cookingHabits,
    this.foodBudget,
    this.dailySchedule,
    this.calorieTarget,
    this.proteinTargetG,
    this.carbTargetG,
    this.fatTargetG,
    this.responseStyle = ResponseStyle.concise,
  });

  /// Üres profil az első indításhoz.
  static const UserProfile empty = UserProfile();

  // Alapadatok
  final int? birthYear;
  final Sex? sex;
  final double? heightCm;

  // Cél
  final String? goal;
  final DateTime? goalDeadline;

  // Életmód és munka (fizikai és mentális terhelés)
  final String? lifestyle;

  // Edzési háttér
  final String? trainingExperience;
  final int? trainingDaysPerWeek;
  final String? equipment;

  // Étkezés
  final String? dietaryNotes;
  final String? injuries;
  final String? cookingHabits;
  final String? foodBudget;

  // Napirend (mikor tud edzeni, mikor kel és fekszik)
  final String? dailySchedule;

  // Makrócélok a Yazio alapján (a felhasználó adja meg)
  final int? calorieTarget;
  final int? proteinTargetG;
  final int? carbTargetG;
  final int? fatTargetG;

  final ResponseStyle responseStyle;

  /// Jelölő érték a [copyWith]-hez: "ezt a mezőt hagyd változatlanul".
  /// Erre azért van szükség, hogy egy mezőt null-ra (üresre) is
  /// lehessen állítani, ne csak új értékre.
  static const Object _keep = Object();

  /// Másolat a profilról, a megadott mezőkkel módosítva.
  /// A meg nem adott mezők változatlanok maradnak; a null érték törli a mezőt.
  UserProfile copyWith({
    Object? birthYear = _keep,
    Object? sex = _keep,
    Object? heightCm = _keep,
    Object? goal = _keep,
    Object? goalDeadline = _keep,
    Object? lifestyle = _keep,
    Object? trainingExperience = _keep,
    Object? trainingDaysPerWeek = _keep,
    Object? equipment = _keep,
    Object? dietaryNotes = _keep,
    Object? injuries = _keep,
    Object? cookingHabits = _keep,
    Object? foodBudget = _keep,
    Object? dailySchedule = _keep,
    Object? calorieTarget = _keep,
    Object? proteinTargetG = _keep,
    Object? carbTargetG = _keep,
    Object? fatTargetG = _keep,
    ResponseStyle? responseStyle,
  }) {
    T? pick<T>(Object? value, T? current) =>
        identical(value, _keep) ? current : value as T?;

    return UserProfile(
      birthYear: pick<int>(birthYear, this.birthYear),
      sex: pick<Sex>(sex, this.sex),
      heightCm: pick<double>(heightCm, this.heightCm),
      goal: pick<String>(goal, this.goal),
      goalDeadline: pick<DateTime>(goalDeadline, this.goalDeadline),
      lifestyle: pick<String>(lifestyle, this.lifestyle),
      trainingExperience:
          pick<String>(trainingExperience, this.trainingExperience),
      trainingDaysPerWeek:
          pick<int>(trainingDaysPerWeek, this.trainingDaysPerWeek),
      equipment: pick<String>(equipment, this.equipment),
      dietaryNotes: pick<String>(dietaryNotes, this.dietaryNotes),
      injuries: pick<String>(injuries, this.injuries),
      cookingHabits: pick<String>(cookingHabits, this.cookingHabits),
      foodBudget: pick<String>(foodBudget, this.foodBudget),
      dailySchedule: pick<String>(dailySchedule, this.dailySchedule),
      calorieTarget: pick<int>(calorieTarget, this.calorieTarget),
      proteinTargetG: pick<int>(proteinTargetG, this.proteinTargetG),
      carbTargetG: pick<int>(carbTargetG, this.carbTargetG),
      fatTargetG: pick<int>(fatTargetG, this.fatTargetG),
      responseStyle: responseStyle ?? this.responseStyle,
    );
  }

  Map<String, Object?> toMap() => {
        'birthYear': birthYear,
        'sex': sex?.name,
        'heightCm': heightCm,
        'goal': goal,
        'goalDeadline': goalDeadline?.toIso8601String(),
        'lifestyle': lifestyle,
        'trainingExperience': trainingExperience,
        'trainingDaysPerWeek': trainingDaysPerWeek,
        'equipment': equipment,
        'dietaryNotes': dietaryNotes,
        'injuries': injuries,
        'cookingHabits': cookingHabits,
        'foodBudget': foodBudget,
        'dailySchedule': dailySchedule,
        'calorieTarget': calorieTarget,
        'proteinTargetG': proteinTargetG,
        'carbTargetG': carbTargetG,
        'fatTargetG': fatTargetG,
        'responseStyle': responseStyle.name,
      };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        birthYear: readInt(map['birthYear']),
        sex: enumByName(Sex.values, map['sex']),
        heightCm: readDouble(map['heightCm']),
        goal: readString(map['goal']),
        goalDeadline: readDate(map['goalDeadline']),
        lifestyle: readString(map['lifestyle']),
        trainingExperience: readString(map['trainingExperience']),
        trainingDaysPerWeek: readInt(map['trainingDaysPerWeek']),
        equipment: readString(map['equipment']),
        dietaryNotes: readString(map['dietaryNotes']),
        injuries: readString(map['injuries']),
        cookingHabits: readString(map['cookingHabits']),
        foodBudget: readString(map['foodBudget']),
        dailySchedule: readString(map['dailySchedule']),
        calorieTarget: readInt(map['calorieTarget']),
        proteinTargetG: readInt(map['proteinTargetG']),
        carbTargetG: readInt(map['carbTargetG']),
        fatTargetG: readInt(map['fatTargetG']),
        responseStyle: enumByName(ResponseStyle.values, map['responseStyle']) ??
            ResponseStyle.concise,
      );
}
