import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/stores.dart';
import '../domain/chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(appDatabaseProvider));
});

/// A chat-üzenetek olvasása, mentése és törlése.
class ChatRepository {
  ChatRepository(this._database);

  final AppDatabase _database;

  /// Az összes üzenet időrendben (a legrégebbi elöl).
  Future<List<ChatMessage>> getAll() async {
    final records = await Stores.chatMessages.find(
      _database.db,
      finder: Finder(sortOrders: [SortOrder('createdAt')]),
    );
    return records
        .map((record) => ChatMessage.fromMap(record.key, record.value))
        .toList();
  }

  /// Új üzenet mentése; visszaadja az új azonosítót.
  Future<String> add(ChatMessage message) {
    return Stores.chatMessages.add(_database.db, message.toMap());
  }

  /// A teljes beszélgetés törlése.
  Future<void> clear() async {
    await Stores.chatMessages.delete(_database.db);
  }
}
