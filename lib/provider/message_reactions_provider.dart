import 'dart:developer';
import 'package:chat_apps/model/message_reactions_model.dart';
import 'package:chat_apps/provider/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_reactions_provider.g.dart';

// ============================================
// WATCH REACTIONS FOR A MESSAGE (Realtime)
// ============================================

@riverpod
Stream<List<MessageReactionModel>> messageReactions(Ref ref, int messageId) {
  try {
    final supabase = ref.watch(supabaseProvider);

    return supabase.client
        .from('message_reactions')
        .stream(primaryKey: ['id'])
        .eq('message_id', messageId)
        .map(
          (data) => data.map((e) => MessageReactionModel.fromJson(e)).toList(),
        );
  } catch (e) {
    log('Error watching reactions for message $messageId: $e');
    rethrow;
  }
}

// ============================================
// REACTION ACTIONS (add / remove)
// ============================================

@riverpod
class MessageReactionNotifier extends _$MessageReactionNotifier {
  static const _table = 'message_reactions';

  @override
  AsyncValue<void> build() => const AsyncData(null);

  // React with emoji
  Future<void> reactWithEmoji({
    required int messageId,
    required String emoji,
  }) async {
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

      log('Reacted with emoji $emoji on message $messageId');
      state = const AsyncData(null);
    } catch (e, st) {
      log('Error reacting with emoji: $e');
      state = AsyncError(e, st);
    }
  }

  // Remove reaction
  Future<void> removeReaction(int messageId) async {
    state = const AsyncLoading();
    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.client.auth.currentUser!.id;

      await supabase.client
          .from(_table)
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);

      log('Removed reaction from message $messageId');
      state = const AsyncData(null);
    } catch (e, st) {
      log('Error removing reaction: $e');
      state = AsyncError(e, st);
    }
  }

  // Toggle — remove if same emoji, replace if different
  Future<void> toggleEmojiReaction({
    required int messageId,
    required String emoji,
    required String currentUserId,
    required List<MessageReactionModel> currentReactions,
  }) async {
    try {
      final myReaction = currentReactions
          .where((r) => r.userId == currentUserId)
          .firstOrNull;

      if (myReaction != null && myReaction.emoji == emoji) {
        // Same emoji → remove
        await removeReaction(messageId);
      } else {
        // Different or no reaction → upsert
        await reactWithEmoji(messageId: messageId, emoji: emoji);
      }
    } catch (e, st) {
      log('Error toggling reaction: $e');
      state = AsyncError(e, st);
    }
  }
}
