import 'package:chat_apps/page/chat_home_page.dart';
import 'package:chat_apps/page/login_page.dart';
import 'package:chat_apps/provider/cache_provider.dart';
import 'package:chat_apps/provider/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await initSupabase();
  runApp(
    ProviderScope(
      overrides: [sharePrefProvider.overrideWithValue(prefs)],
      child: MyApp(prefs: prefs),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      // theme: ThemeData.dark().copyWith(
      //   scaffoldBackgroundColor: const Color(0xFF111827),
      //   primaryColor: const Color(0xFF0D7FF2),
      //   bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      //     backgroundColor: Color(0xFF1F2937),
      //     selectedItemColor: Color(0xFF0D7FF2),
      //     unselectedItemColor: Colors.grey,
      //   ),
      // ),
      home: isLoggedIn ? const ChatHomePage() : const LoginPage(),
      // home: ChatScreen(
      //   userId: '2',
      //   otherUserName: 'MengHeng',
      //   otherUserAvatar: '',
      // ),
    );
  }
}
