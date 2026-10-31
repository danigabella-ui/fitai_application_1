import 'package:sembast/sembast.dart';

/// Az adatbázis "fiókjai": minden adattípus külön tárolóba kerül.
abstract final class Stores {
  /// Egyszerű beállítások kulcs-érték párokként (pl. API-kulcs).
  static final StoreRef<String, String> settings =
      StoreRef<String, String>('settings');

  /// A felhasználói profil (egyetlen rekord).
  static final profile = stringMapStoreFactory.store('profile');

  /// Testsúly és mérőszalagos mérések, dátummal.
  static final measurements = stringMapStoreFactory.store('measurements');

  /// Reggeli check-inek, naponta egy.
  static final checkIns = stringMapStoreFactory.store('check_ins');

  /// A chat üzenetei.
  static final chatMessages = stringMapStoreFactory.store('chat_messages');
}
