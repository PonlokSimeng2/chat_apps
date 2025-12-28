import 'package:chat_apps/page/chat_screen.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:chat_apps/provider/message_provider.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactsSearchProvider = StateProvider<String>((ref) => '');

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getAllUsers = ref.watch(getAllUsersProvider);
    final getConversationUsers = ref.watch(conversationUsersProvider);
    final searchQuery = ref.watch(contactsSearchProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Contacts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              // TODO: Implement add user functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                        ref.read(contactsSearchProvider.notifier).state = value;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search contacts...',
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

          // Contacts List
          Expanded(
            child: currentUser.when(
              data: (currentUserData) {
                return getAllUsers.when(
                  data: (allUsers) {
                    return getConversationUsers.when(
                      data: (conversationUsers) {
                        // Get users you haven't chatted with yet
                        final currentUserId = currentUserData?.id;
                        final filteredUsers = allUsers.where((user) {
                          // Exclude current user
                          if (currentUserId != null && user.id == currentUserId) {
                            return false;
                          }
                          // Exclude users you already have conversations with
                          if (conversationUsers.any((convUser) => convUser.id == user.id)) {
                            return false;
                          }
                          // Filter based on search query
                          return user.displayName.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          );
                        }).toList();

                        if (filteredUsers.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No new contacts available',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'All users are already in your conversations',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return ContactTile(
                              user: user,
                              currentUserId: currentUserData?.id?.toString() ?? '',
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
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(
                        child: Text('Error: $error'),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text('Error: $error'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactTile extends StatelessWidget {
  final UserModel user;
  final String currentUserId;
  final VoidCallback onTap;

  const ContactTile({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF374151),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
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
                // Online status indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: user.isOnline == true
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: user.isOnline == true
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.isOnline == true
                            ? 'Available to chat'
                            : _formatLastSeen(user.lastSeenAt),
                        style: TextStyle(
                          color: user.isOnline == true
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Start chat button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D7FF2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'Offline';
    Duration difference =
        DateTime.now().toUtc().difference(lastSeenAt.toUtc());
    if (difference.isNegative) {
      difference = difference.abs();
    }
    if (difference.inMinutes < 1) {
      return 'last seen now';
    } else if (difference.inHours < 1) {
      return 'last seen ${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return 'last seen ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'last seen ${difference.inDays}d';
    } else {
      return 'last seen ${lastSeenAt.day}/${lastSeenAt.month}';
    }
  }
}
