import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/message_model.dart';
import '../model/message_status.dart';
import '../model/user_model.dart';
import '../main.dart';

part 'message_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageNotifier extends _$MessageNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  @override
  AsyncValue<List<MessageModel>> build() {
    ref.onDispose(() {
      _disconnectRealtime();
    });
    return const AsyncValue.data([]);
  }

  void _setupRealtimeSubscription(int conversationId, String receiverId) {
    try {
      // Remove existing subscription
      _disconnectRealtime();

      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        talker.warning('User not authenticated for Realtime subscription');
        return;
      }

      talker.info('Setting up Realtime subscription for conversation $conversationId');

    // Create a channel for this conversation
    _channel = _client.channel('messages:conversation:$conversationId');

    // Subscribe to INSERT events
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            print('Realtime: 📨 New message received');
            _handleInsert(payload);
          },
        )
        // Subscribe to UPDATE events
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            print('Realtime: 🔄 Message updated');
            _handleUpdate(payload);
          },
        )
        // Subscribe to DELETE events
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            print('Realtime: 🗑️ Message deleted');
            _handleDelete(payload);
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            talker.info('Successfully subscribed to conversation $conversationId');
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            talker.warning('Realtime subscription timed out, retrying...');
            // Retry subscription
            Future.delayed(const Duration(seconds: 2), () {
              _setupRealtimeSubscription(conversationId, receiverId);
            });
          } else if (status == RealtimeSubscribeStatus.channelError) {
            talker.error('Realtime channel error', error);
          }
        });
    } catch (e, st) {
      talker.error('Error setting up realtime subscription', e, st);
    }
  }

  void _handleInsert(PostgresChangePayload payload) {
    try {
      final newData = payload.newRecord;
      if (newData.isEmpty) return;

      final newMessage = MessageModel.fromJson(newData);
      talker.info('New message received from ${newMessage.senderId}');

      addMessage(newMessage);
    } catch (e, st) {
      talker.error('Error handling realtime insert', e, st);
    }
  }

  void _handleUpdate(PostgresChangePayload payload) {
    try {
      final newData = payload.newRecord;
      if (newData.isEmpty) return;

      final updatedMessage = MessageModel.fromJson(newData);
      talker.info('Updating message ${updatedMessage.id}');

      updateMessage(updatedMessage);
    } catch (e, st) {
      talker.error('Error handling realtime update', e, st);
    }
  }

  void _handleDelete(PostgresChangePayload payload) {
    try {
      final oldData = payload.oldRecord;
      if (oldData.isEmpty) return;

      final messageId = oldData['id'] as int?;
      if (messageId != null) {
        talker.info('Deleting message $messageId');
        deleteMessage(messageId);
      }
    } catch (e, st) {
      talker.error('Error handling realtime delete', e, st);
    }
  }

  void _disconnectRealtime() {
    try {
      if (_channel != null) {
        talker.info('Disconnecting from realtime channel');
        _client.removeChannel(_channel!);
        _channel = null;
      }
    } catch (e, st) {
      talker.error('Error disconnecting realtime channel', e, st);
    }
  }

  Future<void> loadMessages(int conversationId, String receiverId) async {
    state = const AsyncValue.loading();

    try {
      talker.info('Loading messages for conversation $conversationId');

      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      talker.info('Loaded ${messages.length} messages for conversation $conversationId');
      state = AsyncValue.data(messages);

      // Setup Realtime subscription
      _setupRealtimeSubscription(conversationId, receiverId);
    } catch (e, stack) {
      talker.error('Error loading messages for conversation $conversationId', e, stack);
      state = AsyncValue.error(e, stack);
    }
  }

  // Public method to add message (for Realtime integration)
  void addMessage(MessageModel message) {
    final currentData = state.value ?? [];

    // Check if message already exists to avoid duplicates
    final existingMessageIndex = currentData.indexWhere(
      (msg) =>
          (msg.id != null && msg.id == message.id) ||
          (msg.tempId != null && msg.tempId == message.tempId),
    );

    if (existingMessageIndex != -1) {
      // Update existing message (useful for updating status of temp messages)
      final updatedList = [...currentData];
      updatedList[existingMessageIndex] = message;
      state = AsyncValue.data(updatedList);
    } else {
      // Add new message
      state = AsyncValue.data([...currentData, message]);
    }
  }

  // Public method to update message (for Realtime integration)
  void updateMessage(MessageModel message) {
    final currentData = state.value ?? [];
    final updatedList = currentData.map((msg) {
      return msg.id == message.id ? message : msg;
    }).toList();
    state = AsyncValue.data(updatedList);
  }

  // Public method to delete message (for Realtime integration)
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
    // 1. Create temporary message for optimistic UI update
    final tempMessage = MessageModel.createTemp(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      messageType: messageType,
    );

    // 2. Add temporary message to UI immediately
    addMessage(tempMessage);

    try {
      // 3. Send message to server
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

      // 4. Create permanent message from server response
      final permanentMessage = MessageModel.fromJson(response).copyWith(
        tempId: tempMessage.tempId, // Keep tempId for replacement
        status: MessageStatus.sent,
      );

      // 5. Replace temporary message with permanent one
      // Note: Realtime will also trigger an insert event, but we handle duplicates in addMessage
      addMessage(permanentMessage);
    } catch (e) {
      // 6. Handle send failure - update message status to failed
      final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
      addMessage(failedMessage);

      // Optionally remove failed message after a delay
      Future.delayed(const Duration(seconds: 5), () {
        final currentData = state.value ?? [];
        final updatedList = currentData
            .where((msg) => msg.uniqueId != tempMessage.uniqueId)
            .toList();
        state = AsyncValue.data(updatedList);
      });

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

      // Update local state immediately (Realtime will also trigger)
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

      // Update local state immediately (Realtime will also trigger)
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

  Future<MessageModel?> getLastMessage({required int conversationId}) async {
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
    _disconnectRealtime();
    state = const AsyncValue.data([]);
  }

  // Disconnect Realtime
  void disconnect() {
    _disconnectRealtime();
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

// Chat List StreamProviders
Future<List<UserModel>> _fetchConversationUsers(
  SupabaseClient supabase,
  String currentUserId,
) async {
  // Get unique users that current user has sent messages to or received messages from
  final response = await supabase
      .from('messages')
      .select('sender_id, receiver_id')
      .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
      .neq('is_deleted', true);

  final Set<String> conversationUserIds = {};
  for (final message in response as List) {
    final senderId = message['sender_id'] as String?;
    final receiverId = message['receiver_id'] as String?;

    if (senderId != null && senderId != currentUserId) {
      conversationUserIds.add(senderId);
    }
    if (receiverId != null && receiverId != currentUserId) {
      conversationUserIds.add(receiverId);
    }
  }

  if (conversationUserIds.isEmpty) return [];

  // Get user details for these conversation users
  final usersResponse = await supabase
      .from('users')
      .select()
      .inFilter('id', conversationUserIds.toList());

  return usersResponse.map((json) => UserModel.fromJson(json)).toList();
}

@riverpod
Stream<List<UserModel>> conversationUsers(Ref ref) async* {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) {
    yield [];
    return;
  }

  final controller = StreamController<List<UserModel>>();
  Timer? refreshTimer;

  Future<void> fetchAndEmit() async {
    try {
      final users = await _fetchConversationUsers(supabase, currentUserId);
      if (!controller.isClosed) {
        controller.add(users);
      }
    } catch (_) {
      if (!controller.isClosed) {
        controller.add([]);
      }
    }
  }

  yield await _fetchConversationUsers(supabase, currentUserId);

  final channel = supabase
      .channel('conversation_users_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'users',
        callback: (_) => fetchAndEmit(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (_) => fetchAndEmit(),
      )
      .subscribe();

  refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    fetchAndEmit();
  });

  ref.onDispose(() {
    supabase.removeChannel(channel);
    refreshTimer?.cancel();
    controller.close();
  });

  await for (final users in controller.stream) {
    yield users;
  }
}

@riverpod
Stream<Map<String, MessageModel>> getLastMessages(Ref ref) async* {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) {
    yield {};
    return;
  }

  // Create a stream controller to handle real-time updates
  final streamController = StreamController<Map<String, MessageModel>>();

  // Initial fetch
  yield await _fetchLastMessages(supabase, currentUserId);

  // Listen to real-time changes
  final channel = supabase
      .channel('last_messages_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) async {
          final newMessages = await _fetchLastMessages(supabase, currentUserId);
          streamController.add(newMessages);
        },
      )
      .subscribe();

  // Listen to the stream controller for updates
  await for (final messages in streamController.stream) {
    yield messages;
  }

  // Cleanup
  ref.onDispose(() {
    supabase.removeChannel(channel);
    streamController.close();
  });
}

@riverpod
Stream<Map<String, int>> getUnreadMessageCounts(Ref ref) async* {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) {
    yield {};
    return;
  }

  // Create a stream controller to handle real-time updates
  final streamController = StreamController<Map<String, int>>();

  // Initial fetch
  yield await _fetchUnreadCounts(supabase, currentUserId);

  // Listen to real-time changes
  final channel = supabase
      .channel('unread_counts_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) async {
          final newCounts = await _fetchUnreadCounts(supabase, currentUserId);
          streamController.add(newCounts);
        },
      )
      .subscribe();

  // Listen to the stream controller for updates
  await for (final counts in streamController.stream) {
    yield counts;
  }

  // Cleanup
  ref.onDispose(() {
    supabase.removeChannel(channel);
    streamController.close();
  });
}

// Helper function to create a unique conversation key
String _getConversationKey(
  String currentUserId,
  String senderId,
  String receiverId,
) {
  final users = [senderId, receiverId]..sort();
  return '${users[0]}_${users[1]}';
}

// Helper function to fetch last messages
Future<Map<String, MessageModel>> _fetchLastMessages(
  SupabaseClient supabase,
  String currentUserId,
) async {
  try {
    final response = await supabase
        .from('messages')
        .select('''
          *,
          conversations!inner(
            name
          )
        ''')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .neq('is_deleted', true)
        .order('created_at', ascending: false);

    final Map<String, MessageModel> lastMessages = {};
    final Set<String> processedConversations = {};

    for (final messageData in response as List) {
      final message = MessageModel.fromJson(messageData);
      final conversationKey = _getConversationKey(
        currentUserId,
        message.senderId,
        message.receiverId,
      );

      if (!processedConversations.contains(conversationKey)) {
        lastMessages[conversationKey] = message;
        processedConversations.add(conversationKey);
      }
    }

    return lastMessages;
  } catch (e) {
    // Error handling without print in production
    return {};
  }
}

// Helper function to fetch unread message counts
Future<Map<String, int>> _fetchUnreadCounts(
  SupabaseClient supabase,
  String currentUserId,
) async {
  try {
    final response = await supabase
        .from('messages')
        .select()
        .eq('receiver_id', currentUserId)
        .neq('is_deleted', true)
        .filter('read_at', 'is', null);

    final Map<String, int> unreadCounts = {};

    for (final messageData in response as List) {
      final message = MessageModel.fromJson(messageData);
      final conversationKey = _getConversationKey(
        currentUserId,
        message.senderId,
        message.receiverId,
      );
      unreadCounts[conversationKey] = (unreadCounts[conversationKey] ?? 0) + 1;
    }

    return unreadCounts;
  } catch (e) {
    // Error handling without print in production
    return {};
  }
}
