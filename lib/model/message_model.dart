import 'message_status.dart';

class MessageModel {
  final int? id;
  final String? tempId;
  final int conversationId;
  final String senderId;
  final String receiverId;
  final String? content;
  final String messageType;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final int? replyToMessageId;
  final bool? isEdited;
  final bool? isDeleted;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final MessageStatus status;

  MessageModel({
    this.id,
    this.tempId,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    this.content,
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.replyToMessageId,
    this.isEdited,
    this.isDeleted,
    this.readAt,
    this.createdAt,
    this.updatedAt,
    this.status = MessageStatus.sent,
  });

  // ✅ Robust UTC parser — handles all Supabase timestamp formats
  static DateTime? _parseUtc(dynamic value) {
    if (value == null) return null;
    // Replace space with T for ISO 8601 compatibility
    // e.g. "2026-04-12 23:35:51+00" → "2026-04-12T23:35:51+00"
    final str = value.toString().replaceFirst(' ', 'T');
    try {
      if (!str.contains('+') && !str.endsWith('Z')) {
        // No timezone info → treat as UTC by appending Z
        return DateTime.parse('${str}Z').toUtc();
      }
      return DateTime.parse(str).toUtc();
    } catch (e) {
      // If parse fails, return null (will show "now" as fallback)
      return null;
    }
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      tempId: json['temp_id']?.toString(),
      conversationId: int.parse(json['conversation_id'].toString()),
      senderId: json['sender_id'].toString(),
      receiverId: json['receiver_id'].toString(),
      content: json['content']?.toString(),
      messageType: json['message_type']?.toString() ?? 'text',
      fileUrl: json['file_url']?.toString(),
      fileName: json['file_name']?.toString(),
      fileSize: json['file_size'] != null
          ? int.tryParse(json['file_size'].toString())
          : null,
      replyToMessageId: json['reply_to_message_id'] != null
          ? int.tryParse(json['reply_to_message_id'].toString())
          : null,
      isEdited: json['is_edited'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      readAt: _parseUtc(json['read_at']),
      createdAt: _parseUtc(json['created_at']),
      updatedAt: _parseUtc(json['updated_at']),
      status: _parseMessageStatus(json),
    );
  }

  static MessageStatus _parseMessageStatus(Map<String, dynamic> json) {
    if (json['read_at'] != null) {
      return MessageStatus.read;
    } else if (json['id'] != null) {
      return MessageStatus.sent;
    } else {
      return MessageStatus.sending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'temp_id': tempId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'reply_to_message_id': replyToMessageId,
      'is_edited': isEdited ?? false,
      'is_deleted': isDeleted ?? false,
      'read_at': readAt?.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'status': status.name,
    };
  }

  MessageModel copyWith({
    int? id,
    String? tempId,
    int? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    String? messageType,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    int? replyToMessageId,
    bool? isEdited,
    bool? isDeleted,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      tempId: tempId ?? this.tempId,
      conversationId: conversationId ?? this.conversationId,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  bool get isUnread => readAt == null;

  bool get isTemp => tempId != null && id == null;

  String get uniqueId => tempId ?? id.toString();

  factory MessageModel.createTemp({
    required int conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) {
    final tempId =
        'temp_${DateTime.now().millisecondsSinceEpoch}_${senderId.hashCode}';
    return MessageModel(
      tempId: tempId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      messageType: messageType,
      createdAt: DateTime.now().toUtc(), // ✅ UTC
      status: MessageStatus.sending,
    );
  }
}
