class MessageReactionModel {
  final String id;
  final int messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  const MessageReactionModel({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) {
    return MessageReactionModel(
      id: json['id'] as String,
      messageId: json['message_id'] as int,
      userId: json['user_id'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Used when inserting a new emoji reaction
  static Map<String, dynamic> insertEmoji({
    required int messageId,
    required String userId,
    required String emoji,
  }) {
    return {'message_id': messageId, 'user_id': userId, 'emoji': emoji};
  }

  MessageReactionModel copyWith({
    String? id,
    int? messageId,
    String? userId,
    String? emoji,
    DateTime? createdAt,
  }) {
    return MessageReactionModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageReactionModel &&
          other.id == id &&
          other.messageId == messageId &&
          other.userId == userId;

  @override
  int get hashCode => id.hashCode ^ messageId.hashCode ^ userId.hashCode;

  @override
  String toString() =>
      'MessageReactionModel(id: $id, messageId: $messageId, userId: $userId, emoji: $emoji)';
}
