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
  String? displayName,
  String? bio,
  String? website,
  String? phoneNumber,
  String? profilePictureUrl,
}) async {
  final userId = ref.read(authProvider);
  if (userId == null) throw Exception('User not authenticated');

  final supabase = ref.read(supabaseProvider);

  final updateData = <String, dynamic>{};
  if (displayName != null) updateData['display_name'] = displayName;
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
FutureOr<UserModel?> currentUser(Ref ref) async {
  final userId = ref.watch(authProvider);
  if (userId == null) return null;

  final user = await getUser(ref, userId);
  // if (user?.active == false) {
  //   await ref.read(authProvider.notifier).signOut();
  //   throw Exception('User is inactive');
  // }

  return user;
}

// Update user profile function
Future<void> updateUserProfile(
  Ref ref, {
  String? displayName,
  String? bio,
  String? website,
  String? phoneNumber,
  String? profilePictureUrl,
}) async {
  final userId = ref.read(authProvider);
  if (userId == null) throw Exception('User not authenticated');

  final supabase = ref.read(supabaseProvider);

  final updateData = <String, dynamic>{};
  if (displayName != null) updateData['display_name'] = displayName;
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
