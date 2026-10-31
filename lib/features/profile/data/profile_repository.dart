import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(appDatabaseProvider));
});

/// A felhasználói profil olvasása és mentése.
class ProfileRepository {
  ProfileRepository(this._database);

  final AppDatabase _database;

  /// A profil egyetlen rekordként van tárolva ezen a kulcson.
  static const String _profileKey = 'main';

  /// A mentett profil, vagy null, ha még soha nem volt profil elmentve.
  /// Ebből tudja az app, hogy az első indítás képernyőjét kell-e mutatnia.
  Future<UserProfile?> findProfile() async {
    final map = await Stores.profile.record(_profileKey).get(_database.db);
    if (map == null) return null;
    return UserProfile.fromMap(map);
  }

  Future<UserProfile> getProfile() async {
    final map = await Stores.profile.record(_profileKey).get(_database.db);
    if (map == null) return UserProfile.empty;
    return UserProfile.fromMap(map);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await Stores.profile.record(_profileKey).put(_database.db, profile.toMap());
  }
}
