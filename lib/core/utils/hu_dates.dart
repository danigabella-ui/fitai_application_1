/// Magyar dátumformázás egyszerű segédfüggvényekkel.
library;

const List<String> _weekdays = [
  'hétfő',
  'kedd',
  'szerda',
  'csütörtök',
  'péntek',
  'szombat',
  'vasárnap',
];

const List<String> _months = [
  'január',
  'február',
  'március',
  'április',
  'május',
  'június',
  'július',
  'augusztus',
  'szeptember',
  'október',
  'november',
  'december',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Pl. "Szombat, október 31."
String huLongDate(DateTime date) {
  final weekday = _weekdays[date.weekday - 1];
  final capitalized = weekday[0].toUpperCase() + weekday.substring(1);
  return '$capitalized, ${_months[date.month - 1]} ${date.day}.';
}

/// Pl. "szombat"
String huWeekday(DateTime date) => _weekdays[date.weekday - 1];

/// Pl. "2026. 10. 31-i" (melléknévként: "a 2026. 10. 31-i mérés")
String huShortDateAdjective(DateTime date) =>
    '${date.year}. ${_two(date.month)}. ${_two(date.day)}-i';

/// Pl. "2027. február 28."
String huFullDate(DateTime date) =>
    '${date.year}. ${_months[date.month - 1]} ${date.day}.';

/// Pl. "2026. 10. 31."
String huShortDate(DateTime date) =>
    '${date.year}. ${_two(date.month)}. ${_two(date.day)}.';

/// Pl. "2026. 10. 31. 14:05"
String huDateTime(DateTime date) {
  final local = date.toLocal();
  return '${huShortDate(local)} ${_two(local.hour)}:${_two(local.minute)}';
}

/// A hét napjainak rövid neve, hétfőtől (1) vasárnapig (7).
const List<String> huWeekdayShortNames = [
  'H',
  'K',
  'Sze',
  'Cs',
  'P',
  'Szo',
  'V',
];

/// Időpont az éjféltől eltelt percekből, pl. 390 → "6:30".
String huClock(int minutesOfDay) {
  final hours = (minutesOfDay ~/ 60) % 24;
  return '$hours:${_two(minutesOfDay % 60)}';
}

/// Napok rövid felsorolása (1 = hétfő … 7 = vasárnap).
/// Egymást követő, legalább 3 napos sorozatnál tartományt ír:
/// {1,2,3,4,5} → "H–P", {1,3,5} → "H, Sze, P".
String huWeekdaySet(Set<int> days) {
  final sorted = days.where((d) => d >= 1 && d <= 7).toList()..sort();
  if (sorted.isEmpty) return '';
  final isRun = sorted.length >= 3 && sorted.last - sorted.first == sorted.length - 1;
  if (isRun) {
    return '${huWeekdayShortNames[sorted.first - 1]}–'
        '${huWeekdayShortNames[sorted.last - 1]}';
  }
  return sorted.map((d) => huWeekdayShortNames[d - 1]).join(', ');
}

/// Mennyi idő telt el egy dátum óta: "ma", "5 napja", "3 hete",
/// "9 hónapja", "2 éve".
String huElapsed(DateTime from, {DateTime? now}) {
  final current = now ?? DateTime.now();
  // UTC-ben számolunk, hogy az óraátállítás ne zavarja.
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(current.year, current.month, current.day);
  final days = b.difference(a).inDays;
  if (days <= 0) return 'ma';
  if (days < 14) return '$days napja';
  if (days < 60) return '${days ~/ 7} hete';
  if (days < 730) return '${(days / 30.44).floor()} hónapja';
  return '${days ~/ 365} éve';
}
