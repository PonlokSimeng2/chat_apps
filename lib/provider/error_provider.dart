import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../main.dart';

/// Error message model
class ErrorInfo {
  final String message;
  final String? details;
  final DateTime timestamp;
  final ErrorSeverity severity;

  ErrorInfo({
    required this.message,
    this.details,
    required this.timestamp,
    this.severity = ErrorSeverity.error,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorInfo &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          details == other.details &&
          timestamp == other.timestamp &&
          severity == other.severity;

  @override
  int get hashCode =>
      message.hashCode ^
      details.hashCode ^
      timestamp.hashCode ^
      severity.hashCode;
}

/// Error severity levels
enum ErrorSeverity { info, warning, error, critical }

/// Error state management provider
final errorProvider = StateNotifierProvider<ErrorNotifier, List<ErrorInfo>>((
  ref,
) {
  return ErrorNotifier();
});

class ErrorNotifier extends StateNotifier<List<ErrorInfo>> {
  ErrorNotifier() : super([]);

  /// Add a new error to the state
  void addError(
    String message, {
    String? details,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final error = ErrorInfo(
      message: message,
      details: details,
      timestamp: DateTime.now(),
      severity: severity,
    );

    state = [error, ...state.take(9)]; // Keep only last 10 errors

    // Auto-remove errors after 5 seconds for non-critical errors
    if (severity != ErrorSeverity.critical) {
      Future.delayed(const Duration(seconds: 5), () {
        if (state.contains(error)) {
          state = state.where((e) => e != error).toList();
        }
      });
    }
  }

  /// Remove a specific error
  void removeError(ErrorInfo error) {
    state = state.where((e) => e != error).toList();
  }

  /// Clear all errors
  void clearErrors() {
    state = [];
  }

  /// Get errors by severity
  List<ErrorInfo> getErrorsBySeverity(ErrorSeverity severity) {
    return state.where((error) => error.severity == severity).toList();
  }

  /// Get the most recent error
  ErrorInfo? get latestError => state.isNotEmpty ? state.first : null;

  /// Check if there are any critical errors
  bool get hasCriticalErrors =>
      state.any((e) => e.severity == ErrorSeverity.critical);

  /// Check if there are any errors
  bool get hasErrors => state.isNotEmpty;
}

/// Enhanced Talker integration with visual feedback
class VisualTalker {
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    // Log to Talker
    switch (severity) {
      case ErrorSeverity.info:
        talker.info(message);
        break;
      case ErrorSeverity.warning:
        talker.warning(message);
        break;
      case ErrorSeverity.error:
        talker.error(message, error, stackTrace);
        break;
      case ErrorSeverity.critical:
        talker.error('CRITICAL: $message', error, stackTrace);
        break;
    }
  }

  static void logInfo(String message) {
    logError(message, severity: ErrorSeverity.info);
  }

  static void logWarning(String message) {
    logError(message, severity: ErrorSeverity.warning);
  }

  static void logCritical(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    logError(
      message,
      error: error,
      stackTrace: stackTrace,
      severity: ErrorSeverity.critical,
    );
  }
}
