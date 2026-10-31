/// A profil választható értékei, magyar feliratokkal.
///
/// Az AI ezeket a feliratokat kapja meg, ezért egyértelműek és rövidek.
/// FONTOS: az értékek neve (pl. `fatLoss`) az adatbázisban és a
/// mentésekben is így szerepel, ezért utólag nem szabad átnevezni őket.
/// A felirat bármikor változhat.
library;

enum GoalType {
  fatLoss('Fogyás, szálkásítás'),
  muscleGain('Izomépítés'),
  strength('Erőnövelés'),
  endurance('Állóképesség'),
  sport('Felkészülés egy sportra'),
  health('Egészség, közérzet');

  const GoalType(this.label);
  final String label;
}

enum Sport {
  football('Labdarúgás'),
  running('Futás'),
  basketball('Kosárlabda'),
  handball('Kézilabda'),
  volleyball('Röplabda'),
  tennis('Tenisz'),
  swimming('Úszás'),
  cycling('Kerékpár'),
  combat('Küzdősport'),
  other('Egyéb');

  const Sport(this.label);
  final String label;
}

enum WorkType {
  sedentary('Ülőmunka (irodai)'),
  mixed('Vegyes (ülő és mozgó)'),
  standing('Állómunka'),
  physical('Fizikai munka'),
  heavyPhysical('Nehéz fizikai munka'),
  notWorking('Nem dolgozom');

  const WorkType(this.label);
  final String label;
}

enum WorkSchedule {
  fixedDay('Fix nappali'),
  shifts('Műszakos'),
  flexible('Rugalmas');

  const WorkSchedule(this.label);
  final String label;
}

/// Mentális terhelés.
enum LoadLevel {
  low('Alacsony'),
  medium('Közepes'),
  high('Magas');

  const LoadLevel(this.label);
  final String label;
}

/// Mozgás a munkán és az edzéseken kívül (gyaloglás, biciklizés stb.).
enum ActivityLevel {
  low('Kevés'),
  medium('Közepes'),
  high('Sok');

  const ActivityLevel(this.label);
  final String label;
}

enum ExperienceLevel {
  beginner('Kezdő', '1 év alatt'),
  intermediate('Középhaladó', '1–3 év'),
  advanced('Haladó', '3 év felett');

  const ExperienceLevel(this.label, this.detail);
  final String label;
  final String detail;
}

enum TrainingLocation {
  gym('Edzőterem'),
  home('Otthon'),
  outdoor('Szabadban');

  const TrainingLocation(this.label);
  final String label;
}

enum Equipment {
  machines('Gépek'),
  freeWeights('Szabadsúlyok'),
  kettlebell('Kettlebell'),
  bands('Gumiszalag'),
  pullUpBar('Húzódzkodó rúd'),
  cardio('Kardiógépek');

  const Equipment(this.label);
  final String label;
}

enum DietType {
  omnivore('Mindenevő'),
  vegetarian('Vegetáriánus'),
  vegan('Vegán'),
  pescatarian('Pescovegetáriánus');

  const DietType(this.label);
  final String label;
}

enum Allergy {
  lactose('Laktóz'),
  gluten('Glutén'),
  nuts('Diófélék'),
  peanut('Földimogyoró'),
  egg('Tojás'),
  fish('Hal'),
  shellfish('Rákfélék'),
  soy('Szója'),
  other('Egyéb');

  const Allergy(this.label);
  final String label;
}

enum CookingTime {
  under15('15 perc alatt'),
  from15to30('15–30 perc'),
  from30to60('30–60 perc'),
  over60('60 perc felett');

  const CookingTime(this.label);
  final String label;
}

enum MealPrep {
  never('Nem'),
  sometimes('Néha'),
  regularly('Rendszeresen');

  const MealPrep(this.label);
  final String label;
}

/// Testrészek. A sérülésnapló és a Check-In fájdalomjelzése is ezt használja.
enum BodyArea {
  neck('Nyak'),
  shoulder('Váll'),
  elbow('Könyök'),
  wrist('Csukló'),
  lowerBack('Derék, hát'),
  hip('Csípő'),
  knee('Térd'),
  ankle('Boka');

  const BodyArea(this.label);
  final String label;
}

/// Napszakok, amikor edzeni lehet.
enum DayPart {
  morning('Reggel'),
  forenoon('Délelőtt'),
  afternoon('Délután'),
  evening('Este');

  const DayPart(this.label);
  final String label;
}

/// Egy edzés választható hossza percben (a 90 jelentése: 90 vagy több).
const List<int> sessionLengthOptions = [30, 45, 60, 75, 90];

/// A napi étkezések választható száma.
const List<int> mealsPerDayOptions = [2, 3, 4, 5, 6];
