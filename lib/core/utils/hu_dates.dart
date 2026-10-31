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
