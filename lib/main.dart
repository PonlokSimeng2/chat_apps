import 'package:chat_apps/page/chat_home_page.dart';
import 'package:chat_apps/page/login_page.dart';
import 'package:chat_apps/provider/cache_provider.dart';
import 'package:chat_apps/provider/supabase_provider.dart';
import 'package:chat_apps/widgets/error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

// Enhanced Talker with custom logging methods and colors
class ColoredTalker {
  static const reset = '\x1B[0m';

  // ANSI Color codes
  static const red = '\x1B[31m';
  static const boldRed = '\x1B[1;31m';
  static const yellow = '\x1B[33m';
  static const cyan = '\x1B[36m';
  static const green = '\x1B[32m';
  static const white = '\x1B[37m';

  static void info(String message) {
    print('$cyanℹ️ INFO: $message$reset');
    talker.info(message);
  }

  static void warning(String message) {
    print('$yellow⚠️ WARNING: $message$reset');
    talker.warning(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('$red🔴 ERROR: $message$reset');
    if (error != null) print('$red  Details: $error$reset');
    if (stackTrace != null) print('$red  Stack: $stackTrace$reset');
    talker.error(message, error, stackTrace);
  }

  static void critical(String message, [Object? error, StackTrace? stackTrace]) {
    print('$boldRed🚨 CRITICAL: $message$reset');
    if (error != null) print('$boldRed  Details: $error$reset');
    if (stackTrace != null) print('$boldRed  Stack: $stackTrace$reset');
    talker.error('CRITICAL: $message', error, stackTrace);
  }

  static void debug(String message) {
    print('$white🐛 DEBUG: $message$reset');
    talker.debug(message);
  }

  static void good(String message) {
    print('$green✅ SUCCESS: $message$reset');
    // Use info as fallback since good method doesn't exist
    talker.info('SUCCESS: $message');
  }
}

// Configure Talker with basic settings
final talker = Talker(
  settings: TalkerSettings(
    enabled: true,
    useConsoleLogs: true,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    await initSupabase();

    ColoredTalker.good('Application starting up successfully');

    runApp(
      ProviderScope(
        overrides: [sharePrefProvider.overrideWithValue(prefs)],
        child: MyApp(prefs: prefs),
      ),
    );
  } catch (e, st) {
    ColoredTalker.critical('Application startup failed', e, st);

    // Show error in debug mode
    if (!const bool.fromEnvironment('dart.vm.product')) {
      runApp(
        ProviderScope(
          child: MaterialApp(
            home: ErrorScreen(
              title: 'Startup Error',
              error: e.toString(),
              details: st.toString(),
            ),
          ),
        ),
      );
    }
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    try {
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      ColoredTalker.info('Building app with login status: $isLoggedIn');

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chat App',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF111827),
          primaryColor: const Color(0xFF0D7FF2),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1F2937),
            selectedItemColor: Color(0xFF0D7FF2),
            unselectedItemColor: Colors.grey,
          ),
        ),
        home: isLoggedIn ? const ChatHomePage() : const LoginPage(),
        builder: (context, child) {
          return TalkerWrapper(
            talker: talker,
            child: child!,
          );
        },
      );
    } catch (e, st) {
      ColoredTalker.error('Error building app', e, st);
      rethrow;
    }
  }
}
