import 'package:flutter/material.dart';

import '../../../core/utils/hu_dates.dart';
import '../../../core/utils/number_input.dart';
import '../domain/user_profile.dart';

/// A profil szakaszai: cím, ikon, rövid leírás, és hogy a kártyán
/// mi jelenjen meg belőlük. A sorrend itt dönti el a kártyák és a
/// vezetett kitöltés lépéseinek sorrendjét is.
enum ProfileSection {
  basics(
    title: 'Alapadatok',
    icon: Icons.person_outline,
    description:
        'Ezekből becsüli az AI például az energiaigényedet és a regenerációs időt.',
  ),
  goal(
    title: 'Cél',
    icon: Icons.flag_outlined,
    description:
        'Mit szeretnél elérni, és meddig? A célt bármikor lecserélheted.',
  ),
  lifestyle(
    title: 'Életmód és munka',
    icon: Icons.work_outline,
    description:
        'Mi terhel fizikailag és mentálisan? Így az AI reálisan tud tervezni.',
  ),
  training(
    title: 'Edzési háttér',
    icon: Icons.fitness_center,
    description: 'Honnan indulsz, mennyi időd van, és mivel tudsz edzeni.',
  ),
  nutrition(
    title: 'Étkezés',
    icon: Icons.restaurant_outlined,
    description:
        'Mit eszel és mit nem, mennyi időd van főzni, és mennyit szánsz rá.',
  ),
  schedule(
    title: 'Napirend',
    icon: Icons.schedule,
    description:
        'Mikor kelsz, mikor fekszel, és mikor tudsz edzeni egy szokásos napon.',
  ),
  macros(
    title: 'Napi makrócélok',
    icon: Icons.pie_chart_outline,
    description: 'A Yazióban beállított napi céljaid, kézzel átmásolva. '
        'Ha ott módosítod őket, itt is írd át. Az AI ezekkel számol, '
        'és legfeljebb javasolhat változtatást.',
  );

  const ProfileSection({
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;

  /// Ki van-e töltve a szakaszból legalább egy mező.
  bool isFilledIn(UserProfile profile) => summaryOf(profile).isNotEmpty;

  /// A kártyán megjelenő sorok. Az első a fő sor, a többi kiegészítő.
  /// Üres lista, ha a szakasz nincs kitöltve. Ha a választható mezők még
  /// üresek, a korábban beírt szabad szöveg jelenik meg.
  List<String> summaryOf(UserProfile p) {
    final lines = _nonEmpty(_structuredSummary(p));
    if (lines.isNotEmpty) return lines;
    return _nonEmpty(legacyTextsOf(p));
  }

  /// A szakasz korábbi, szabad szöveges mezőinek tartalma.
  List<String?> legacyTextsOf(UserProfile p) => switch (this) {
        ProfileSection.goal => [p.goal],
        ProfileSection.lifestyle => [p.lifestyle],
        ProfileSection.training => [p.trainingExperience, p.equipment],
        ProfileSection.nutrition => [
            p.dietaryNotes,
            p.cookingHabits,
            p.foodBudget,
          ],
        ProfileSection.schedule => [p.dailySchedule],
        ProfileSection.basics || ProfileSection.macros =>
          const [],
      };

  List<String?> _structuredSummary(UserProfile p) {
    switch (this) {
      case ProfileSection.basics:
        return [
          _join([
            p.birthYear?.toString(),
            p.sex?.label,
            p.heightCm == null ? null : '${formatDecimal(p.heightCm)} cm',
          ]),
        ];
      case ProfileSection.goal:
        final sport = p.goalSport == null
            ? null
            : p.goalSport == Sport.other
                ? (p.goalSportOther ?? 'egyéb sport')
                : p.goalSport!.label.toLowerCase();
        return [
          _join(
            [
              for (final type in GoalType.values)
                if (p.goalTypes.contains(type))
                  type == GoalType.sport && sport != null
                      ? 'felkészülés: $sport'
                      : type.label,
            ],
            ', ',
          ),
          p.goalDeadline == null ? null : deadlineText(p.goalDeadline!),
        ];
      case ProfileSection.lifestyle:
        final working = p.workType != WorkType.notWorking;
        final start = p.workStartMinutes;
        final end = p.workEndMinutes;
        return [
          _join([p.workType?.label, if (working) p.workSchedule?.label]),
          if (working)
            _join(
              [
                huWeekdaySet(p.workDays),
                start == null || end == null
                    ? null
                    : '${huClock(start)}–${huClock(end)}',
              ],
              ', ',
            ),
          _join([
            p.mentalLoad == null
                ? null
                : 'mentális terhelés: ${p.mentalLoad!.label.toLowerCase()}',
            p.dailyActivity == null
                ? null
                : 'mozgás: ${p.dailyActivity!.label.toLowerCase()}',
          ]),
        ];
      case ProfileSection.training:
        return [
          _join([
            p.experienceLevel?.label,
            p.trainingDaysPerWeek == null
                ? null
                : 'heti ${p.trainingDaysPerWeek} nap',
            p.sessionMinutes == null ? null : sessionLabel(p.sessionMinutes!),
          ]),
          _join([
            _labels(TrainingLocation.values, p.trainingLocations, (v) => v.label),
            _labels(Equipment.values, p.equipmentItems, (v) => v.label),
          ]),
          p.otherSports.isEmpty
              ? null
              : 'Más sport: ${_labels(Sport.values, p.otherSports, (v) => v.label.toLowerCase())}',
        ];
      case ProfileSection.nutrition:
        final allergyNames = [
          for (final allergy in Allergy.values)
            if (p.allergies.contains(allergy))
              allergy == Allergy.other
                  ? (p.allergyOther ?? 'egyéb')
                  : allergy.label.toLowerCase(),
        ];
        return [
          _join([
            p.dietType?.label,
            p.mealsPerDay == null ? null : 'napi ${p.mealsPerDay} étkezés',
          ]),
          allergyNames.isEmpty ? null : 'Allergia: ${allergyNames.join(', ')}',
          p.dislikedFoods == null ? null : 'Nem eszem: ${p.dislikedFoods}',
          _join([
            p.cookingTime == null ? null : 'főzés: ${p.cookingTime!.label}',
            p.mealPrep == null
                ? null
                : 'előre főzés: ${p.mealPrep!.label.toLowerCase()}',
            p.weeklyFoodBudget == null
                ? null
                : 'heti ${formatThousands(p.weeklyFoodBudget!)} Ft',
          ]),
        ];
      case ProfileSection.schedule:
        return [
          _sleepLine(p.wakeMinutes, p.sleepMinutes, ''),
          if (p.weekendDifferent)
            _sleepLine(p.weekendWakeMinutes, p.weekendSleepMinutes, 'Hétvégén: '),
          p.trainingTimes.isEmpty
              ? null
              : 'Edzésidő: ${_labels(DayPart.values, p.trainingTimes, (v) => v.label.toLowerCase())}',
        ];
      case ProfileSection.macros:
        return [
          p.calorieTarget == null ? null : '${p.calorieTarget} kcal',
          p.proteinTargetG == null ? null : '${p.proteinTargetG} g fehérje',
          p.carbTargetG == null ? null : '${p.carbTargetG} g szénhidrát',
          p.fatTargetG == null ? null : '${p.fatTargetG} g zsír',
        ];
    }
  }

  static String? _sleepLine(int? wake, int? sleep, String prefix) {
    final text = _join([
      wake == null ? null : 'kelés ${huClock(wake)}',
      sleep == null ? null : 'lefekvés ${huClock(sleep)}',
    ]);
    return text == null ? null : '$prefix$text';
  }

  /// A kiválasztott értékek feliratai, a lista sorrendjében.
  static String? _labels<T>(
    List<T> all,
    Set<T> selected,
    String Function(T) label,
  ) {
    final names = [
      for (final value in all)
        if (selected.contains(value)) label(value),
    ];
    return names.isEmpty ? null : names.join(', ');
  }

  /// A nem üres részek összefűzve; null, ha mind üres.
  static String? _join(List<String?> parts, [String separator = ' · ']) {
    final kept = _nonEmpty(parts);
    return kept.isEmpty ? null : kept.join(separator);
  }

  static List<String> _nonEmpty(List<String?> items) => [
        for (final item in items)
          if (item != null && item.trim().isNotEmpty) item.trim(),
      ];
}

/// Egy edzés hossza szövegként; a 90 jelentése „90 vagy több”.
String sessionLabel(int minutes) =>
    minutes >= 90 ? '90+ perc' : '$minutes perc';

/// Pl. "Határidő: 2027. február 28. · még 17 hét"
String deadlineText(DateTime deadline, {DateTime? now}) {
  final current = now ?? DateTime.now();
  // UTC-ben számolunk, hogy az óraátállítás ne zavarja a napok számát.
  final today = DateTime.utc(current.year, current.month, current.day);
  final day = DateTime.utc(deadline.year, deadline.month, deadline.day);
  final days = day.difference(today).inDays;

  final String remaining;
  if (days < 0) {
    remaining = 'lejárt';
  } else if (days == 0) {
    remaining = 'ma';
  } else if (days < 14) {
    remaining = 'még $days nap';
  } else {
    remaining = 'még ${days ~/ 7} hét';
  }
  return 'Határidő: ${huFullDate(deadline)} · $remaining';
}

extension SexLabel on Sex {
  String get label => switch (this) {
        Sex.male => 'férfi',
        Sex.female => 'nő',
      };
}

extension ResponseStyleText on ResponseStyle {
  String get label => switch (this) {
        ResponseStyle.concise => 'Tömör',
        ResponseStyle.detailed => 'Részletes',
      };

  String get help => switch (this) {
        ResponseStyle.concise =>
          'Rövid, lényegre törő válaszok. Ha kell, rákérdezhetsz a részletekre.',
        ResponseStyle.detailed =>
          'Bővebb magyarázat: miért javasolja, amit javasol, és mire figyelj.',
      };
}
