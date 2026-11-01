import '../../../core/utils/map_utils.dart';
import '../../profile/domain/injury.dart';

// A testrészek (BodyArea) és az oldalak (InjurySide) innen is elérhetők
// legyenek: a fájdalom helye a sérülésnapló listáit használja.
export '../../profile/domain/injury.dart' show BodyArea, InjurySide;

// FONTOS: az értékek neve (pl. `moderate`) az adatbázisban és a mentésekben
// is így szerepel, ezért utólag nem szabad átnevezni őket.

/// A reggeli check-in négy csúszkája, 1–7-es skálán.
///
/// Az alvásnál és az energiánál a magas szám a jó, az izomláznál és a
/// stressznél a magas szám a rossz. A [levels] a hét fokozat felirata,
/// 1-től 7-ig.
enum CheckInMetric {
  sleep('Alvás', [
    'nagyon rossz',
    'rossz',
    'gyenge',
    'közepes',
    'jó',
    'nagyon jó',
    'kiváló',
  ]),
  energy('Energia', [
    'kimerült',
    'nagyon fáradt',
    'fáradt',
    'közepes',
    'friss',
    'nagyon friss',
    'teljesen kipihent',
  ]),
  soreness('Izomláz', [
    'nincs',
    'alig érezhető',
    'enyhe',
    'közepes',
    'jelentős',
    'erős',
    'nagyon erős',
  ]),
  stress('Stressz', [
    'teljesen nyugodt',
    'nyugodt',
    'enyhe',
    'közepes',
    'feszült',
    'nagyon feszült',
    'túlterhelt',
  ]);

  const CheckInMetric(this.label, this.levels);

  final String label;
  final List<String> levels;

  static const int minValue = 1;
  static const int maxValue = 7;

  /// Egy érték felirata, pl. alvás, 5 → „jó”.
  String levelLabel(int value) {
    var index = value - minValue;
    if (index < 0) index = 0;
    if (index > levels.length - 1) index = levels.length - 1;
    return levels[index];
  }
}

/// A fájdalom erőssége.
enum PainIntensity {
  mild('Enyhe'),
  moderate('Közepes'),
  severe('Erős');

  const PainIntensity(this.label);
  final String label;
}

/// Van-e értelme oldalt választani ennél a testrésznél
/// (a nyaknál és a deréknál nincs).
bool bodyAreaHasSides(BodyArea area) =>
    area != BodyArea.neck && area != BodyArea.lowerBack;

/// Átfedi-e egymást két oldal. Ha valamelyik nincs megadva, vagy
/// valamelyik „Mindkettő”, akkor igen.
bool sidesOverlap(InjurySide? a, InjurySide? b) =>
    a == null ||
    b == null ||
    a == InjurySide.both ||
    b == InjurySide.both ||
    a == b;

/// Egy fájdalom helye és erőssége a check-inben.
class PainSpot {
  const PainSpot({required this.area, this.side, required this.intensity});

  final BodyArea area;

  /// Null, ha a testrésznél nincs oldal (nyak, derék).
  final InjurySide? side;
  final PainIntensity intensity;

  /// A hely azonosítója: ugyanaz a hely egy check-inben csak egyszer
  /// szerepelhet.
  String get key => '${area.name}:${side?.name ?? '-'}';

  /// Pl. „Térd, bal” vagy „Váll, mindkét oldal”.
  String get placeLabel => switch (side) {
        null => area.label,
        InjurySide.both => '${area.label}, mindkét oldal',
        InjurySide s => '${area.label}, ${s.label.toLowerCase()}',
      };

  /// Pl. „Térd, bal – közepes”.
  String get label => '$placeLabel – ${intensity.label.toLowerCase()}';

  Map<String, Object?> toMap() => {
        'area': area.name,
        'side': side?.name,
        'intensity': intensity.name,
      };

  /// Null, ha a tárolt adatból hiányzik a testrész.
  static PainSpot? tryFromMap(Map<String, Object?> map) {
    final area = enumByName(BodyArea.values, map['area']);
    if (area == null) return null;
    return PainSpot(
      area: area,
      side: enumByName(InjurySide.values, map['side']),
      intensity: enumByName(PainIntensity.values, map['intensity']) ??
          PainIntensity.moderate,
    );
  }
}

/// A reggeli check-in. Naponta egy van; ha aznap újra kitöltöd, felülíródik.
///
/// A négy csúszka 1–7-es skálán (a feliratok a [CheckInMetric]-ben):
/// - [sleepQuality]: 1 = nagyon rossz, 7 = kiváló
/// - [energy]: 1 = kimerült, 7 = teljesen kipihent
/// - [soreness]: 1 = nincs izomláz, 7 = nagyon erős izomláz
/// - [stress]: 1 = teljesen nyugodt, 7 = túlterhelt
class CheckIn {
  const CheckIn({
    required this.date,
    required this.sleepQuality,
    required this.energy,
    required this.soreness,
    required this.stress,
    this.watchSleepScore,
    this.pains = const <PainSpot>[],
    this.filledAt,
  });

  /// Melyik napra szól (éjfél, helyi idő szerint).
  final DateTime date;
  final int sleepQuality;
  final int energy;
  final int soreness;
  final int stress;

  /// Opcionális: az óra alváspontszáma (0–100).
  final int? watchSleepScore;

  /// Ahol konkrétan fáj valami. Üres, ha nincs fájdalom.
  final List<PainSpot> pains;

  /// Mikor töltötte ki először a felhasználó. Módosításkor nem változik,
  /// így az AI látja, hogy reggel készült-e, vagy utólag lett pótolva.
  final DateTime? filledAt;

  /// A nap azonosítója az adatbázisban, pl. "2026-10-31".
  String get dayKey => dayKeyOf(date);

  /// Ugyanazon a napon lett kitöltve, amelyikre szól.
  bool get filledOnTheDay {
    final filled = filledAt;
    return filled != null && isSameDay(filled, date);
  }

  int valueOf(CheckInMetric metric) => switch (metric) {
        CheckInMetric.sleep => sleepQuality,
        CheckInMetric.energy => energy,
        CheckInMetric.soreness => soreness,
        CheckInMetric.stress => stress,
      };

  static String dayKeyOf(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static bool isSameDay(DateTime a, DateTime b) => dayKeyOf(a) == dayKeyOf(b);

  Map<String, Object?> toMap() => {
        'date': dayKey,
        'sleepQuality': sleepQuality,
        'energy': energy,
        'soreness': soreness,
        'stress': stress,
        'watchSleepScore': watchSleepScore,
        'pains': [for (final pain in pains) pain.toMap()],
        'filledAt': filledAt?.toIso8601String(),
      };

  factory CheckIn.fromMap(Map<String, Object?> map) => CheckIn(
        date: readDate(map['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        sleepQuality: readInt(map['sleepQuality']) ?? 4,
        energy: readInt(map['energy']) ?? 4,
        soreness: readInt(map['soreness']) ?? 4,
        stress: readInt(map['stress']) ?? 4,
        watchSleepScore: readInt(map['watchSleepScore']),
        pains: _readPains(map['pains']),
        filledAt: readDate(map['filledAt']),
      );

  static List<PainSpot> _readPains(Object? raw) {
    final result = <PainSpot>[];
    if (raw is! List) return result;
    for (final item in raw) {
      if (item is! Map) continue;
      final spot = PainSpot.tryFromMap(Map<String, Object?>.from(item));
      if (spot != null) result.add(spot);
    }
    return result;
  }
}
