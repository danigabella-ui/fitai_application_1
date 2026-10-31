import '../../../core/utils/map_utils.dart';

/// Egy mérési alkalom. Nem kell minden mezőt kitölteni,
/// csak azokat, amelyeket az aktuális célhoz mérni érdemes.
class Measurement {
  const Measurement({
    this.id,
    required this.date,
    this.weightKg,
    this.neckCm,
    this.chestCm,
    this.waistCm,
    this.hipCm,
    this.thighCm,
    this.calfCm,
    this.bicepsCm,
  });

  /// Az adatbázis azonosítója; null, amíg nincs elmentve.
  final String? id;
  final DateTime date;

  final double? weightKg;
  final double? neckCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipCm;
  final double? thighCm;
  final double? calfCm;
  final double? bicepsCm;

  Map<String, Object?> toMap() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'neckCm': neckCm,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'hipCm': hipCm,
        'thighCm': thighCm,
        'calfCm': calfCm,
        'bicepsCm': bicepsCm,
      };

  factory Measurement.fromMap(String id, Map<String, Object?> map) =>
      Measurement(
        id: id,
        date: readDate(map['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        weightKg: readDouble(map['weightKg']),
        neckCm: readDouble(map['neckCm']),
        chestCm: readDouble(map['chestCm']),
        waistCm: readDouble(map['waistCm']),
        hipCm: readDouble(map['hipCm']),
        thighCm: readDouble(map['thighCm']),
        calfCm: readDouble(map['calfCm']),
        bicepsCm: readDouble(map['bicepsCm']),
      );
}
