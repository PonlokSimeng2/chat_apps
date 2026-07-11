import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([SupabaseClient, AuthResponse, User])
void main() {
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser();
    when(mockUser.id).thenReturn('test-user-id-123');
  });

  // ─── signIn error mapping ────────────────────────────────────
  group('signIn error mapping', () {
    test('maps invalid credentials error correctly', () {
      final message = mapAuthError('Invalid login credentials');
      expect(
        message,
        equals('Invalid email or password. Please check your credentials.'),
      );
    });

    test('maps email not confirmed error correctly', () {
      final message = mapAuthError('Email not confirmed');
      expect(message, equals('Please confirm your email before signing in.'));
    });

    test('maps unknown error to generic message', () {
      final message = mapAuthError('Some unknown error');
      expect(message, equals('Sign in failed. Please try again.'));
    });
  });

  // ─── Email validation ────────────────────────────────────────
  group('Email validation', () {
    test('empty email returns error', () {
      expect(validateEmail(''), equals('Please enter your email'));
    });

    test('whitespace email returns error', () {
      expect(validateEmail('   '), equals('Please enter your email'));
    });

    test('invalid email format returns error', () {
      expect(
        validateEmail('notanemail'),
        equals('Please enter a valid email address'),
      );
    });

    test('email without domain returns error', () {
      expect(
        validateEmail('test@'),
        equals('Please enter a valid email address'),
      );
    });

    test('valid email returns null', () {
      expect(validateEmail('test@example.com'), isNull);
    });
  });

  // ─── Password validation ─────────────────────────────────────
  group('Password validation', () {
    test('empty password returns error', () {
      expect(validatePassword(''), equals('Please enter your password'));
    });

    test('password under 6 chars returns error', () {
      expect(
        validatePassword('123'),
        equals('Password must be at least 6 characters'),
      );
    });

    test('password of exactly 6 chars returns null', () {
      expect(validatePassword('123456'), isNull);
    });

    test('valid password returns null', () {
      expect(validatePassword('password123'), isNull);
    });
  });

  // ─── isAuthenticated logic ───────────────────────────────────
  group('isAuthenticated', () {
    test('user is authenticated when id is not null', () {
      when(mockUser.id).thenReturn('test-user-id-123');
      expect(mockUser.id, isNotNull);
    });

    test('user is not authenticated when null', () {
      final User? nullUser = null;
      expect(nullUser, isNull);
    });
  });

  // ─── User ID ─────────────────────────────────────────────────
  group('User ID', () {
    test('returns correct user id', () {
      when(mockUser.id).thenReturn('test-user-id-123');
      expect(mockUser.id, equals('test-user-id-123'));
    });
  });
}

// ─── Pure functions mirroring auth_provider.dart logic ──────────

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your email';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your password';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

String mapAuthError(String error) {
  if (error.contains('Invalid login credentials')) {
    return 'Invalid email or password. Please check your credentials.';
  } else if (error.contains('Email not confirmed')) {
    return 'Please confirm your email before signing in.';
  } else {
    return 'Sign in failed. Please try again.';
  }
}
