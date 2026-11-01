import 'package:fitai_application_1/core/database/app_database.dart';
import 'package:fitai_application_1/features/checkin/data/checkin_repository.dart';
import 'package:fitai_application_1/features/checkin/domain/check_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

CheckIn _sample(DateTime day) => CheckIn(
      date: day,
      sleepQuality: 5,
      energy: 4,
      soreness: 2,
      stress: 3,
      watchSleepScore: 82,
      pains: const [
        PainSpot(
          area: BodyArea.knee,
          side: InjurySide.left,
          intensity: PainIntensity.moderate,
        ),
        PainSpot(area: BodyArea.lowerBack, intensity: PainIntensity.mild),
      ],
      filledAt: DateTime(day.year, day.month, day.day, 7, 42),
    );

void main() {
  test('A check-in tárolás után ugyanaz marad', () {
    final original = _sample(DateTime(2026, 11, 1));
    final restored = CheckIn.fromMap(original.toMap());

    expect(restored.dayKey, '2026-11-01');
    for (final metric in CheckInMetric.values) {
      expect(restored.valueOf(metric), original.valueOf(metric));
    }
    expect(restored.watchSleepScore, 82);
    expect(
      restored.pains.map((pain) => pain.key).toList(),
      ['knee:left', 'lowerBack:-'],
    );
    expect(restored.pains.first.intensity, PainIntensity.moderate);
    expect(restored.filledAt, DateTime(2026, 11, 1, 7, 42));
    expect(restored.filledOnTheDay, isTrue);
  });

  test('Feliratok és oldalak', () {
    expect(CheckInMetric.sleep.levelLabel(5), 'jó');
    expect(CheckInMetric.soreness.levelLabel(1), 'nincs');
    expect(
      const PainSpot(
        area: BodyArea.knee,
        side: InjurySide.left,
        intensity: PainIntensity.severe,
      ).label,
      'Térd, bal – erős',
    );
    expect(bodyAreaHasSides(BodyArea.neck), isFalse);
    expect(sidesOverlap(InjurySide.left, InjurySide.right), isFalse);
    expect(sidesOverlap(InjurySide.left, InjurySide.both), isTrue);
    expect(sidesOverlap(null, InjurySide.right), isTrue);
  });

  test('A repository csak a kért napokat adja vissza', () async {
    final database = await AppDatabase.open(newDatabaseFactoryMemory());
    final repository = CheckInRepository(database);
    await repository.save(_sample(DateTime(2026, 10, 30)));
    await repository.save(_sample(DateTime(2026, 11, 1)));

    final result = await repository.getDays([
      DateTime(2026, 10, 31),
      DateTime(2026, 11, 1),
    ]);

    expect(result.keys.toList(), ['2026-11-01']);
  });
}
