/// Fájlok mentése és megnyitása.
///
/// Weben (a telefonon és a böngészőben) a valódi megvalósítás fut,
/// minden más környezetben (pl. tesztekben) egy üres helyettesítő.
library;

export 'file_service_stub.dart'
    if (dart.library.js_interop) 'file_service_web.dart';
