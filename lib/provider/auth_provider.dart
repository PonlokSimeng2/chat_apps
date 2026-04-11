import 'dart:developer';
import 'package:chat_apps/provider/supabase_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  String? _lastOneSignalUserId;
  bool _oneSignalObserverRegistered = false;

  @override
  String? build() {
    final session = ref.watch(supabaseProvider).client.auth.currentSession;
    if (session == null) return null;
    _queueOneSignalSync(session.user.id);
    return session.user.id;
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      talker.info('Starting signup process for email: $email');
      final supabase = ref.read(supabaseProvider);

      // Check if username exists
      final existingUsername = await supabase.client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        talker.warning('Username already taken: $username');
        return "Username already taken";
      }

      // Create Supabase Auth user
      final authResult = await supabase.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        final userId = authResult.user!.id;
        talker.info('Created auth user with ID: $userId');

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
        talker.info('Created user record for: $username');

        // Auto-login
        final signInResult = await supabase.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (signInResult.user != null) {
          state = signInResult.user!.id;
          _queueOneSignalSync(signInResult.user!.id);
          talker.info('Auto-login successful for: $username');
          return null; // Success
        }
      }

      return "Registration failed";
    } catch (e, st) {
      talker.error('Signup error', e, st);
      log("Signup error: $e");
      return "Registration failed. Please try again.";
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      talker.info('Starting sign in process for email: $email');
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
          talker.info('Updated online status for user: ${result.user!.id}');
        } catch (updateError) {
          talker.error('Error updating online status', updateError);
          log("Error updating online status: $updateError");
          // Don't fail the login just because we couldn't update online status
        }

        state = result.user!.id;
        _queueOneSignalSync(result.user!.id);
        talker.info('Sign in successful for user: ${result.user!.id}');
        return null; // Success - moved inside the success condition
      } else {
        talker.warning('Sign in failed: No user returned');
        return "Login failed: No user returned";
      }
    } catch (e, st) {
      talker.error('Sign in error', e, st);
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
    final supabase = ref.read(supabaseProvider).client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await supabase
            .from('users')
            .update({
              'is_online': false,
              'onesignal_subscription_id': null, // ✅ clear subscription ID
              'last_seen_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      } catch (e, st) {
        talker.warning('Failed to update on sign out', e, st);
      }
    }

    // ✅ Reset trackers so next user gets fresh sync
    _lastOneSignalUserId = null;
    _oneSignalObserverRegistered = false;

    await supabase.auth.signOut();
    OneSignal.logout();
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

  void _queueOneSignalSync(String userId) {
    if (_lastOneSignalUserId == userId) return;
    _lastOneSignalUserId = userId;
    Future.microtask(() => _syncOneSignalSubscriptionId(userId));
  }

  Future<void> _syncOneSignalSubscriptionId(String userId) async {
    final supabase = ref.read(supabaseProvider).client;
    try {
      OneSignal.login(userId);
    } catch (e, st) {
      talker.warning('OneSignal login failed', e, st);
    }

    final permissionGranted = await OneSignal.Notifications.requestPermission(
      true,
    );
    if (!permissionGranted) {
      talker.warning('Notifications permission not granted');
    }

    String? subId = OneSignal.User.pushSubscription.id;
    if (subId == null || subId.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      subId = OneSignal.User.pushSubscription.id;
    }
    if (subId != null && subId.isNotEmpty) {
      await _updateOneSignalSubscriptionId(supabase, userId, subId);
      return;
    }

    if (_oneSignalObserverRegistered) return;
    _oneSignalObserverRegistered = true;
    OneSignal.User.pushSubscription.addObserver((state) async {
      final currentUserId = supabase.auth.currentUser?.id;
      final currentSubId = state.current.id;
      if (currentUserId == null ||
          currentSubId == null ||
          currentSubId.isEmpty) {
        return;
      }
      await _updateOneSignalSubscriptionId(
        supabase,
        currentUserId,
        currentSubId,
      );
    });
  }

  Future<void> _updateOneSignalSubscriptionId(
    SupabaseClient client,
    String userId,
    String subId,
  ) async {
    try {
      await client
          .from('users')
          .update({'onesignal_subscription_id': subId})
          .eq('id', userId);
      talker.info('Saved OneSignal subscription id for user: $userId');
    } catch (e, st) {
      talker.error('Failed to save OneSignal subscription id', e, st);
    }
  }
}
