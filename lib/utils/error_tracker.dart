import '../main.dart';

/// Utility class for centralized error tracking
class ErrorTracker {
  /// Log an informational message
  static void info(String message) {
    talker.info(message);
  }

  /// Log a warning message
  static void warning(String message) {
    talker.warning(message);
  }

  /// Log a debug message
  static void debug(String message) {
    talker.debug(message);
  }

  /// Log an error with optional exception and stack trace
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    talker.error(message, error, stackTrace);
  }

  /// Log an exception with context
  static void handleException(
    String context,
    Object exception,
    StackTrace stackTrace,
  ) {
    talker.error('$context: ${exception.toString()}', exception, stackTrace);
  }

  /// Test method to verify error tracking is working
  static void testErrorTracking() {
    info('Testing error tracking system');
    debug('This is a debug message');
    warning('This is a warning message');

    try {
      throw Exception('This is a test exception');
    } catch (e, st) {
      error('Test exception caught', e, st);
    }

    info('Error tracking test completed');
  }
}