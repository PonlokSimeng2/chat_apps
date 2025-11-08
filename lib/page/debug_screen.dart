import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/error_tracker.dart';
import '../utils/talker_demo.dart';
import '../main.dart';

/// Debug screen to test error tracking functionality
class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Error Testing'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Error Tracking Tests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ErrorTracker.info('Info button pressed'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Log Info Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ErrorTracker.warning('Warning button pressed'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Log Warning Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ErrorTracker.error('Error button pressed'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Log Error Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ErrorTracker.testErrorTracking(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Run Full Error Test'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              '🎨 Colored Talker Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ColoredTalker.info('This is an info message in cyan'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
              child: const Text('Cyan Info Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ColoredTalker.warning('This is a warning in yellow'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow.shade700),
              child: const Text('Yellow Warning Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ColoredTalker.error('This is an error in red'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Red Error Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ColoredTalker.critical('This is critical in bold red'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
              child: const Text('Bold Red Critical Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ColoredTalker.good('This is success in green'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Green Success Message'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: TalkerColorDemo.runAllDemos,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('🌈 Run All Color Demos'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Network Error Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _simulateNetworkError,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: const Text('Simulate Network Error'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _simulateTimeout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text('Simulate Timeout'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'UI Error Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _simulateUIError,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: const Text('Simulate UI Error'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateNetworkError() {
    try {
      ColoredTalker.info('Simulating network error');
      throw Exception('Failed to connect to server: Connection timeout');
    } catch (e, st) {
      ColoredTalker.error('Network operation failed', e, st);
    }
  }

  void _simulateTimeout() {
    try {
      ColoredTalker.warning('Simulating operation timeout');
      throw TimeoutException('Operation timed out after 30 seconds', const Duration(seconds: 30));
    } catch (e, st) {
      ColoredTalker.error('Operation timeout', e, st);
    }
  }

  void _simulateUIError() {
    try {
      ColoredTalker.debug('Simulating UI rendering error');
      throw Exception('Failed to render widget: Missing required data');
    } catch (e, st) {
      ColoredTalker.critical('UI rendering failed', e, st);
    }
  }
}