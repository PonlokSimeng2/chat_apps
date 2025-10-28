import 'message_status.dart';

class MessageModel {
  final int? id;
  final String? tempId; // Temporary ID for optimistic updates
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
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      status: _parseMessageStatus(json),
    );
  }

  static MessageStatus _parseMessageStatus(Map<String, dynamic> json) {
    // Determine status based on read_at and other fields
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
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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

  // Check if message is unread
  bool get isUnread => readAt == null;

  // Factory method for creating temporary message (optimistic UI)
  factory MessageModel.createTemp({
    required int conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${senderId.hashCode}';
    return MessageModel(
      tempId: tempId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      messageType: messageType,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  // Check if this is a temporary message
  bool get isTemp => tempId != null && id == null;

  // Get the unique identifier for this message (tempId or id)
  String get uniqueId => tempId ?? id.toString();
}
