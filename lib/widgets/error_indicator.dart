import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/error_provider.dart';

/// Visual error indicator widget
class ErrorIndicator extends ConsumerWidget {
  const ErrorIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(errorProvider);
    final errorNotifier = ref.read(errorProvider.notifier);

    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      right: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: errors.map((error) => _ErrorCard(
          error: error,
          onClose: () => errorNotifier.removeError(error),
        )).toList(),
      ),
    );
  }
}

/// Individual error card widget
class _ErrorCard extends StatelessWidget {
  final ErrorInfo error;
  final VoidCallback onClose;

  const _ErrorCard({
    required this.error,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(error.severity),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        maxWidth: 300,
        minWidth: 200,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(error.severity),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTitle(error.severity),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          if (error.message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              error.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (error.details != null && error.details!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              error.details!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatTime(error.timestamp),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue.shade600;
      case ErrorSeverity.warning:
        return Colors.orange.shade600;
      case ErrorSeverity.error:
        return Colors.red.shade600;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  String _getTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'Info';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical';
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

/// Floating error button for the app bar
class ErrorFab extends ConsumerWidget {
  const ErrorFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(errorProvider);
    final errorCount = errors.length;

    if (errorCount == 0) {
      return const SizedBox.shrink();
    }

    final hasCritical = errors.any((e) => e.severity == ErrorSeverity.critical);
    final hasErrors = errors.any((e) => e.severity == ErrorSeverity.error);

    return FloatingActionButton.extended(
      onPressed: () => _showErrorDialog(context, ref),
      backgroundColor: hasCritical
          ? Colors.red.shade900
          : hasErrors
              ? Colors.red.shade600
              : Colors.orange.shade600,
      icon: Icon(
        hasCritical ? Icons.dangerous : Icons.error_outline,
        color: Colors.white,
        size: 20,
      ),
      label: Text(
        errorCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, WidgetRef ref) {
    final errors = ref.read(errorProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text('Errors (${errors.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: errors.isEmpty
              ? const Center(child: Text('No errors'))
              : ListView.builder(
                  itemCount: errors.length,
                  itemBuilder: (context, index) {
                    final error = errors[index];
                    return Card(
                      color: _getCardColor(error.severity),
                      child: ListTile(
                        leading: Icon(
                          _getCardIcon(error.severity),
                          color: Colors.white,
                        ),
                        title: Text(
                          error.message,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (error.details != null)
                              Text(
                                error.details!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            Text(
                              _formatDialogTime(error.timestamp),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            ref.read(errorProvider.notifier).removeError(error);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(errorProvider.notifier).clearErrors();
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getCardColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue.shade600;
      case ErrorSeverity.warning:
        return Colors.orange.shade600;
      case ErrorSeverity.error:
        return Colors.red.shade600;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getCardIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  String _formatDialogTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}