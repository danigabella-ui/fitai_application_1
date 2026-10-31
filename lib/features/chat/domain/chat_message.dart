import '../../../core/utils/map_utils.dart';

/// Ki írta az üzenetet.
enum ChatRole { user, assistant }

/// Egy chat-üzenet.
class ChatMessage {
  const ChatMessage({
    this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  /// Az adatbázis azonosítója; null, amíg nincs elmentve.
  final String? id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'role': role.name,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromMap(String id, Map<String, Object?> map) =>
      ChatMessage(
        id: id,
        role: enumByName(ChatRole.values, map['role']) ?? ChatRole.user,
        text: map['text'] is String ? map['text'] as String : '',
        createdAt:
            readDate(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}
