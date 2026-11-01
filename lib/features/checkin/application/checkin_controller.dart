import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/checkin_repository.dart';
import '../domain/check_in.dart';

/// A mai nap (éjfél, helyi idő szerint).
///
/// Az iPhone a kezdőképernyős appot a háttérben életben tarthatja, ezért
/// a Check-In fül percenként és az app előtérbe kerülésekor meghívja a
/// [CurrentDayController.refresh]-t. Így reggel az új nap jelenik meg,
/// nem a tegnapi.
final currentDayProvider = NotifierProvider<CurrentDayController, DateTime>(
  CurrentDayController.new,
);

class CurrentDayController extends Notifier<DateTime> {
  @override
  DateTime build() => _today();

  /// Ha közben új nap kezdődött, átvált rá.
  void refresh() {
    final today = _today();
    if (today != state) state = today;
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

/// A mai check-in és az előző napoké, egy csomagban.
class RecentCheckIns {
  const RecentCheckIns({required this.today, required this.byDay});

  /// Hány korábbi nap látszik a Check-In fülön.
  static const int historyDays = 7;

  final DateTime today;

  /// A nap azonosítója (pl. "2026-10-31") → check-in.
  final Map<String, CheckIn> byDay;

  CheckIn? forDay(DateTime day) => byDay[CheckIn.dayKeyOf(day)];

  CheckIn? get todayCheckIn => forDay(today);

  /// Az előző napok, tegnaptól visszafelé.
  List<DateTime> get pastDays => pastDaysOf(today);

  static List<DateTime> pastDaysOf(DateTime today) => [
        for (var i = 1; i <= historyDays; i++)
          DateTime(today.year, today.month, today.day - i),
      ];
}

/// A mai és az előző 7 nap check-injei. Bármelyik képernyő figyelheti.
final checkInsProvider =
    AsyncNotifierProvider<CheckInsController, RecentCheckIns>(
  CheckInsController.new,
);

class CheckInsController extends AsyncNotifier<RecentCheckIns> {
  @override
  Future<RecentCheckIns> build() {
    final today = ref.watch(currentDayProvider);
    return _load(ref.watch(checkInRepositoryProvider), today);
  }

  /// Elmenti a check-int (ha arra a napra már van, felülírja).
  Future<void> save(CheckIn checkIn) async {
    final repository = ref.read(checkInRepositoryProvider);
    await repository.save(checkIn);
    state = AsyncData(await _load(repository, ref.read(currentDayProvider)));
  }

  static Future<RecentCheckIns> _load(
    CheckInRepository repository,
    DateTime today,
  ) async {
    final byDay = await repository.getDays([
      today,
      ...RecentCheckIns.pastDaysOf(today),
    ]);
    return RecentCheckIns(today: today, byDay: byDay);
  }
}
