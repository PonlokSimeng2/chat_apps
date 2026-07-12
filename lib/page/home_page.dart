import 'package:chat_apps/page/contact_page.dart';
import 'package:chat_apps/page/list_page.dart';
import 'package:chat_apps/page/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_apps/utils/responsive_helper.dart';
import 'package:flutter_riverpod/legacy.dart';

// Providers
final selectedTabProvider = StateProvider<int>((ref) => 0);

final searchQueryProvider = StateProvider<String>((ref) => '');

// Main App
class ChatHomePage extends StatelessWidget {
  const ChatHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatHomeScreen();
  }
}

// Main Screen
class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    // Use ResponsiveHelper for breakpoint detection
    if (ResponsiveHelper.shouldUseNavigationRail(context)) {
      return Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: SafeArea(
          child: Row(
            children: [
              // Navigation Rail for desktop
              NavigationRail(
                selectedIndex: selectedTab,
                onDestinationSelected: (index) =>
                    ref.read(selectedTabProvider.notifier).state = index,
                backgroundColor: const Color(0xFF1F2937),
                extended: true,
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: const IconThemeData(
                  color: Color(0xFF0D7FF2),
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF0D7FF2),
                  fontWeight: FontWeight.bold,
                ),
                unselectedIconTheme: const IconThemeData(color: Colors.grey),
                unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                minWidth: ResponsiveHelper.getNavigationRailWidth(context),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble),
                    label: Text('Chats'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.groups),
                    label: Text('Contacts'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
              // Vertical divider
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFF374151),
              ),
              // Main content
              Expanded(
                child: IndexedStack(
                  index: selectedTab,
                  children: const [
                    ChatListScreen(),
                    ContactsScreen(),
                    ProfilePage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Column(
          children: [
            // Responsive breakpoint indicator using ResponsiveHelper
            //ResponsiveHelper.debugBreakpointIndicator(context),
            // Main content
            Expanded(
              child: IndexedStack(
                index: selectedTab,
                children: const [
                  ChatListScreen(),
                  ContactsScreen(),
                  ProfilePage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2937),
          border: Border(top: BorderSide(color: Color(0xFF374151), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedTab,
          onTap: (index) =>
              ref.read(selectedTabProvider.notifier).state = index,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0D7FF2),
          unselectedItemColor: Colors.grey,
          selectedFontSize: ResponsiveHelper.getBodyFontSize(context),
          unselectedFontSize: ResponsiveHelper.getBodyFontSize(context),
          iconSize: ResponsiveHelper.getIconSize(context),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// Chat List Item Widget
