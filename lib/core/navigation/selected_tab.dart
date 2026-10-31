import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A fülek sorszámai az alsó navigációs sávban.
abstract final class AppTabs {
  static const int chat = 0;
  static const int calendar = 1;
  static const int checkIn = 2;
  static const int profile = 3;
}

/// Az éppen kiválasztott fül. Így az app bármely pontjáról át lehet
/// váltani egy másik fülre (pl. a profil kitöltése után a Profil fülre).
final selectedTabProvider = NotifierProvider<SelectedTabController, int>(
  SelectedTabController.new,
);

class SelectedTabController extends Notifier<int> {
  @override
  int build() => AppTabs.chat;

  void select(int index) => state = index;
}
