import 'dart:async';
import 'dart:developer';
import 'package:chat_apps/model/message_reactions_model.dart';
import 'package:chat_apps/provider/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'message_reactions_provider.g.dart';

@riverpod
Stream<List<MessageReactionModel>> messageReactions(Ref ref, int messageId) {
  final supabase = ref.watch(supabaseProvider).client;
  final controller = StreamController<List<MessageReactionModel>>();

  List<MessageReactionModel> currentList = [];

  void emit() {
    if (!controller.isClosed) {
      controller.add([...currentList]);
    }
  }

  final channel = supabase.channel('message_reactions_$messageId')
    ..onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'message_reactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'message_id',
        value: messageId,
      ),
      callback: (payload) {
        try {
          final newReaction = MessageReactionModel.fromJson(payload.newRecord);
          currentList = [
            ...currentList.where((r) => r.userId != newReaction.userId),
            newReaction,
          ];
          log(
            'INSERT reaction: ${newReaction.emoji} | list size: ${currentList.length}',
          );
          emit();
        } catch (e) {
          log('Error handling INSERT: $e');
        }
      },
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'message_reactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'message_id',
        value: messageId,
      ),
      callback: (payload) {
        try {
          // ✅ Log full oldRecord to debug what Supabase sends
          log('DELETE payload.oldRecord: ${payload.oldRecord}');
          log(
            'currentList before delete: ${currentList.map((r) => '${r.id}/${r.userId}/${r.emoji}').toList()}',
          );

          final deletedId = payload.oldRecord['id'] as String?;
          final deletedUserId = payload.oldRecord['user_id'] as String?;

          if (deletedId != null && deletedId.isNotEmpty) {
            currentList = currentList.where((r) => r.id != deletedId).toList();
            log('Removed by id: $deletedId');
          } else if (deletedUserId != null && deletedUserId.isNotEmpty) {
            currentList = currentList
                .where((r) => r.userId != deletedUserId)
                .toList();
            log('Removed by userId: $deletedUserId');
          } else {
            // ✅ Last resort — re-fetch from DB since oldRecord is empty
            log('oldRecord is empty — re-fetching from DB');
            Future.microtask(() async {
              try {
                final data = await supabase
                    .from('message_reactions')
                    .select()
                    .eq('message_id', messageId);
                currentList = (data as List)
                    .map((e) => MessageReactionModel.fromJson(e))
                    .toList();
                log('Re-fetched ${currentList.length} reactions');
                emit();
              } catch (e) {
                log('Error re-fetching reactions: $e');
              }
            });
            return; // emit will be called inside microtask
          }

          log('currentList after delete: ${currentList.length}');
          emit();
        } catch (e) {
          log('Error handling DELETE: $e');
        }
      },
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'message_reactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'message_id',
        value: messageId,
      ),
      callback: (payload) {
        try {
          final updated = MessageReactionModel.fromJson(payload.newRecord);
          currentList = currentList
              .map((r) => r.id == updated.id ? updated : r)
              .toList();
          log('UPDATE reaction: ${updated.emoji}');
          emit();
        } catch (e) {
          log('Error handling UPDATE: $e');
        }
      },
    )
    ..subscribe();

  Future.microtask(() async {
    try {
      final data = await supabase
          .from('message_reactions')
          .select()
          .eq('message_id', messageId);

      currentList = (data as List)
          .map((e) => MessageReactionModel.fromJson(e))
          .toList();

      log(
        'Initial fetch: ${currentList.length} reactions for message $messageId',
      );
      emit();
    } catch (e) {
      log('Error fetching initial reactions: $e');
      emit();
    }
  });

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
    log('Disposed reactions channel for message $messageId');
  });

  return controller.stream;
}

// ============================================
// REACTION ACTIONS
// ============================================

@riverpod
class MessageReactionNotifier extends _$MessageReactionNotifier {
  static const _table = 'message_reactions';

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> reactWithEmoji({
    required int messageId,
    required String emoji,
  }) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.client.auth.currentUser!.id;

      await supabase.client
          .from(_table)
          .upsert(
            MessageReactionModel.insertEmoji(
              messageId: messageId,
              userId: userId,
              emoji: emoji,
            ),
            onConflict: 'message_id,user_id',
          );

      if (!ref.mounted) return;
      log('Reacted with emoji $emoji on message $messageId');
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      log('Error reacting with emoji: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> removeReaction(int messageId) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.client.auth.currentUser!.id;

      final result = await supabase.client
          .from(_table)
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .select(); // ✅ .select() confirms the row was actually deleted

      if (!ref.mounted) return;
      log('Deleted rows: $result');
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      log('Error removing reaction: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleEmojiReaction({
    required int messageId,
    required String emoji,
    required String currentUserId,
  }) async {
    if (!ref.mounted) return;
    try {
      final currentReactions =
          ref.read(messageReactionsProvider(messageId)).value ?? [];

      final myReaction = currentReactions
          .where((r) => r.userId == currentUserId)
          .firstOrNull;

      log(
        'Toggle: myReaction=${myReaction?.emoji}, tapped=$emoji, currentUserId=$currentUserId',
      );

      if (myReaction != null && myReaction.emoji == emoji) {
        log('Same emoji → removing');
        await removeReaction(messageId);
      } else {
        log('New emoji → adding');
        await reactWithEmoji(messageId: messageId, emoji: emoji);
      }
    } catch (e, st) {
      if (!ref.mounted) return;
      log('Error toggling reaction: $e');
      state = AsyncError(e, st);
    }
  }
}
