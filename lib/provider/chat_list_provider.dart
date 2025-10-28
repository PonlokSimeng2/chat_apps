import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/conversation_model.dart';
import '../model/message_model.dart';
import '../model/user_model.dart';

part 'chat_list_provider.g.dart';

@Riverpod(keepAlive: true)
class ChatListNotifier extends _$ChatListNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  Timer? _refreshTimer;

  @override
  AsyncValue<List<ChatListItem>> build() {
    ref.onDispose(() {
      _channel?.unsubscribe();
      _refreshTimer?.cancel();
    });
    return const AsyncValue.loading();
  }

  Future<void> loadChatList(String userId) async {
    state = const AsyncValue.loading();

    try {
      // Get all data in a single optimized query
      final response = await _client
          .from('conversations')
          .select('''
            id,
            name,
            updated_at,
            conversation_participants!inner(
              user_id,
              users!inner(
                id,
                username,
                email,
                display_name,
                profile_picture_url,
                avatar_url,
                status
              )
            ),
            messages(
              id,
              content,
              sender_id,
              receiver_id,
              created_at,
              is_edited,
              read_at
            ).order(created_at, desc: true).limit(1)
          ''')
          .eq('conversation_participants.user_id', userId)
          .eq('is_active', true)
          .order('updated_at', ascending: false)
          .limit(20); // Limit to prevent too much data

      final chatItems = <ChatListItem>[];
      final conversationIds = <int>[];

      // Process conversations in a single pass
      for (final conversation in response as List) {
        final participants = (conversation['conversation_participants'] as List?)
            ?.map((p) => _parseUserFromParticipant(p))
            .where((user) => user != null)
            .cast<UserModel>()
            .toList() ?? [];

        final otherUser = participants.firstWhere(
          (user) => user.id != userId,
          orElse: () => participants.isNotEmpty ? participants.first : UserModel(
            id: 'unknown',
            username: 'Unknown User',
            email: 'unknown@example.com',
            displayName: 'Unknown User',
          ),
        );

        final messages = conversation['messages'] as List?;
        final lastMessage = messages != null && messages.isNotEmpty
            ? MessageModel.fromJson(messages.first)
            : null;

        chatItems.add(ChatListItem(
          conversation: ConversationModel.fromJson(conversation),
          otherUser: otherUser,
          lastMessage: lastMessage,
          unreadCount: 0, // Will be updated below
        ));

        if (conversation['id'] != null) {
          conversationIds.add(conversation['id'] as int);
        }
      }

      // Get unread counts in a single batch query
      if (conversationIds.isNotEmpty) {
        final unreadCounts = await _getBatchUnreadCounts(conversationIds, userId);

        // Update chat items with unread counts
        for (int i = 0; i < chatItems.length; i++) {
          final conversationId = chatItems[i].conversation.id;
          if (conversationId != null) {
            chatItems[i] = chatItems[i].copyWith(
              unreadCount: unreadCounts[conversationId] ?? 0,
            );
          }
        }
      }

      state = AsyncValue.data(chatItems);

      // Setup real-time subscription
      _setupRealtimeSubscription(userId);

      // Setup periodic refresh for unread counts (less frequent)
      _setupPeriodicRefresh(userId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Helper method to parse user from participant data
  UserModel? _parseUserFromParticipant(Map<String, dynamic> participant) {
    try {
      final userData = participant['users'] as Map<String, dynamic>?;
      if (userData == null) return null;

      return UserModel(
        id: userData['id']?.toString() ?? '',
        username: userData['username']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        displayName: userData['display_name']?.toString() ?? userData['username']?.toString() ?? 'Unknown User',
        profilePictureUrl: userData['profile_picture_url']?.toString() ?? userData['avatar_url']?.toString(),
        isOnline: userData['status']?.toString() == 'online',
      );
    } catch (e) {
      return null;
    }
  }

  // Get unread counts in a single batch query for better performance
  Future<Map<int, int>> _getBatchUnreadCounts(List<int> conversationIds, String userId) async {
    try {
      final unreadCounts = <int, int>{};

      // Process in batches to avoid overwhelming the database
      const batchSize = 10;
      for (int i = 0; i < conversationIds.length; i += batchSize) {
        final batch = conversationIds.skip(i).take(batchSize).toList();

        final response = await _client
            .from('messages')
            .select('conversation_id, id')
            .inFilter('conversation_id', batch)
            .neq('sender_id', userId)
            .eq('is_deleted', false)
            .filter('read_at', 'is', null);

        for (final message in response as List) {
          final conversationId = message['conversation_id'] as int;
          unreadCounts[conversationId] = (unreadCounts[conversationId] ?? 0) + 1;
        }
      }

      return unreadCounts;
    } catch (e) {
      return {};
    }
  }

  
  void _setupRealtimeSubscription(String userId) {
    _channel?.unsubscribe();

    _channel = _client.channel('chat_list:$userId');

    // Listen to new messages
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: userId,
      ),
      callback: (payload) {
        _handleNewMessage(payload.newRecord, userId);
      },
    );

    // Listen to message updates (read receipts)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        _handleMessageUpdate(payload.newRecord, userId);
      },
    );

    // Listen to conversation updates
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'conversations',
      callback: (payload) {
        _handleConversationUpdate(payload.newRecord, userId);
      },
    );

    _channel!.subscribe();
  }

  void _handleNewMessage(Map<String, dynamic> messageData, String currentUserId) {
    final currentData = state.value ?? [];
    final newMessage = MessageModel.fromJson(messageData);
    final conversationId = newMessage.conversationId;

    // Find the chat item for this conversation
    final chatItemIndex = currentData.indexWhere(
      (item) => item.conversation.id == conversationId,
    );

    if (chatItemIndex != -1) {
      final chatItem = currentData[chatItemIndex];

      // Update last message and unread count
      final updatedChatItem = chatItem.copyWith(
        lastMessage: newMessage,
        unreadCount: newMessage.senderId != currentUserId
            ? chatItem.unreadCount + 1
            : chatItem.unreadCount,
      );

      // Move this conversation to the top of the list
      final updatedList = <ChatListItem>[updatedChatItem];
      updatedList.addAll(currentData.where((item) => item.conversation.id != conversationId));

      state = AsyncValue.data(updatedList);
    }
  }

  void _handleMessageUpdate(Map<String, dynamic> messageData, String currentUserId) {
    final currentData = state.value ?? [];
    final updatedMessage = MessageModel.fromJson(messageData);
    final conversationId = updatedMessage.conversationId;

    final chatItemIndex = currentData.indexWhere(
      (item) => item.conversation.id == conversationId,
    );

    if (chatItemIndex != -1) {
      final chatItem = currentData[chatItemIndex];

      // If this is a read receipt for a message received by current user, update unread count
      if (updatedMessage.readAt != null && updatedMessage.receiverId == currentUserId) {
        final newUnreadCount = chatItem.unreadCount > 0 ? chatItem.unreadCount - 1 : 0;

        final updatedChatItem = chatItem.copyWith(
          unreadCount: newUnreadCount,
        );

        final updatedList = [...currentData];
        updatedList[chatItemIndex] = updatedChatItem;

        state = AsyncValue.data(updatedList);
      }
    }
  }

  void _handleConversationUpdate(Map<String, dynamic> conversationData, String currentUserId) {
    // Reload the entire chat list when conversations are updated
    loadChatList(currentUserId);
  }

  void _setupPeriodicRefresh(String userId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      // Refresh unread counts periodically (less frequent to reduce load)
      _refreshUnreadCounts(userId);
    });
  }

  Future<void> _refreshUnreadCounts(String userId) async {
    final currentData = state.value;
    if (currentData == null || currentData.isEmpty) return;

    try {
      // Get conversation IDs for batch update
      final conversationIds = currentData
          .map((item) => item.conversation.id)
          .where((id) => id != null)
          .cast<int>()
          .toList();

      if (conversationIds.isEmpty) return;

      // Get updated unread counts in batch
      final updatedCounts = await _getBatchUnreadCounts(conversationIds, userId);

      // Update chat items with new counts
      final updatedList = currentData.map((chatItem) {
        final conversationId = chatItem.conversation.id;
        if (conversationId != null) {
          return chatItem.copyWith(unreadCount: updatedCounts[conversationId] ?? 0);
        }
        return chatItem.copyWith(unreadCount: 0);
      }).toList();

      state = AsyncValue.data(updatedList);
    } catch (e) {
      // Don't update state on error to avoid UI disruption
      print('Error refreshing unread counts: $e');
    }
  }

  Future<void> markConversationAsRead(int conversationId, String userId) async {
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

      // Update local state
      final currentData = state.value ?? [];
      final chatItemIndex = currentData.indexWhere(
        (item) => item.conversation.id == conversationId,
      );

      if (chatItemIndex != -1) {
        final updatedList = [...currentData];
        updatedList[chatItemIndex] = currentData[chatItemIndex].copyWith(unreadCount: 0);
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Don't throw error for read receipts as they're not critical
      print('Failed to mark conversation as read: $e');
    }
  }

  void refresh() {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      loadChatList(userId);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
    _channel?.unsubscribe();
    _refreshTimer?.cancel();
  }
}

class ChatListItem {
  final ConversationModel conversation;
  final UserModel otherUser;
  final MessageModel? lastMessage;
  final int unreadCount;

  ChatListItem({
    required this.conversation,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  ChatListItem copyWith({
    ConversationModel? conversation,
    UserModel? otherUser,
    MessageModel? lastMessage,
    int? unreadCount,
  }) {
    return ChatListItem(
      conversation: conversation ?? this.conversation,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}