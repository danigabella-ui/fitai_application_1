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
