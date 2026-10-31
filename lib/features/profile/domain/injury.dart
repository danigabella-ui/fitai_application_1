import '../../../core/utils/map_utils.dart';
import 'profile_options.dart';

// A testrészlista (BodyArea) innen is elérhető legyen.
export 'profile_options.dart';

// FONTOS: az értékek neve (pl. `surgery`) az adatbázisban és a mentésekben
// is így szerepel, ezért utólag nem szabad átnevezni őket.

enum InjurySide {
  left('Bal'),
  right('Jobb'),
  both('Mindkettő');

  const InjurySide(this.label);
  final String label;
}

enum InjuryType {
  surgery('Műtét'),
  strain('Húzódás'),
  sprain('Ficam'),
  ligament('Szalagsérülés'),
  fracture('Törés'),
  chronicPain('Tartós fájdalom'),
  other('Egyéb');

  const InjuryType(this.label);
  final String label;
}

enum InjuryStatus {
  active('Aktív'),
  rehab('Rehabilitáció'),
  healed('Gyógyult');

  const InjuryStatus(this.label);
  final String label;
}

/// Mennyire terhelhető most a sérült terület (4 fokozat).
enum LoadCapacity {
  protect('Kímélni kell'),
  light('Enyhén terhelhető'),
  progressive('Fokozatosan terhelhető'),
  full('Teljesen terhelhető');

  const LoadCapacity(this.label);
  final String label;
}

/// Mozgások, amelyek még gondot okozhatnak.
enum Movement {
  running('Futás'),
  sprint('Sprint'),
  changeOfDirection('Irányváltás'),
  jumping('Ugrás'),
  kicking('Rúgás'),
  squat('Guggolás'),
  lunge('Kitörés'),
  lifting('Súlyemelés');

  const Movement(this.label);
  final String label;
}

/// Egy állapotfrissítés: hol tart a sérülés egy adott napon.
class InjuryUpdate {
  const InjuryUpdate({
    required this.date,
    this.capacity,
    this.problemMovements = const <Movement>{},
    this.medicalNote,
  });

  final DateTime date;
  final LoadCapacity? capacity;
  final Set<Movement> problemMovements;

  /// Orvosi vagy gyógytornász utasítás (pl. „június végéig nincs futás”).
  final String? medicalNote;

  Map<String, Object?> toMap() => {
        'date': date.toIso8601String(),
        'capacity': capacity?.name,
        'problemMovements': enumSetToList(problemMovements),
        'medicalNote': medicalNote,
      };

  factory InjuryUpdate.fromMap(Map<String, Object?> map) => InjuryUpdate(
        date: readDate(map['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        capacity: enumByName(LoadCapacity.values, map['capacity']),
        problemMovements: readEnumSet(Movement.values, map['problemMovements']),
        medicalNote: readString(map['medicalNote']),
      );
}

/// Egy sérülés a sérülésnaplóban, az állapotfrissítéseivel együtt.
/// A gyógyult sérülés sem törlődik: az AI így tudja, hol volt korábban gond.
class Injury {
  const Injury({
    this.id,
    required this.area,
    this.side,
    this.type,
    this.startDate,
    this.status = InjuryStatus.active,
    this.updates = const [],
    required this.createdAt,
  });

  /// Hány nap után jelezze az app, hogy ideje frissíteni egy nyitott sérülést.
  static const int staleAfterDays = 28;

  /// Az adatbázis azonosítója; null, amíg nincs elmentve.
  final String? id;
  final BodyArea? area;
  final InjurySide? side;
  final InjuryType? type;
  final DateTime? startDate;
  final InjuryStatus status;

  /// Az állapotfrissítések, a legfrissebb elöl.
  final List<InjuryUpdate> updates;

  /// Mikor rögzítette a felhasználó a sérülést.
  final DateTime createdAt;

  InjuryUpdate? get latestUpdate => updates.isEmpty ? null : updates.first;

  /// Nem gyógyult még (aktív vagy rehabilitáció).
  bool get isOpen => status != InjuryStatus.healed;

  /// Igaz, ha nyitott sérülés, és régen volt frissítve.
  bool needsUpdate({DateTime? now}) {
    if (!isOpen) return false;
    final last = latestUpdate?.date ?? createdAt;
    return (now ?? DateTime.now()).difference(last).inDays >= staleAfterDays;
  }

  static const Object _keep = Object();

  Injury copyWith({
    Object? area = _keep,
    Object? side = _keep,
    Object? type = _keep,
    Object? startDate = _keep,
    InjuryStatus? status,
    List<InjuryUpdate>? updates,
  }) {
    T? pick<T>(Object? value, T? current) =>
        identical(value, _keep) ? current : value as T?;

    return Injury(
      id: id,
      area: pick<BodyArea>(area, this.area),
      side: pick<InjurySide>(side, this.side),
      type: pick<InjuryType>(type, this.type),
      startDate: pick<DateTime>(startDate, this.startDate),
      status: status ?? this.status,
      updates: updates == null ? this.updates : sortUpdates(updates),
      createdAt: createdAt,
    );
  }

  /// A frissítések dátum szerint, a legfrissebb elöl.
  static List<InjuryUpdate> sortUpdates(Iterable<InjuryUpdate> updates) =>
      updates.toList()..sort((a, b) => b.date.compareTo(a.date));

  Map<String, Object?> toMap() => {
        'area': area?.name,
        'side': side?.name,
        'type': type?.name,
        'startDate': startDate?.toIso8601String(),
        'status': status.name,
        'updates': [for (final update in updates) update.toMap()],
        'createdAt': createdAt.toIso8601String(),
      };

  factory Injury.fromMap(String id, Map<String, Object?> map) {
    final rawUpdates = map['updates'];
    return Injury(
      id: id,
      area: enumByName(BodyArea.values, map['area']),
      side: enumByName(InjurySide.values, map['side']),
      type: enumByName(InjuryType.values, map['type']),
      startDate: readDate(map['startDate']),
      status: enumByName(InjuryStatus.values, map['status']) ??
          InjuryStatus.active,
      updates: sortUpdates([
        if (rawUpdates is List)
          for (final item in rawUpdates)
            if (item is Map) InjuryUpdate.fromMap(Map<String, Object?>.from(item)),
      ]),
      createdAt: readDate(map['createdAt']) ?? DateTime.now(),
    );
  }
}
