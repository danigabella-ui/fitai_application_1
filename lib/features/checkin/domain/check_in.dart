import '../../../core/utils/map_utils.dart';

/// A reggeli check-in. Naponta egy van; ha aznap újra kitöltöd, felülíródik.
///
/// A négy csúszka 1–7-es skálán:
/// - [sleepQuality]: 1 = nagyon rossz, 7 = kiváló
/// - [energy]: 1 = kimerült, 7 = teljesen kipihent
/// - [soreness]: 1 = nincs izomláz, 7 = erős izomláz
/// - [stress]: 1 = nyugodt, 7 = nagyon terhelt
class CheckIn {
  const CheckIn({
    required this.date,
    required this.sleepQuality,
    required this.energy,
    required this.soreness,
    required this.stress,
    this.watchSleepScore,
    this.painLocation,
  });

  final DateTime date;
  final int sleepQuality;
  final int energy;
  final int soreness;
  final int stress;

  /// Opcionális: az óra alváspontszáma (0–100).
  final int? watchSleepScore;

  /// Opcionális: ha valami konkrétan fáj, hol (pl. "bal térd").
  /// Null, ha nincs fájdalom.
  final String? painLocation;

  /// A nap azonosítója az adatbázisban, pl. "2026-10-31".
  String get dayKey => dayKeyOf(date);

  static String dayKeyOf(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, Object?> toMap() => {
        'date': dayKey,
        'sleepQuality': sleepQuality,
        'energy': energy,
        'soreness': soreness,
        'stress': stress,
        'watchSleepScore': watchSleepScore,
        'painLocation': painLocation,
      };

  factory CheckIn.fromMap(Map<String, Object?> map) => CheckIn(
        date: readDate(map['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        sleepQuality: readInt(map['sleepQuality']) ?? 4,
        energy: readInt(map['energy']) ?? 4,
        soreness: readInt(map['soreness']) ?? 4,
        stress: readInt(map['stress']) ?? 4,
        watchSleepScore: readInt(map['watchSleepScore']),
        painLocation: readString(map['painLocation']),
      );
}
