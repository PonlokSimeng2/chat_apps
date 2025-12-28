import 'dart:async';
import 'package:chat_apps/page/chat_screen.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:chat_apps/provider/message_provider.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:chat_apps/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_apps/utils/responsive_helper.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

// Helper function to create a unique conversation key
String _getConversationKey(String currentUserId, String senderId, String receiverId) {
  final users = [senderId, receiverId]..sort();
  return '${users[0]}_${users[1]}';
}

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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

    // Use ResponsiveHelper for responsive calculations
    final headerPadding = ResponsiveHelper.getPadding(context);
    final avatarSize = ResponsiveHelper.getSmallAvatarSize(context);
    final titleFontSize = ResponsiveHelper.getHeadingFontSize(context);
    final searchHeight = ResponsiveHelper.getSearchBarHeight(context);
    final searchHorizontalPadding = ResponsiveHelper.getPadding(context);
    final searchBorderRadius = ResponsiveHelper.getBorderRadius(context) * 1.5;
    final searchFontSize = ResponsiveHelper.getSubtitleFontSize(context);

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(headerPadding),
              child: Row(
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(avatarSize / 2),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBpEN6dfbSeC6GJfwBfgdExi8xM_e-PYrwfawXMDgbQDDaKbP9PzGHGz7DKuCcyFy00ljTbUAkf4Xdc6LHXgyiKB7ZCpBuT_XXNAR6uNfsoYeQLrPwKK6tTSK0We2htGRqGH79Bq0mUZnvu1-52ZJV26ORS4Lk2xvAmXvksK-a6b0p3sIPVrjHb_Wf1tbiAG_gYdyKJHI45FoK5KZv3YEo76U6mx-xwckcJ2PxS6ku7wwUmHWWjqV2-yvPMWHS1jX0SIsmsabt-iUPn',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Chats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(avatarSize / 2),
                    ),
                    child: Icon(Icons.chat, color: Colors.white, size: avatarSize * 0.5),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: searchHorizontalPadding),
              child: Container(
                height: searchHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(searchBorderRadius),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: searchHorizontalPadding),
                      child: Icon(Icons.search, color: Colors.grey, size: searchHeight * 0.4),
                    ),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          ref.read(searchQueryProvider.notifier).state = value;
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: searchFontSize,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: searchHorizontalPadding * 0.5,
                            vertical: searchHeight * 0.1,
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: searchFontSize,
                        ),
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
              return getConversationUsers.when(
                data: (conversationUsers) {
                  return getLastMessages.when(
                    data: (lastMessages) {
                      return getUnreadMessageCounts.when(
                        data: (unreadCounts) {
                          // Get users with conversations, filtered by search query
                          final currentUserId = currentUserData?.id;
                          final conversationUsersList = conversationUsers.where((user) {
                            return user.displayName.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            );
                          }).toList();

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
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                                childCount: conversationUsersList.length,
                              ),
                            ),
                          ],

                          // Empty State
                          if (conversationUsersList.isEmpty)
                            const SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(child: Text('Error: $error')),
                  );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Center(child: Text('Error: $error')),
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

    // Use ResponsiveHelper for responsive sizing
    final avatarSize = ResponsiveHelper.getAvatarSize(context);
    final horizontalPadding = ResponsiveHelper.getListTilePadding(context);
    final verticalPadding = ResponsiveHelper.getListTileVerticalPadding(context);
    final fontSizeName = ResponsiveHelper.getTitleFontSize(context);
    final fontSizeMessage = ResponsiveHelper.getSubtitleFontSize(context);
    final fontSizeTime = ResponsiveHelper.getCaptionFontSize(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ? 8.0 : 0, vertical: 2.0),
        decoration: BoxDecoration(
          color: hasUnreadMessages ? const Color(0xFF1E3A5A) : const Color(0xFF1E293B),
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
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(avatarSize / 2),
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
                  child: user.isOnline == true
                      ? Container(
                          width: avatarSize * 0.285,
                          height: avatarSize * 0.285,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius:
                                BorderRadius.circular(avatarSize * 0.143),
                            border: Border.all(
                              color: const Color(0xFF111827),
                              width: 2,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: avatarSize * 0.12,
                            vertical: avatarSize * 0.04,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius:
                                BorderRadius.circular(avatarSize * 0.14),
                            border: Border.all(
                              color: const Color(0xFF111827),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _formatLastSeenShort(user.lastSeenAt),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: avatarSize * 0.14,
                              fontWeight: FontWeight.w600,
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
                      constraints: BoxConstraints(
                        minWidth: avatarSize * 0.39,
                        minHeight: avatarSize * 0.39,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D7FF2),
                        borderRadius: BorderRadius.circular(avatarSize * 0.196),
                        border: Border.all(
                          color: const Color(0xFF111827),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: avatarSize * 0.179,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: ResponsiveHelper.isDesktop(context) ? 20 : 16),

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
                            color: hasUnreadMessages ? Colors.white : const Color(0xFFD1D5DB),
                            fontSize: fontSizeName,
                            fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Message time
                      if (lastMessage?.createdAt != null)
                        Text(
                          _formatMessageTime(lastMessage!.createdAt!),
                          style: TextStyle(
                            color: hasUnreadMessages ? const Color(0xFF0D7FF2) : const Color(0xFF9CA3AF),
                            fontSize: fontSizeTime,
                            fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.isDesktop(context) ? 6 : 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getLastMessageText(),
                          style: TextStyle(
                            color: hasUnreadMessages ? Colors.white : const Color(0xFF9CA3AF),
                            fontSize: fontSizeMessage,
                            fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: ResponsiveHelper.isDesktop(context) ? 2 : 1,
                        ),
                      ),
                      // Message status indicator
                      if (lastMessage?.senderId == currentUserId)
                        _buildMessageStatusIndicator(),
                      if (user.isOnline != true && user.lastSeenAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatLastSeenShort(user.lastSeenAt),
                          style: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: fontSizeTime,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: ResponsiveHelper.isDesktop(context) ? 12 : 8),

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

  String _formatLastSeenShort(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return '';
    Duration difference =
        DateTime.now().toUtc().difference(lastSeenAt.toUtc());
    if (difference.isNegative) {
      difference = difference.abs();
    }
    if (difference.inMinutes < 1) {
      return '1m';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${lastSeenAt.day}/${lastSeenAt.month}';
    }
  }
}
