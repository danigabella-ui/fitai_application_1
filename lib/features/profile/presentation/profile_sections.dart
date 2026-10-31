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
  injuries(
    title: 'Sérülések, korlátozások',
    icon: Icons.healing_outlined,
    description:
        'Az AI kerüli azokat a gyakorlatokat, amelyek ezeket terhelnék.',
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
  /// Üres lista, ha a szakasz nincs kitöltve.
  List<String> summaryOf(UserProfile p) {
    switch (this) {
      case ProfileSection.basics:
        final parts = _nonEmpty([
          p.birthYear?.toString(),
          p.sex?.label,
          p.heightCm == null ? null : '${formatDecimal(p.heightCm)} cm',
        ]);
        return parts.isEmpty ? const [] : [parts.join(' · ')];
      case ProfileSection.goal:
        return _nonEmpty([
          p.goal,
          p.goalDeadline == null ? null : deadlineText(p.goalDeadline!),
        ]);
      case ProfileSection.lifestyle:
        return _nonEmpty([p.lifestyle]);
      case ProfileSection.training:
        return _nonEmpty([
          p.trainingDaysPerWeek == null
              ? null
              : 'Heti ${p.trainingDaysPerWeek} nap',
          p.trainingExperience,
          p.equipment,
        ]);
      case ProfileSection.nutrition:
        return _nonEmpty([
          p.dietaryNotes,
          p.cookingHabits,
          p.foodBudget == null ? null : 'Heti keret: ${p.foodBudget}',
        ]);
      case ProfileSection.injuries:
        return _nonEmpty([p.injuries]);
      case ProfileSection.schedule:
        return _nonEmpty([p.dailySchedule]);
      case ProfileSection.macros:
        return _nonEmpty([
          p.calorieTarget == null ? null : '${p.calorieTarget} kcal',
          p.proteinTargetG == null ? null : '${p.proteinTargetG} g fehérje',
          p.carbTargetG == null ? null : '${p.carbTargetG} g szénhidrát',
          p.fatTargetG == null ? null : '${p.fatTargetG} g zsír',
        ]);
    }
  }

  static List<String> _nonEmpty(List<String?> items) => [
        for (final item in items)
          if (item != null && item.trim().isNotEmpty) item.trim(),
      ];
}

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
