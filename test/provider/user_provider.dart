import 'dart:typed_data';
import 'package:chat_apps/model/user_model.dart';
import 'package:chat_apps/provider/auth_provider.dart';
import 'package:chat_apps/provider/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'user_provider.g.dart';

// Update user profile function for WidgetRef
Future<void> updateUserProfileWidget(
  WidgetRef ref, {
  String? userName,
  String? bio,
  String? website,
  String? phoneNumber,
  String? profilePictureUrl,
}) async {
  final userId = ref.read(authProvider);
  if (userId == null) throw Exception('User not authenticated');

  final supabase = ref.read(supabaseProvider);

  final updateData = <String, dynamic>{};
  if (userName != null) updateData['display_name'] = userName;
  if (bio != null) updateData['bio'] = bio;
  if (website != null) updateData['website'] = website;
  if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
  if (profilePictureUrl != null)
    updateData['profile_picture_url'] = profilePictureUrl;

  if (updateData.isNotEmpty) {
    updateData['update_at'] = DateTime.now().toIso8601String();

    await supabase.client.from('users').update(updateData).eq('id', userId);

    // Invalidate current user provider to refetch updated data
    ref.invalidate(currentUserProvider);
  }
}

// Upload profile picture function for WidgetRef
Future<String> uploadProfilePictureWidget(
  WidgetRef ref,
  String filePath,
  Uint8List fileBytes,
) async {
  final userId = ref.read(authProvider);
  if (userId == null) throw Exception('User not authenticated');

  final supabase = ref.read(supabaseProvider);

  final fileName =
      '$userId/profile_${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

  await supabase.client.storage
      .from('profile-pictures')
      .uploadBinary(fileName, fileBytes);

  return supabase.client.storage
      .from('profile-pictures')
      .getPublicUrl(fileName);
}

@riverpod
Future<UserModel?> getUser(Ref ref, String userId) async {
  final supabase = ref.read(supabaseProvider);
  final json = await supabase.client
      .from('users')
      .select()
      .eq('id', userId.toString())
      .single();
  return UserModel.fromJson(json);
}

@riverpod
Future<List<UserModel>> getAllUsers(Ref ref) async {
  final supabase = ref.read(supabaseProvider);
  final jsonList = await supabase.client.from('users').select();
  return jsonList.map((json) => UserModel.fromJson(json)).toList();
}

@riverpod
Future<List<UserModel>> getContactUsers(Ref ref) async {
  final userId = ref.watch(authProvider);
  if (userId == null) return [];

  // For now, return empty list since conversation_participants table doesn't exist
  // TODO: Implement when database schema is updated
  return [];
}

@riverpod
FutureOr<UserModel?> currentUser(Ref ref) async {
  final userId = ref.watch(authProvider);
  if (userId == null) {
    return null;
  }

  final user = await getUser(ref, userId);
  // if (user?.active == false) {
  //   await ref.read(authProvider.notifier).signOut();
  //   throw Exception('User is inactive');
  // }

  return user;
}

// Create or get a private conversation between two users
@riverpod
Future<int> createOrGetPrivateConversation(Ref ref, String otherUserId) async {
  final supabase = ref.read(supabaseProvider);
  final currentUserId = ref.watch(authProvider);
  if (currentUserId == null) throw Exception('User not authenticated');

  print(
    '🔐 Creating private conversation between $currentUserId and $otherUserId',
  );

  // Since conversation_participants table doesn't exist, create a unique conversation per user pair
  // Using a hash of user IDs to ensure uniqueness
  final userPair = [currentUserId, otherUserId]..sort();
  final conversationName = 'private_${userPair[0]}_${userPair[1]}';

  // Check if conversation already exists
  final existingConversation = await supabase.client
      .from('conversations')
      .select('id')
      .eq('name', conversationName)
      .maybeSingle();

  if (existingConversation != null) {
    print(
      '✅ Found existing conversation with ID: ${existingConversation['id']}',
    );
    return existingConversation['id'] as int;
  }

  // Create new private conversation
  final newConversation = await supabase.client
      .from('conversations')
      .insert({
        'name': conversationName, // Use conversation name as unique identifier
        'description':
            'Private conversation between $currentUserId and $otherUserId',
        'created_by': currentUserId,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
      .select()
      .single();

  final conversationId = newConversation['id'] as int;

  print('✅ Created private conversation with ID: $conversationId');
  return conversationId;
}

// Update user profile function
Future<void> updateUserProfile(
  Ref ref, {
  String? userName,
  String? bio,
  String? website,
  String? phoneNumber,
  String? profilePictureUrl,
}) async {
  final userId = ref.read(authProvider);
  if (userId == null) throw Exception('User not authenticated');

  final supabase = ref.read(supabaseProvider);

  final updateData = <String, dynamic>{};
  if (userName != null) updateData['display_name'] = userName;
  if (bio != null) updateData['bio'] = bio;
  if (website != null) updateData['website'] = website;
  if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
  if (profilePictureUrl != null)
    updateData['profile_picture_url'] = profilePictureUrl;

  if (updateData.isNotEmpty) {
    updateData['update_at'] = DateTime.now().toIso8601String();

    await supabase.client.from('users').update(updateData).eq('id', userId);

    // Invalidate current user provider to refetch updated data
    ref.invalidate(currentUserProvider);
  }
}

// Upload profile picture function
Future<String> uploadProfilePicture(
  Ref ref,
  String filePath,
  Uint8List fileBytes,
) async {
  final userId = ref.read(authProvider);
  if (userId == null) throw Exception('User not authenticated');

  final supabase = ref.read(supabaseProvider);

  final fileName =
      '$userId/profile_${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

  await supabase.client.storage
      .from('profile-pictures')
      .uploadBinary(fileName, fileBytes);

  return supabase.client.storage
      .from('profile-pictures')
      .getPublicUrl(fileName);
}
