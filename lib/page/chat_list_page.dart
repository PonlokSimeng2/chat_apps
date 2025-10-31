import 'package:chat_apps/page/chat_screen.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:chat_apps/provider/message_provider.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:chat_apps/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

// Helper function to create a unique conversation key
String _getConversationKey(
  String currentUserId,
  String senderId,
  String receiverId,
) {
  final users = [senderId, receiverId]..sort();
  return '${users[0]}_${users[1]}';
}

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final getConversationUsers = ref.watch(conversationUsersProvider);
    final getLastMessages = ref.watch(getLastMessagesProvider);
    final getUnreadMessageCounts = ref.watch(getUnreadMessageCountsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currentUser = ref.watch(currentUserProvider);
    // final newMessageAlert = ref.watch(newMessageAlertProvider);

    return Stack(
      children: [
        Column(
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
                    child: const Icon(
                      Icons.chat,
                      color: Colors.white,
                      size: 20,
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

<<<<<<< HEAD
            Expanded(
              child: currentUser.when(
                data: (currentUserData) {
                  return getConversationUsers.when(
                    data: (conversationUsers) {
                      return getLastMessages.when(
                        data: (lastMessages) {
                          return getUnreadMessageCounts.when(
                            data: (unreadCounts) {
                              // Get users with conversations, filtered by search query
                              final currentUserId = currentUserData?.id;
                              final conversationUsersList = conversationUsers
                                  .where((user) {
                                    return user.displayName
                                        .toLowerCase()
                                        .contains(searchQuery.toLowerCase());
                                  })
                                  .toList();

                              return CustomScrollView(
                                slivers: [
                                  // Conversations Section
                                  if (conversationUsersList.isNotEmpty) ...[
                                    const SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'CONVERSATIONS',
                                          style: TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.0,
=======
                          // If currentUserId is null, show empty state
                          if (currentUserId == null) {
                            return const SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Please log in to view conversations',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return CustomScrollView(
                            slivers: [
                              // Conversations Section
                              if (conversationUsersList.isNotEmpty) ...[
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      'CONVERSATIONS',
                                      style: TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final user = conversationUsersList[index];
                                      final conversationKey = _getConversationKey(
                                        currentUserId,
                                        currentUserId,
                                        user.id ?? '',
                                      );
                                      final lastMessage = lastMessages[conversationKey];
                                      final unreadCount = unreadCounts[conversationKey] ?? 0;

                                  return ConversationTile(
                                    user: user,
                                    lastMessage: lastMessage,
                                    currentUserId: currentUserId,
                                    unreadCount: unreadCount,
                                    onTap: () async {
                                      if (user.id == null) return;

                                      final conversationId = await ref.read(
                                        createOrGetPrivateConversationProvider(user.id!).future,
                                      );

                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              senderId: currentUserId,
                                              otherUserName: user.displayName,
                                              otherUserAvatar: user.profilePictureUrl ??
                                                  'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                                              receiverId: user.id?.toString() ?? '',
                                              conversationId: conversationId,
                                            ),
>>>>>>> 08da7e8 (chat_list_page)
                                          ),
                                        ),
                                      ),
                                    ),
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate((
                                        context,
                                        index,
                                      ) {
                                        final user =
                                            conversationUsersList[index];
                                        final conversationKey =
                                            _getConversationKey(
                                              currentUserId!,
                                              currentUserId,
                                              user.id!,
                                            );
                                        final lastMessage =
                                            lastMessages[conversationKey];
                                        final unreadCount =
                                            unreadCounts[conversationKey] ?? 0;

                                        return ConversationTile(
                                          user: user,
                                          lastMessage: lastMessage,
                                          currentUserId: currentUserId,
                                          unreadCount: unreadCount,
                                          onTap: () async {
                                            final conversationId = await ref.read(
                                              createOrGetPrivateConversationProvider(
                                                user.id!,
                                              ).future,
                                            );

                                            if (context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ChatScreen(
                                                    senderId: currentUserId,
                                                    otherUserName:
                                                        user.displayName,
                                                    otherUserAvatar:
                                                        user.profilePictureUrl ??
                                                        'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                                                    receiverId:
                                                        user.id?.toString() ??
                                                        '',
                                                    conversationId:
                                                        conversationId,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      }, childCount: conversationUsersList.length),
                                    ),
                                  ],

                                  // Empty State
                                  if (conversationUsersList.isEmpty)
                                    const SliverFillRemaining(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 64,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No conversations yet',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Go to Contacts tab to start a new chat',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stackTrace) =>
                                Center(child: Text('Error: $error')),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) =>
                            Center(child: Text('Error: $error')),
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
        // New Message Alert Overlay
      ],
    );
  }
}

class ConversationTile extends StatelessWidget {
  final UserModel user;
  final MessageModel? lastMessage;
  final String currentUserId;
  final int unreadCount;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.user,
    this.lastMessage,
    required this.currentUserId,
    this.unreadCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnreadMessages = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnreadMessages
              ? const Color(0xFF1E3A5A)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: hasUnreadMessages
              ? Border.all(color: const Color(0xFF0D7FF2), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Avatar with online indicator and unread badge
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
                        color: const Color(0xFF111827),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Unread count badge
                if (hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D7FF2),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: const Color(0xFF111827),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: TextStyle(
                            color: hasUnreadMessages
                                ? Colors.white
                                : const Color(0xFFD1D5DB),
                            fontSize: 16,
                            fontWeight: hasUnreadMessages
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Message time
                      if (lastMessage?.createdAt != null)
                        Text(
                          _formatMessageTime(lastMessage!.createdAt!),
                          style: TextStyle(
                            color: hasUnreadMessages
                                ? const Color(0xFF0D7FF2)
                                : const Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontWeight: hasUnreadMessages
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getLastMessageText(),
                          style: TextStyle(
                            color: hasUnreadMessages
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                            fontSize: 14,
                            fontWeight: hasUnreadMessages
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // Message status indicator
                      if (lastMessage?.senderId == currentUserId)
                        _buildMessageStatusIndicator(),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chat icon
            // Container(
            //   decoration: BoxDecoration(
            //     color: const Color(0xFF1F2937),
            //     borderRadius: BorderRadius.circular(20),
            //   ),
            //   child: const Icon(Icons.chat, color: Colors.white, size: 20),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIndicator() {
    if (lastMessage == null) return const SizedBox.shrink();

    return Icon(
      Icons.done_all,
      size: 16,
      color: lastMessage!.readAt != null
          ? const Color(0xFF0D7FF2)
          : Colors.grey,
    );
  }

  String _getLastMessageText() {
    if (lastMessage == null) return 'No messages yet';

    if (lastMessage!.senderId == currentUserId) {
      if (lastMessage!.isEdited == true) {
        return 'You: ${lastMessage!.content ?? ''} (edited)';
      }
      return 'You: ${lastMessage!.content ?? ''}';
    }

    return lastMessage!.content ?? '';
  }

  String _formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${messageTime.day}/${messageTime.month}';
    }
  }
}
