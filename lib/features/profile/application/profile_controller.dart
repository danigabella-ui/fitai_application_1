import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// A felhasználói profil, az app bármely pontjáról figyelhető.
///
/// Az értéke null, amíg még soha nem lett profil elmentve: ilyenkor az app
/// az üdvözlőképernyővel indul.
final profileProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() {
    return ref.watch(profileRepositoryProvider).findProfile();
  }

  /// Elmenti a profilt, és azonnal frissít minden képernyőt, amely figyeli.
  Future<void> save(UserProfile profile) async {
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    state = AsyncData(profile);
  }
}
