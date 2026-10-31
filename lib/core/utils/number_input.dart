/// Számok beolvasása és kiírása magyar formában (tizedesvesszővel).
///
/// Az iPhone magyar billentyűzete tizedesvesszőt ad (82,5), ezért a
/// beolvasás a vesszőt és a pontot is elfogadja, a kiírás pedig vesszőt
/// használ.
library;

import 'package:flutter/widgets.dart';

/// Tizedes tört beolvasása. Üres vagy értelmezhetetlen szövegre null.
/// A szóközöket figyelmen kívül hagyja ("2 450" → 2450).
double? parseDecimal(String text) {
  final cleaned = text.trim().replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || !value.isFinite) return null;
  return value;
}

/// Egész szám beolvasása. Ha a szöveg nem egész szám, null.
int? parseWholeNumber(String text) {
  final value = parseDecimal(text);
  if (value == null || value != value.roundToDouble()) return null;
  return value.round();
}

/// Szám kiírása: egész számnál tizedes nélkül ("182"),
/// egyébként egy tizedesjeggyel, vesszővel ("82,5"). Null → üres szöveg.
String formatDecimal(num? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

/// Ellenőrző szabály számmezőkhöz. Az üres mező mindig rendben van
/// (minden adat opcionális), a kitöltöttnek számnak kell lennie a
/// megadott határok között.
FormFieldValidator<String> numberValidator({
  required num min,
  required num max,
  String unit = '',
  bool wholeNumber = false,
}) {
  return (text) {
    if (text == null || text.trim().isEmpty) return null;
    final num? value =
        wholeNumber ? parseWholeNumber(text) : parseDecimal(text);
    if (value == null) {
      return wholeNumber
          ? 'Egész számot adj meg.'
          : 'Számot adj meg, például 82,5.';
    }
    if (value < min || value > max) {
      final suffix = unit.isEmpty ? '' : ' $unit';
      return '${formatDecimal(min)} és ${formatDecimal(max)}$suffix között legyen.';
    }
    return null;
  };
}
