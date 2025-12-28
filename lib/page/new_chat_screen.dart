import 'package:chat_apps/page/chat_screen.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newChatSearchProvider = StateProvider<String>((ref) => '');

class NewChatScreen extends ConsumerWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsers = ref.watch(getAllUsersProvider);
    final currentUser = ref.watch(currentUserProvider);
    final searchQuery = ref.watch(newChatSearchProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Chat',
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
                        ref.read(newChatSearchProvider.notifier).state = value;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search users...',
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

          // Users List
          Expanded(
            child: currentUser.when(
              data: (currentUserData) {
                return allUsers.when(
                  data: (users) {
                    final filteredUsers = users.where((user) {
                      final currentUserId = currentUserData?.id;
                      // Don't show current user in the list
                      if (currentUserId != null && user.id == currentUserId) {
                        return false;
                      }
                      // Filter based on search query
                      if (searchQuery.isNotEmpty) {
                        return user.displayName.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );
                      }
                      return true;
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
                        return UserTile(
                          user: user,
                          currentUserId: currentUserData?.id?.toString() ?? '',
                          onTap: () async {
                            // Create or get private conversation
                            final conversationId = await ref.read(
                              createOrGetPrivateConversationProvider(user.id!).future,
                            );

                            // Navigate to chat screen
                            if (context.mounted) {
                              Navigator.pushReplacement(
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
            ),
          ),
        ],
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final UserModel user;
  final String currentUserId;
  final VoidCallback onTap;

  const UserTile({
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
                    user.isOnline == true
                        ? 'Online'
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
            ),

            // Chat icon
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const IconButton(
                icon: Icon(Icons.chat, color: Colors.white, size: 20),
                onPressed: null, // Tap handled by parent InkWell
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
