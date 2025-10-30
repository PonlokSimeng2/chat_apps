import 'package:chat_apps/page/chat_screen.dart';
import 'package:chat_apps/page/new_chat_screen.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // No need to manually load - the provider will handle it automatically
  }

  @override
  Widget build(BuildContext context) {
    final getAllUsers = ref.watch(getAllUsersProvider);
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewChatScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
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
              return getAllUsers.when(
                data: (allUsers) {
                  // Filter based on search query and exclude current user
                  final filteredUsers = allUsers.where((user) {
                    // Don't show current user in the list
                    if (currentUserData?.id != null && user.id == currentUserData!.id) {
                      return false;
                    }
                    // Filter based on search query
                    return user.displayName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return GestureDetector(
                        onTap: () async {
                          // Create or get private conversation
                          final conversationId = await ref.read(
                            createOrGetPrivateConversationProvider(user.id!).future,
                          );

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  senderId: currentUserData?.id?.toString() ?? '',
                                  otherUserName: user.displayName,
                                  otherUserAvatar: user.profilePictureUrl ??
                                      'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                                  receiverId: user.id?.toString() ?? '',
                                  conversationId: conversationId,
                                ),
                              ),
                            );
                          }
                        },
                        child: SimpleUserTile(
                          user: user,
                          onTap: () async {
                            // Create or get private conversation when user taps
                            final conversationId = await ref.read(
                              createOrGetPrivateConversationProvider(user.id!).future,
                            );

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    senderId: currentUserData?.id?.toString() ?? '',
                                    otherUserName: user.displayName,
                                    otherUserAvatar: user.profilePictureUrl ??
                                        'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                                    receiverId: user.id?.toString() ?? '',
                                    conversationId: conversationId,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
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

class SimpleUserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const SimpleUserTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: DecorationImage(
                  image: NetworkImage(
                    user.profilePictureUrl ??
                        'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.isOnline == true ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: user.isOnline == true
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Chat icon
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.chat, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
