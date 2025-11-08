import '../main.dart';

/// Demonstration of Talker color usage
class TalkerColorDemo {
  /// Run all color demonstrations
  static void runAllDemos() {
    ColoredTalker.info('This is an info message in cyan color ℹ️');
    ColoredTalker.warning('This is a warning message in yellow color ⚠️');
    ColoredTalker.error('This is an error message in red color 🔴');
    ColoredTalker.critical('This is a critical error message in bold red 🚨');
    ColoredTalker.debug('This is a debug message in white color 🐛');
    ColoredTalker.good('This is a success message in green color ✅');
  }

  /// Simulate different error scenarios with colors
  static void simulateErrorScenarios() {
    // Network error scenario
    ColoredTalker.error('Network request failed');

    // Authentication error
    ColoredTalker.error('Authentication failed: Invalid credentials');

    // Critical system error
    ColoredTalker.critical('Database connection lost');

    // Warning scenario
    ColoredTalker.warning('Slow network connection detected');

    // Info scenario
    ColoredTalker.info('User logged in successfully');

    // Debug scenario
    ColoredTalker.debug('Loading user data from cache');

    // Success scenario
    ColoredTalker.good('Message sent successfully');
  }

  /// Test error with exceptions and stack traces
  static void testErrorsWithExceptions() {
    try {
      // Simulate a division by zero error
      final result = 10 ~/ 0;
      ColoredTalker.info('Result: $result');
    } catch (e, st) {
      ColoredTalker.error('Math calculation failed', e, st);
    }

    try {
      // Simulate a null reference error
      String? nullableString;
      final length = nullableString!.length;
      ColoredTalker.info('String length: $length');
    } catch (e, st) {
      ColoredTalker.critical('Null reference error detected', e, st);
    }
  }

  /// Demonstrate API call error handling
  static void simulateApiErrors() {
    // Simulate different API errors
    ColoredTalker.error('API call failed: 404 Not Found');
    ColoredTalker.warning('API rate limit approaching');
    ColoredTalker.error('API timeout: Request took too long');
    ColoredTalker.critical('API key expired - cannot make requests');
    ColoredTalker.good('API call successful');
  }

  /// Demonstrate chat-specific errors
  static void simulateChatErrors() {
    ColoredTalker.error('Failed to send message');
    ColoredTalker.warning('Message delivered but not read');
    ColoredTalker.error('Realtime connection lost');
    ColoredTalker.critical('Chat server unavailable');
    ColoredTalker.info('New message received');
    ColoredTalker.good('Message delivered successfully');
  }
}