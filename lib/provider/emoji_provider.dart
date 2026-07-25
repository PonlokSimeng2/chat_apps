import 'dart:developer';
import 'package:chat_apps/model/emoji_model.dart';
import 'package:chat_apps/provider/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'emoji_provider.g.dart';

// ============================================
// FETCH ALL EMOJIS
// ============================================

// ============================================
// FETCH EMOJIS GROUPED BY CATEGORY
// ============================================

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
