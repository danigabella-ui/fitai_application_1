/// Segédfüggvények a tárolt adatok biztonságos visszaolvasásához.
/// Ha egy mező hiányzik vagy rossz típusú, null-t adnak vissza hiba helyett.
library;

T? enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

int? readInt(Object? value) => value is num ? value.toInt() : null;

double? readDouble(Object? value) => value is num ? value.toDouble() : null;

String? readString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

DateTime? readDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

bool readBool(Object? value) => value == true;

/// Értékek halmaza a tárolt névlistából; az ismeretlen neveket kihagyja.
Set<T> readEnumSet<T extends Enum>(List<T> values, Object? raw) {
  final result = <T>{};
  if (raw is! List) return result;
  for (final item in raw) {
    final value = enumByName(values, item);
    if (value != null) result.add(value);
  }
  return result;
}

/// Egész számok halmaza a tárolt listából.
Set<int> readIntSet(Object? raw) {
  final result = <int>{};
  if (raw is! List) return result;
  for (final item in raw) {
    if (item is num) result.add(item.toInt());
  }
  return result;
}

/// Értékek halmaza tárolható névlistaként, mindig ugyanabban a sorrendben.
List<String> enumSetToList<T extends Enum>(Set<T> values) {
  final sorted = values.toList()..sort((a, b) => a.index.compareTo(b.index));
  return [for (final value in sorted) value.name];
}

/// Egész számok halmaza tárolható listaként, növekvő sorrendben.
List<int> intSetToList(Set<int> values) => values.toList()..sort();
