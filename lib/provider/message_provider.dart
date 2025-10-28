import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../model/message_model.dart';

part 'message_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageNotifier extends _$MessageNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  WebSocketChannel? _wsChannel;

  @override
  AsyncValue<List<MessageModel>> build() {
    ref.onDispose(() {
      _wsChannel?.sink.close();
    });
    return const AsyncValue.data([]);
  }

  void _connectWebSocket(int conversationId) {
    // Close any existing channel
    _wsChannel?.sink.close();

    // Connect to the WebSocket server
    _wsChannel = WebSocketChannel.connect(
      Uri.parse(
        'wss://desirable-moira-kfa-f246aea1.koyeb.app/ws?conversationId=$conversationId',
      ),
    );

    // Listen to incoming messages
    _wsChannel!.stream.listen(
      (message) {
        try {
          final decodedMessage = jsonDecode(message);
          final newMessage = MessageModel.fromJson(decodedMessage);
          addMessage(newMessage);
        } catch (e) {
          print('Error decoding or handling message: $e');
        }
      },
      onError: (error) => print('WebSocket error: $error'),
      onDone: () => print('WebSocket closed'),
    );
  }

  Future<void> loadMessages(int conversationId) async {
    state = const AsyncValue.loading();

    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      state = AsyncValue.data(messages);

      // Setup WebSocket connection
      _connectWebSocket(conversationId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Public method to add message (for WebSocket integration)
  void addMessage(MessageModel message) {
    final currentData = state.value ?? [];

    // Check if message already exists to avoid duplicates
    if (!currentData.any((msg) => msg.id == message.id)) {
      state = AsyncValue.data([...currentData, message]);
    }
  }

  // Public method to update message (for WebSocket integration)
  void updateMessage(MessageModel message) {
    final currentData = state.value ?? [];
    final updatedList = currentData.map((msg) {
      return msg.id == message.id ? message : msg;
    }).toList();
    state = AsyncValue.data(updatedList);
  }

  // Public method to delete message (for WebSocket integration)
  void deleteMessage(int messageId) {
    final currentData = state.value ?? [];
    final filteredList = currentData
        .where((msg) => msg.id != messageId)
        .toList();
    state = AsyncValue.data(filteredList);
  }

  Future<void> sendMessage({
    required int conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
    String? fileName,
    int? fileSize,
    int? replyToMessageId,
  }) async {
    try {
      final newMessageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'reply_to_message_id': replyToMessageId,
        'is_edited': false,
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values
      newMessageData.removeWhere((key, value) => value == null);

      final response = await _client
          .from('messages')
          .insert(newMessageData)
          .select()
          .single();

      // Send the persisted message over WebSocket
      _wsChannel?.sink.add(jsonEncode(response));

      // No need to return the message, listener will update state.
      // Also, add it locally for immediate UI update.
      addMessage(MessageModel.fromJson(response));
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<MessageModel> editMessage({
    required int messageId,
    required String newContent,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .select()
          .single();

      final updatedMessage = MessageModel.fromJson(response);

      // Update local state immediately
      updateMessage(updatedMessage);

      return updatedMessage;
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  Future<void> deleteMessagePermanently(int messageId) async {
    try {
      await _client
          .from('messages')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);

      // Update local state immediately
      deleteMessage(messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> markAsRead(int messageId) async {
    try {
      await _client
          .from('messages')
          .update({
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      // Don't throw error for read receipts as they're not critical
      print('Failed to mark message as read: $e');
    }
  }

  Future<void> markAllMessagesAsRead({
    required String userId,
    required int conversationId,
  }) async {
    try {
      await _client
          .from('messages')
          .update({
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .filter('read_at', 'is', null);
    } catch (e) {
      // Don't throw error for read receipts as they're not critical
      print('Failed to mark all messages as read: $e');
    }
  }

  Future<List<MessageModel>> searchMessages({
    required int conversationId,
    required String query,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Get messages for a specific conversation
  List<MessageModel> getMessagesForConversation(int conversationId) {
    final allMessages = state.value ?? [];
    return allMessages
        .where(
          (msg) =>
              msg.conversationId == conversationId && msg.isDeleted != true,
        )
        .toList();
  }

  Future<int> getUnreadMessageCount({
    required String userId,
    required int conversationId,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_deleted', false)
          .filter('read_at', 'is', null)
          .count();
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<MessageModel?> getLastMessage({
    required int conversationId,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? MessageModel.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  // Clear all messages (useful when logging out)
  void clearMessages() {
    state = const AsyncValue.data([]);
  }
}

// Convenience providers
@riverpod
class MessagePagination extends _$MessagePagination {
  final int _limit = 50;
  int _offset = 0;
  bool _hasMore = true;
  int? _currentConversationId;

  @override
  AsyncValue<List<MessageModel>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> loadMoreMessages(int conversationId) async {
    if (!_hasMore) return;

    // If conversation changed, reset pagination
    if (_currentConversationId != conversationId) {
      _offset = 0;
      _hasMore = true;
      _currentConversationId = conversationId;
      state = const AsyncValue.data([]);
    }

    state = const AsyncValue.loading();

    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      final newMessages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      // Reverse to maintain chronological order
      final chronologicalMessages = newMessages.reversed.toList();

      if (newMessages.length < _limit) {
        _hasMore = false;
      }

      _offset += newMessages.length;

      state = AsyncValue.data([...state.value ?? [], ...chronologicalMessages]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    _offset = 0;
    _hasMore = true;
    _currentConversationId = null;
    state = const AsyncValue.data([]);
  }

  bool get hasMore => _hasMore;
}
