import 'dart:developer';
import 'package:chat_apps/model/emoji_model.dart';
import 'package:chat_apps/provider/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'emoji_provider.g.dart';

// ============================================
// FETCH ALL EMOJIS
// ============================================

@riverpod
Future<List<EmojiModel>> emojis(Ref ref) async {
  try {
    final supabase = ref.watch(supabaseProvider);

    final data = await supabase.client
        .from('emojis')
        .select()
        .order('sort_order');

    return (data as List)
        .map((e) => EmojiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    log('Error fetching emojis: $e');
    rethrow;
  }
}

// ============================================
// FETCH EMOJIS GROUPED BY CATEGORY
// ============================================

@riverpod
Future<Map<String, List<EmojiModel>>> emojisByCategory(Ref ref) async {
  try {
    final emojiList = await ref.watch(emojisProvider.future);

    final Map<String, List<EmojiModel>> grouped = {};
    for (final emoji in emojiList) {
      grouped.putIfAbsent(emoji.category, () => []).add(emoji);
    }
    return grouped;
  } catch (e) {
    log('Error grouping emojis by category: $e');
    rethrow;
  }
}

// ============================================
// FETCH EMOJIS BY SINGLE CATEGORY
// ============================================

@riverpod
Future<List<EmojiModel>> emojisBySingleCategory(
  Ref ref,
  String category,
) async {
  try {
    final supabase = ref.watch(supabaseProvider);

    final data = await supabase.client
        .from('emojis')
        .select()
        .eq('category', category)
        .order('sort_order');

    return (data as List)
        .map((e) => EmojiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    log('Error fetching emojis for category $category: $e');
    rethrow;
  }
}

// ============================================
// FETCH ALL CATEGORY NAMES
// ============================================

@riverpod
Future<List<String>> emojiCategories(Ref ref) async {
  try {
    final supabase = ref.watch(supabaseProvider);

    final data = await supabase.client
        .from('emojis')
        .select('category')
        .order('sort_order');

    final categories = (data as List)
        .map((e) => e['category'] as String)
        .toSet()
        .toList();

    return categories;
  } catch (e) {
    log('Error fetching emoji categories: $e');
    rethrow;
  }
}

// ============================================
// SELECTED CATEGORY STATE
// ============================================

@riverpod
class SelectedEmojiCategory extends _$SelectedEmojiCategory {
  @override
  String build() => 'reaction';

  void select(String category) {
    state = category;
  }
}
