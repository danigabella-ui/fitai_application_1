import '../../../core/utils/map_utils.dart';

/// A mérhető értékek: felirat, mértékegység és az ésszerű tartomány.
/// A sorrend itt dönti el a sorrendet az űrlapon és a kártyákon is.
enum MeasurementField {
  weight('Testsúly', 'kg', 30, 300),
  neck('Nyak', 'cm', 20, 70),
  chest('Mellkas', 'cm', 50, 200),
  waist('Derék', 'cm', 40, 200),
  hip('Csípő', 'cm', 50, 200),
  thigh('Comb', 'cm', 25, 120),
  calf('Vádli', 'cm', 20, 70),
  biceps('Bicepsz', 'cm', 15, 70);

  const MeasurementField(this.label, this.unit, this.min, this.max);

  final String label;
  final String unit;
  final double min;
  final double max;

  /// A mérőszalagos körméretek (a testsúly nélkül).
  static const List<MeasurementField> circumferences = [
    neck,
    chest,
    waist,
    hip,
    thigh,
    calf,
    biceps,
  ];
}

/// Egy mérési nap. Naponta egy mérés van: ha ugyanarra a napra újra
/// rögzítesz, az új értékek kiegészítik (vagy felülírják) a meglévőket.
/// Nem kell minden mezőt kitölteni, csak azokat, amelyeket mérni érdemes.
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

  /// Mérés a megadott értékekből. A dátumból csak a nap számít.
  factory Measurement.fromValues(
    DateTime date,
    Map<MeasurementField, double?> values,
  ) =>
      Measurement(
        date: DateTime(date.year, date.month, date.day),
        weightKg: values[MeasurementField.weight],
        neckCm: values[MeasurementField.neck],
        chestCm: values[MeasurementField.chest],
        waistCm: values[MeasurementField.waist],
        hipCm: values[MeasurementField.hip],
        thighCm: values[MeasurementField.thigh],
        calfCm: values[MeasurementField.calf],
        bicepsCm: values[MeasurementField.biceps],
      );

  /// Az adatbázis azonosítója (a nap, pl. "2026-10-31"); null, amíg nincs
  /// elmentve.
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

  /// A nap azonosítója az adatbázisban, pl. "2026-10-31".
  String get dayKey => dayKeyOf(date);

  static String dayKeyOf(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double? valueOf(MeasurementField field) => switch (field) {
        MeasurementField.weight => weightKg,
        MeasurementField.neck => neckCm,
        MeasurementField.chest => chestCm,
        MeasurementField.waist => waistCm,
        MeasurementField.hip => hipCm,
        MeasurementField.thigh => thighCm,
        MeasurementField.calf => calfCm,
        MeasurementField.biceps => bicepsCm,
      };

  /// Van-e legalább egy kitöltött érték.
  bool get hasAnyValue =>
      MeasurementField.values.any((field) => valueOf(field) != null);

  /// A kitöltött mezők, a megadott sorrendben.
  List<MeasurementField> get filledFields => [
        for (final field in MeasurementField.values)
          if (valueOf(field) != null) field,
      ];

  /// Ez a mérés kiegészítve egy ugyanarra a napra rögzített újabbal:
  /// ahol az újabbnak van értéke, az számít, a többi marad.
  Measurement mergedWith(Measurement newer) => Measurement(
        id: id,
        date: date,
        weightKg: newer.weightKg ?? weightKg,
        neckCm: newer.neckCm ?? neckCm,
        chestCm: newer.chestCm ?? chestCm,
        waistCm: newer.waistCm ?? waistCm,
        hipCm: newer.hipCm ?? hipCm,
        thighCm: newer.thighCm ?? thighCm,
        calfCm: newer.calfCm ?? calfCm,
        bicepsCm: newer.bicepsCm ?? bicepsCm,
      );

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
