import 'package:chat_apps/page/chat_screen.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final contactsSearchProvider = StateProvider<String>((ref) => '');

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getAllUsers = ref.watch(getAllUsersProvider);
    final searchQuery = ref.watch(contactsSearchProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B14),
        elevation: 0,
        centerTitle: true,
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
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C28),
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

          const SizedBox(height: 20),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'MY CONTACTS',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Contacts List
          Expanded(
            child: currentUser.when(
              data: (currentUserData) {
                return getAllUsers.when(
                  data: (allUsers) {
                    final currentUserId = currentUserData?.id;
                    final filteredUsers = allUsers.where((user) {
                      if (currentUserId != null && user.id == currentUserId) {
                        return false;
                      }
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
                              'No contacts found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try searching with a different name',
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
                          onTap: () {
                            if (user.id == null) return;
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
                                  conversationIdFuture: ref.read(
                                    createOrGetPrivateConversationProvider(
                                      user.id!,
                                    ).future,
                                  ),
                                  isOnline: user.isOnline ?? false,
                                  lastSeenAt: user.lastSeenAt,
                                ),
                              ),
                            );
                          },
                        );
                        ;
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text('Error: $error')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
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
    final isOnline = user.isOnline == true;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Avatar (plain, no badge dot — matches mockup)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline ? 'Online' : _formatLastSeen(user.lastSeenAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'Offline';
    Duration difference = DateTime.now().toUtc().difference(lastSeenAt.toUtc());
    if (difference.isNegative) difference = difference.abs();

    if (difference.inMinutes < 1) return 'Last seen just now';
    if (difference.inHours < 1) {
      return 'Last seen ${difference.inMinutes} minutes ago';
    }
    if (difference.inDays < 1) {
      return difference.inHours == 1
          ? 'Last seen 1 hour ago'
          : 'Last seen ${difference.inHours} hours ago';
    }
    if (difference.inDays == 1) return 'Last seen yesterday';
    if (difference.inDays < 7) return 'Last seen ${difference.inDays} days ago';
    return 'Last seen ${lastSeenAt.day}/${lastSeenAt.month}';
  }
}
