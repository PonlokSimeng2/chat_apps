import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/error_provider.dart';

/// Demo button to test error tracking functionality
class ErrorDemoButton extends ConsumerWidget {
  const ErrorDemoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showErrorDemo(context, ref),
      backgroundColor: Colors.red.shade600,
      child: const Icon(Icons.bug_report, color: Colors.white),
    );
  }

  void _showErrorDemo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2937),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Error Testing Demo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test different error scenarios to see the visual feedback:',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildErrorButton(
              context,
              ref,
              'Info Message',
              Colors.blue,
              () => ref.read(errorProvider.notifier).addError(
                'This is an info message',
                severity: ErrorSeverity.info,
              ),
            ),
            _buildErrorButton(
              context,
              ref,
              'Warning Message',
              Colors.orange,
              () => ref.read(errorProvider.notifier).addError(
                'This is a warning message',
                details: 'Something might be wrong',
                severity: ErrorSeverity.warning,
              ),
            ),
            _buildErrorButton(
              context,
              ref,
              'Error Message',
              Colors.red,
              () => ref.read(errorProvider.notifier).addError(
                'This is an error message',
                details: 'Something went wrong',
                severity: ErrorSeverity.error,
              ),
            ),
            _buildErrorButton(
              context,
              ref,
              'Critical Error',
              Colors.red.shade900,
              () => ref.read(errorProvider.notifier).addError(
                'This is a critical error',
                details: 'The app may crash soon!',
                severity: ErrorSeverity.critical,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      ref.read(errorProvider.notifier).clearErrors();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}