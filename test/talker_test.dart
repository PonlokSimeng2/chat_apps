import 'package:flutter_test/flutter_test.dart';
import 'package:chat_apps/main.dart';

void main() {
  testWidgets('Talker initialization test', (WidgetTester tester) async {
    // Test that our app can initialize with Talker
    await tester.pumpWidget(MyApp(prefs: null)); // Note: This would need proper setup

    // Verify Talker is initialized
    expect(talker, isNotNull);
  });

  test('Talker error logging test', () {
    // Test that we can log different types of messages
    talker.info('Test info message');
    talker.warning('Test warning message');
    talker.error('Test error message', Exception('Test exception'), StackTrace.current);

    // If we reach here without exceptions, logging is working
    expect(true, isTrue);
  });
}