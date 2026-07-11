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
    if (!controller.isClosed) controller.add([...currentList]);
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
          emit();
        } catch (e) {
          log('Error handling INSERT reaction: $e');
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
          final deletedId = payload.oldRecord['id'] as String?;
          final deletedUserId = payload.oldRecord['user_id'] as String?;

          if (deletedId != null && deletedId.isNotEmpty) {
            currentList = currentList.where((r) => r.id != deletedId).toList();
          } else if (deletedUserId != null && deletedUserId.isNotEmpty) {
            currentList = currentList
                .where((r) => r.userId != deletedUserId)
                .toList();
          } else {
            // Fallback re-fetch
            Future.microtask(() async {
              try {
                final data = await supabase
                    .from('message_reactions')
                    .select()
                    .eq('message_id', messageId);
                currentList = (data as List)
                    .map((e) => MessageReactionModel.fromJson(e))
                    .toList();
                emit();
              } catch (e) {
                log('Error re-fetching reactions: $e');
              }
            });
            return;
          }
          emit();
        } catch (e) {
          log('Error handling DELETE reaction: $e');
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
          emit();
        } catch (e) {
          log('Error handling UPDATE reaction: $e');
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
      emit();
    } catch (e) {
      log('Error fetching initial reactions: $e');
      emit();
    }
  });

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
}

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

      await supabase.client
          .from(_table)
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);

      if (!ref.mounted) return;
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

      if (myReaction != null && myReaction.emoji == emoji) {
        await removeReaction(messageId);
      } else {
        await reactWithEmoji(messageId: messageId, emoji: emoji);
      }
    } catch (e, st) {
      if (!ref.mounted) return;
      log('Error toggling reaction: $e');
      state = AsyncError(e, st);
    }
  }
}
