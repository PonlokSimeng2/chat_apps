import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_indicator.dart';

/// Wrapper widget that includes error indicators for any screen
class AppWrapper extends ConsumerWidget {
  final Widget child;

  const AppWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          // Error indicators positioned at the top right
          const ErrorIndicator(),
        ],
      ),
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 80), // Avoid bottom nav bar
        child: ErrorFab(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}

/// Simple wrapper for full-screen pages
class FullScreenWrapper extends ConsumerWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;

  const FullScreenWrapper({
    super.key,
    required this.child,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
              backgroundColor: const Color(0xFF1F2937),
              foregroundColor: Colors.white,
            )
          : null,
      body: Stack(
        children: [
          child,
          const ErrorIndicator(),
        ],
      ),
      floatingActionButton: const ErrorFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}