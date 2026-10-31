import 'package:sembast/sembast.dart';

/// A helyi adatbázis. Weben a böngésző tárhelyén (IndexedDB) él,
/// vagyis az adatok a telefonon maradnak, sehova nem töltődnek fel.
class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static const String fileName = 'fitai.db';

  /// Megnyitja az adatbázist (első indításkor létre is hozza).
  /// A [factory] dönti el, hol tárolódik: weben a böngészőben,
  /// tesztekben a memóriában.
  static Future<AppDatabase> open(DatabaseFactory factory) async {
    final db = await factory.openDatabase(fileName);
    return AppDatabase(db);
  }
}
