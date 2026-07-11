import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/conversation_model.dart';

part 'conversation_provider.g.dart';

@Riverpod(keepAlive: true)
class ConversationNotifier extends _$ConversationNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  @override
  AsyncValue<List<ConversationModel>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadUserConversations(String userId) async {
    state = const AsyncValue.loading();

    try {
      // Get conversations where user is either creator or participant
      final response = await _client
          .from('conversations')
          .select('''
            *,
            conversation_participants!inner(
              user_id,
              joined_at
            )
          ''')
          .eq('conversation_participants.user_id', userId)
          .eq('is_active', true)
          .order('updated_at', ascending: false);

      final conversations = (response as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();

      state = AsyncValue.data(conversations);

      // Setup real-time subscription
      _setupRealtimeSubscription(userId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _setupRealtimeSubscription(String userId) {
    _channel?.unsubscribe();

    _channel = _client.channel('conversations:$userId');

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversations',
      callback: (payload) {
        _handleRealtimeUpdate(payload);
      },
    );

    // Listen to conversation participants changes
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversation_participants',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        _handleParticipantChange(payload, userId);
      },
    );

    _channel!.subscribe();
  }

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    final currentData = state.value ?? [];

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final newConversation = ConversationModel.fromJson(payload.newRecord);
        state = AsyncValue.data([newConversation, ...currentData]);
        break;

      case PostgresChangeEvent.update:
        final updatedConversation = ConversationModel.fromJson(payload.newRecord);
        if (updatedConversation.isActive == false) {
          // Remove inactive conversation
          state = AsyncValue.data(
            currentData.where((conv) => conv.id != updatedConversation.id).toList(),
          );
        } else {
          // Update existing conversation
          final updatedList = currentData.map((conv) {
            return conv.id == updatedConversation.id ? updatedConversation : conv;
          }).toList();
          state = AsyncValue.data(updatedList);
        }
        break;

      case PostgresChangeEvent.delete:
        final deletedId = payload.oldRecord['id'] as int;
        final filteredList = currentData.where((conv) => conv.id != deletedId).toList();
        state = AsyncValue.data(filteredList);
        break;
      case PostgresChangeEvent.all:
        // Handle all changes - typically we don't need to do anything here
        // as individual event types are already handled above
        break;
    }
  }

  void _handleParticipantChange(PostgresChangePayload payload, String userId) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        // User was added to a new conversation
        loadUserConversations(userId);
        break;

      case PostgresChangeEvent.delete:
        // User was removed from a conversation
        loadUserConversations(userId);
        break;
      case PostgresChangeEvent.all:
        // Handle all changes - typically we don't need to do anything here
        break;
      case PostgresChangeEvent.update:
        // Handle updates - typically we don't need to do anything here
        break;
    }
  }

  Future<ConversationModel> createConversation({
    required String name,
    required String createdBy,
    String? description,
    List<String>? participantIds,
  }) async {
    try {
      // Create the conversation
      final conversationResponse = await _client
          .from('conversations')
          .insert({
            'name': name,
            'description': description,
            'created_by': createdBy,
            'is_active': true,
          })
          .select()
          .single();

      final conversation = ConversationModel.fromJson(conversationResponse);

      // Add participants if provided
      if (participantIds != null && participantIds.isNotEmpty) {
        final participants = participantIds.map((userId) => {
          'conversation_id': conversation.id,
          'user_id': userId,
          'joined_at': DateTime.now().toIso8601String(),
        }).toList();

        // Also add the creator as a participant
        participants.add({
          'conversation_id': conversation.id,
          'user_id': createdBy,
          'joined_at': DateTime.now().toIso8601String(),
        });

        await _client.from('conversation_participants').insert(participants);
      } else {
        // If no participants specified, add only the creator
        await _client.from('conversation_participants').insert({
          'conversation_id': conversation.id,
          'user_id': createdBy,
          'joined_at': DateTime.now().toIso8601String(),
        });
      }

      return conversation;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  Future<ConversationModel> updateConversation({
    required int conversationId,
    String? name,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      final response = await _client
          .from('conversations')
          .update(updateData)
          .eq('id', conversationId)
          .select()
          .single();

      return ConversationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update conversation: $e');
    }
  }

  Future<void> leaveConversation({
    required int conversationId,
    required String userId,
  }) async {
    try {
      // Remove user from conversation participants
      await _client
          .from('conversation_participants')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to leave conversation: $e');
    }
  }

  Future<void> addParticipant({
    required int conversationId,
    required String userId,
  }) async {
    try {
      await _client.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add participant: $e');
    }
  }

  Future<void> removeParticipant({
    required int conversationId,
    required String userId,
  }) async {
    try {
      await _client
          .from('conversation_participants')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove participant: $e');
    }
  }

  Future<List<ConversationModel>> searchConversations({
    required String userId,
    required String query,
  }) async {
    try {
      final response = await _client
          .from('conversations')
          .select('''
            *,
            conversation_participants!inner(
              user_id,
              joined_at
            )
          ''')
          .eq('conversation_participants.user_id', userId)
          .eq('is_active', true)
          .ilike('name', '%$query%')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search conversations: $e');
    }
  }

  Future<ConversationModel?> getConversationById(int conversationId) async {
    try {
      final response = await _client
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null ? ConversationModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  void refresh() {
    final currentState = state;
    if (currentState is AsyncData && currentState.value != null) {
      // Extract userId from the first conversation's participants or handle differently
      // This is a simplified approach - you might want to store userId differently
      loadUserConversations(_client.auth.currentUser?.id ?? '');
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
    _channel?.unsubscribe();
  }
}

// Provider for individual conversation
@riverpod
class SingleConversationNotifier extends _$SingleConversationNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  AsyncValue<ConversationModel?> build(int conversationId) {
    return const AsyncValue.loading();
  }

  Future<void> loadConversation() async {
    state = const AsyncValue.loading();

    try {
      final response = await _client
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .eq('is_active', true)
          .maybeSingle();

      final conversation = response != null ? ConversationModel.fromJson(response) : null;
      state = AsyncValue.data(conversation);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for conversation participants
@riverpod
class ConversationParticipantsNotifier extends _$ConversationParticipantsNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  AsyncValue<List<Map<String, dynamic>>> build(int conversationId) {
    return const AsyncValue.loading();
  }

  Future<void> loadParticipants() async {
    state = const AsyncValue.loading();

    try {
      final response = await _client
          .from('conversation_participants')
          .select('''
            *,
            users!inner(
              id,
              username,
              avatar_url,
              status
            )
          ''')
          .eq('conversation_id', conversationId);

      state = AsyncValue.data((response as List).cast<Map<String, dynamic>>());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}