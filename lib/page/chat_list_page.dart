import 'package:chat_app/page/chat_list_item_page.dart';
import 'package:chat_app/page/chat_screen.dart';
import 'package:chat_app/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getAllusers = ref.watch(getAllUsersProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBpEN6dfbSeC6GJfwBfgdExi8xM_e-PYrwfawXMDgbQDDaKbP9PzGHGz7DKuCcyFy00ljTbUAkf4Xdc6LHXgyiKB7ZCpBuT_XXNAR6uNfsoYeQLrPwKK6tTSK0We2htGRqGH79Bq0mUZnvu1-52ZJV26ORS4Lk2xvAmXvksK-a6b0p3sIPVrjHb_Wf1tbiAG_gYdyKJHI45FoK5KZv3YEo76U6mx-xwckcJ2PxS6ku7wwUmHWWjqV2-yvPMWHS1jX0SIsmsabt-iUPn',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Chats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Icon(Icons.search, color: Colors.grey),
                ),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: currentUser.when(
            data: (currentUserData) {
              return getAllusers.when(
                data: (users) {
                  final filteredUsers = users.where((user) {
                    final currentUserId = currentUserData?.id;
                    // Do not show current user in the list
                    if (currentUserId != null && user.id == currentUserId) {
                      return false;
                    }
                    // Filter based on search query
                    return user.displayName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );
                  }).toList();

                  return Column(
                    children: [
                      // Users Row
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      senderId:
                                          currentUserData?.id?.toString() ?? '',
                                      otherUserName: user.displayName,
                                      otherUserAvatar:
                                          user.profilePictureUrl ??
                                          'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                                      receiverId: user.id?.toString() ?? '',
                                      conversationId: 1,
                                      // userId: '${currentUserData?.id}',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(32),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            user.profilePictureUrl ??
                                                'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.displayName,
                                      style: const TextStyle(
                                        color: Color(0xFFD1D5DB),
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Chat List
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      senderId:
                                          currentUserData?.id?.toString() ?? '',
                                      otherUserName: user.displayName,
                                      otherUserAvatar:
                                          user.profilePictureUrl ??
                                          'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                                      receiverId: user.id?.toString() ?? '',
                                      conversationId: 1,
                                      // userId: '${currentUserData?.id}',
                                    ),
                                  ),
                                );
                              },
                              child: ChatListItemPage(
                                user: user,
                                conversationId: 1, // You'll need to replace this with actual conversation ID
                                currentUserId: currentUserData?.id?.toString() ?? '',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Error: $error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}
