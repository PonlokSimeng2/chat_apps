import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/message_model.dart';
import '../model/message_status.dart';
import '../model/user_model.dart';
import '../main.dart';

part 'message_provider.g.dart';

// Helper function to create a unique conversation key
String _getConversationKey(
  String currentUserId,
  String senderId,
  String receiverId,
) {
  final users = [senderId, receiverId]..sort();
  return '${users[0]}_${users[1]}';
}

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
      _disconnectRealtime();

      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        talker.warning('User not authenticated for Realtime subscription');
        return;
      }

      talker.info(
        'Setting up Realtime subscription for conversation $conversationId',
      );

      _channel = _client.channel('messages:conversation:$conversationId');

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
              talker.info('Realtime: New message received');
              _handleInsert(payload);
            },
          )
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
              talker.info('Realtime: Message updated');
              _handleUpdate(payload);
            },
          )
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
              talker.info('Realtime: Message deleted');
              _handleDelete(payload);
            },
          )
          .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              talker.info(
                'Successfully subscribed to conversation $conversationId',
              );
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              talker.warning('Realtime subscription timed out, retrying...');
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

      talker.info(
        'Loaded ${messages.length} messages for conversation $conversationId',
      );
      state = AsyncValue.data(messages);

      _setupRealtimeSubscription(conversationId, receiverId);
    } catch (e, stack) {
      talker.error(
        'Error loading messages for conversation $conversationId',
        e,
        stack,
      );
      state = AsyncValue.error(e, stack);
    }
  }

  void addMessage(MessageModel message) {
    final currentData = state.value ?? [];

    final existingMessageIndex = currentData.indexWhere(
      (msg) =>
          (msg.id != null && msg.id == message.id) ||
          (msg.tempId != null && msg.tempId == message.tempId),
    );

    if (existingMessageIndex != -1) {
      final updatedList = [...currentData];
      updatedList[existingMessageIndex] = message;
      state = AsyncValue.data(updatedList);
    } else {
      state = AsyncValue.data([...currentData, message]);
    }
  }

  void updateMessage(MessageModel message) {
    final currentData = state.value ?? [];
    final updatedList = currentData.map((msg) {
      return msg.id == message.id ? message : msg;
    }).toList();
    state = AsyncValue.data(updatedList);
  }

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
    final tempMessage = MessageModel.createTemp(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      messageType: messageType,
    );

    addMessage(tempMessage);

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

      newMessageData.removeWhere((key, value) => value == null);

      final response = await _client
          .from('messages')
          .insert(newMessageData)
          .select()
          .single();

      final permanentMessage = MessageModel.fromJson(
        response,
      ).copyWith(tempId: tempMessage.tempId, status: MessageStatus.sent);

      addMessage(permanentMessage);
    } catch (e) {
      final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
      addMessage(failedMessage);

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
      talker.warning('Failed to mark message as read: $e');
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
      talker.warning('Failed to mark all messages as read: $e');
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

  void clearMessages() {
    _disconnectRealtime();
    state = const AsyncValue.data([]);
  }

  void disconnect() {
    _disconnectRealtime();
  }

  Future<void> sendImageMessage({
    required int conversationId,
    required String senderId,
    required String receiverId,
    required File imageFile,
  }) async {
    final supabase = Supabase.instance.client;

    final tempMsg = MessageModel.createTemp(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: '📷 Sending image...',
      messageType: 'image',
    );
    state = AsyncData([...state.value ?? [], tempMsg]);

    try {
      final fileName =
          'chat_images/${conversationId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage
          .from('chat-media')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = supabase.storage
          .from('chat-media')
          .getPublicUrl(fileName);

      final response = await supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'receiver_id': receiverId,
            'message_type': 'image',
            'file_url': publicUrl,
            'file_name': fileName,
            'file_size': await imageFile.length(),
            'content': null,
          })
          .select()
          .single();

      final confirmed = MessageModel.fromJson(response);

      state = AsyncData(
        (state.value ?? [])
            .map((m) => m.tempId == tempMsg.tempId ? confirmed : m)
            .toList(),
      );
    } catch (e) {
      state = AsyncData(
        (state.value ?? [])
            .map(
              (m) => m.tempId == tempMsg.tempId
                  ? m.copyWith(status: MessageStatus.failed)
                  : m,
            )
            .toList(),
      );
      rethrow;
    }
  }
}

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

// ─────────────────────────────────────────────
// Chat List Providers
// ─────────────────────────────────────────────

Future<List<UserModel>> _fetchConversationUsers(
  SupabaseClient supabase,
  String currentUserId,
) async {
  // Get all messages involving the current user
  final response = await supabase
      .from('messages')
      .select('sender_id, receiver_id, created_at')
      .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
      .neq('is_deleted', true)
      .order('created_at', ascending: false);

  // Track latest message time per other user
  final Map<String, DateTime> latestMessageTime = {};

  for (final message in response as List) {
    final senderId = message['sender_id'] as String?;
    final receiverId = message['receiver_id'] as String?;
    final createdAt = message['created_at'] != null
        ? DateTime.tryParse(message['created_at'].toString())
        : null;

    final otherId = senderId == currentUserId ? receiverId : senderId;

    if (otherId != null && otherId != currentUserId) {
      if (!latestMessageTime.containsKey(otherId) ||
          (createdAt != null &&
              createdAt.isAfter(latestMessageTime[otherId]!))) {
        latestMessageTime[otherId] = createdAt ?? DateTime(0);
      }
    }
  }

  if (latestMessageTime.isEmpty) return [];

  // Fetch user details
  final usersResponse = await supabase
      .from('users')
      .select()
      .inFilter('id', latestMessageTime.keys.toList());

  final users = (usersResponse as List)
      .map((json) => UserModel.fromJson(json))
      .toList();

  // Sort by latest message time descending
  users.sort((a, b) {
    final timeA = latestMessageTime[a.id] ?? DateTime(0);
    final timeB = latestMessageTime[b.id] ?? DateTime(0);
    return timeB.compareTo(timeA);
  });

  return users;
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

  final streamController = StreamController<Map<String, MessageModel>>();

  yield await _fetchLastMessages(supabase, currentUserId);

  final channel = supabase
      .channel('last_messages_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) async {
          final newMessages = await _fetchLastMessages(supabase, currentUserId);
          if (!streamController.isClosed) {
            streamController.add(newMessages);
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    streamController.close();
  });

  await for (final messages in streamController.stream) {
    yield messages;
  }
}

@riverpod
Stream<Map<String, int>> getUnreadMessageCounts(Ref ref) async* {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) {
    yield {};
    return;
  }

  final streamController = StreamController<Map<String, int>>();

  yield await _fetchUnreadCounts(supabase, currentUserId);

  final channel = supabase
      .channel('unread_counts_$currentUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) async {
          final newCounts = await _fetchUnreadCounts(supabase, currentUserId);
          if (!streamController.isClosed) {
            streamController.add(newCounts);
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    streamController.close();
  });

  await for (final counts in streamController.stream) {
    yield counts;
  }
}

// ─────────────────────────────────────────────
// Helper: fetch last messages
// ─────────────────────────────────────────────
Future<Map<String, MessageModel>> _fetchLastMessages(
  SupabaseClient supabase,
  String currentUserId,
) async {
  try {
    final response = await supabase
        .from('messages')
        .select('*')
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
    talker.error('Error fetching last messages', e);
    return {};
  }
}

// ─────────────────────────────────────────────
// Helper: fetch unread counts
// ─────────────────────────────────────────────
Future<Map<String, int>> _fetchUnreadCounts(
  SupabaseClient supabase,
  String currentUserId,
) async {
  try {
    final response = await supabase
        .from('messages')
        .select('sender_id, receiver_id')
        .eq('receiver_id', currentUserId)
        .neq('is_deleted', true)
        .filter('read_at', 'is', null);

    final Map<String, int> unreadCounts = {};

    for (final messageData in response as List) {
      final senderId = messageData['sender_id'] as String? ?? '';
      final receiverId = messageData['receiver_id'] as String? ?? '';
      final conversationKey = _getConversationKey(
        currentUserId,
        senderId,
        receiverId,
      );
      unreadCounts[conversationKey] = (unreadCounts[conversationKey] ?? 0) + 1;
    }

    return unreadCounts;
  } catch (e) {
    talker.error('Error fetching unread counts', e);
    return {};
  }
}
