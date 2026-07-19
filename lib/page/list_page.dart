import 'dart:async';
import 'package:chat_apps/component/las_seen.dart';
import 'package:chat_apps/page/chat_screen.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:chat_apps/provider/message_provider.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:chat_apps/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_apps/utils/responsive_helper.dart';
import 'package:flutter_riverpod/legacy.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

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
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
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

    final headerPadding = ResponsiveHelper.getPadding(context);
    final avatarSize = ResponsiveHelper.getSmallAvatarSize(context);
    final titleFontSize = ResponsiveHelper.getHeadingFontSize(context);
    final searchHeight = ResponsiveHelper.getSearchBarHeight(context);
    final searchHorizontalPadding = ResponsiveHelper.getPadding(context);
    final searchBorderRadius = ResponsiveHelper.getBorderRadius(context) * 1.5;
    final searchFontSize = ResponsiveHelper.getSubtitleFontSize(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: headerPadding,
                vertical: headerPadding * 0.5,
              ),
              child: currentUser.when(
                data: (me) => Row(
                  children: [
                    CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundImage: NetworkImage(
                        me?.profilePictureUrl ??
                            'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Chats',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F2937),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: avatarSize * 0.5,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox(height: 40),
              ),
            ),

            // ── Search bar ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: searchHorizontalPadding,
              ),
              child: Container(
                height: searchHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C28),
                  borderRadius: BorderRadius.circular(searchBorderRadius),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: searchHorizontalPadding),
                      child: Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: searchHeight * 0.4,
                      ),
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

            const SizedBox(height: 20),

            Expanded(
              child: currentUser.when(
                data: (currentUserData) {
                  return getConversationUsers.when(
                    data: (conversationUsers) {
                      return getLastMessages.when(
                        data: (lastMessages) {
                          return getUnreadMessageCounts.when(
                            data: (unreadCounts) {
                              final currentUserId = currentUserData?.id;

                              final conversationUsersList = conversationUsers
                                  .where(
                                    (user) => user.displayName
                                        .toLowerCase()
                                        .contains(searchQuery.toLowerCase()),
                                  )
                                  .toList();

                              final onlineUsers = conversationUsers
                                  .where((u) => u.isOnline == true)
                                  .toList();

                              if (currentUserId == null) {
                                return const Center(
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
                                );
                              }

                              return CustomScrollView(
                                slivers: [
                                  // ── Online contacts row ───────
                                  if (onlineUsers.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: SizedBox(
                                        height: 92,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: headerPadding,
                                          ),
                                          itemCount: onlineUsers.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 16),
                                          itemBuilder: (context, index) {
                                            final user = onlineUsers[index];
                                            return _OnlineContactItem(
                                              user: user,
                                              onTap: () {
                                                if (user.id == null) return;
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ChatScreen(
                                                      senderId: currentUserId,
                                                      otherUserName:
                                                          user.displayName,
                                                      otherUserAvatar:
                                                          user.profilePictureUrl ??
                                                          '...',
                                                      receiverId:
                                                          user.id?.toString() ??
                                                          '',
                                                      conversationIdFuture: ref
                                                          .read(
                                                            createOrGetPrivateConversationProvider(
                                                              user.id!,
                                                            ).future,
                                                          ),
                                                      isOnline:
                                                          user.isOnline ??
                                                          false,
                                                      lastSeenAt:
                                                          user.lastSeenAt,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                  if (onlineUsers.isNotEmpty)
                                    const SliverToBoxAdapter(
                                      child: SizedBox(height: 12),
                                    ),

                                  // ── Conversation list ─────────
                                  if (conversationUsersList.isNotEmpty)
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate((
                                        context,
                                        index,
                                      ) {
                                        final user =
                                            conversationUsersList[index];
                                        final conversationKey =
                                            _getConversationKey(
                                              currentUserId,
                                              currentUserId,
                                              user.id ?? '',
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
                                          onTap: () {
                                            if (user.id == null) return;
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
                                                      user.id?.toString() ?? '',
                                                  conversationIdFuture: ref.read(
                                                    createOrGetPrivateConversationProvider(
                                                      user.id!,
                                                    ).future,
                                                  ),
                                                  isOnline:
                                                      user.isOnline ?? false,
                                                  lastSeenAt: user.lastSeenAt,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }, childCount: conversationUsersList.length),
                                    ),
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
      ),
    );
  }
}

// ============================================
// ONLINE CONTACT ITEM (top horizontal row)
// ============================================
class _OnlineContactItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _OnlineContactItem({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      user.profilePictureUrl ??
                          'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0B0B14),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// CONVERSATION TILE (plain row style)
// ============================================

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
    final avatarSize = ResponsiveHelper.getAvatarSize(context);
    final horizontalPadding = ResponsiveHelper.getListTilePadding(context);
    final verticalPadding = ResponsiveHelper.getListTileVerticalPadding(
      context,
    );
    final fontSizeName = ResponsiveHelper.getTitleFontSize(context);
    final fontSizeMessage = ResponsiveHelper.getSubtitleFontSize(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
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
                if (user.isOnline == true)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: avatarSize * 0.28,
                      height: avatarSize * 0.28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0B0B14),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: ResponsiveHelper.isDesktop(context) ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSizeName,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLastMessageText(),
                    style: TextStyle(
                      color: const Color(0xFF9CA3AF),
                      fontSize: fontSizeMessage,
                      fontWeight: hasUnreadMessages
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ⬅️ new trailing column: status/time on top, unread badge below
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  user.isOnline == true
                      ? 'Online'
                      : formatLastSeenShort(user.lastSeenAt),
                  style: TextStyle(
                    color: user.isOnline == true
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: user.isOnline == true
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasUnreadMessages)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D7FF2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
}
