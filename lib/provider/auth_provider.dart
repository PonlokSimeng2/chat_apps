import 'dart:developer';
import 'package:chat_app/provider/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  String? build() {
    final session = ref.watch(supabaseProvider).client.auth.currentSession;
    if (session == null) return null;
    return session.user.id;
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final supabase = ref.read(supabaseProvider);

      // Check if username exists
      final existingUsername = await supabase.client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        return "Username already taken";
      }

      // Create Supabase Auth user
      final authResult = await supabase.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        final userId = authResult.user!.id;

        // Create user record - MUST match your table columns
        final userRecord = {
          'id': userId,
          'username': username,
          'email': email,
          'display_name': displayName,
          'phone_number': '', // Add default phone if your table requires it
          'is_online': true,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'last_seen_at': DateTime.now().toIso8601String(),
        };

        await supabase.client.from('users').insert(userRecord);

        // Auto-login
        final signInResult = await supabase.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (signInResult.user != null) {
          state = signInResult.user!.id;
          return null; // Success
        }
      }

      return "Registration failed";
    } catch (e) {
      log("Signup error: $e");
      return "Registration failed. Please try again.";
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final supabase = ref.read(supabaseProvider);

      final result = await supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Update online status in your users table
        try {
          await supabase.client
              .from('users')
              .update({
                'is_online': true,
                'last_seen_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', result.user!.id);
        } catch (updateError) {
          log("Error updating online status: $updateError");
          // Don't fail the login just because we couldn't update online status
        }

        state = result.user!.id;
        return null; // Success - moved inside the success condition
      } else {
        return "Login failed: No user returned";
      }
    } catch (e) {
      log("Error sign in: $e");

      if (e.toString().contains('Invalid login credentials')) {
        return "Invalid email or password. Please check your credentials.";
      } else if (e.toString().contains('Email not confirmed')) {
        return "Please confirm your email before signing in.";
      } else {
        return "Sign in failed. Please try again.";
      }
    }
  }

  Future<void> signOut() async {
    await ref.read(supabaseProvider).client.auth.signOut();
    ref.invalidateSelf();
  }

  Future<String?> resendOtp(String email) async {
    try {
      final supabase = ref.read(supabaseProvider);

      await supabase.client.auth.resend(type: OtpType.signup, email: email);

      return null; // Success
    } catch (e) {
      log("Error resending OTP: $e");
      return "Failed to resend verification email. Please try again.";
    }
  }

  // Helper method to get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final userId = state;
      if (userId == null) return null;

      final supabase = ref.read(supabaseProvider);
      final userData = await supabase.client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      return userData;
    } catch (e) {
      log("Error getting user data: $e");
      return null;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final supabase = ref.read(supabaseProvider);
      final result = await supabase.client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      return result == null; // Available if no result found
    } catch (e) {
      log("Error checking username availability: $e");
      return false; // Assume not available on error
    }
  }

  // Update user profile
  Future<String?> updateProfile({
    String? displayName,
    String? bio,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    try {
      final userId = state;
      if (userId == null) return "User not authenticated";

      final supabase = ref.read(supabaseProvider);

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (profilePictureUrl != null)
        updates['profile_picture_url'] = profilePictureUrl;

      await supabase.client.from('users').update(updates).eq('id', userId);

      return null; // Success
    } catch (e) {
      log("Error updating profile: $e");
      return "Failed to update profile. Please try again.";
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => state != null;

  // Get current user ID
  String? get currentUserId => state;
}
