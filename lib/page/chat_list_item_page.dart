import 'package:chat_apps/model/user_model.dart';
import 'package:chat_apps/model/message_model.dart';
import 'package:chat_apps/provider/message_provider.dart';
import 'package:chat_apps/page/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatListItemPage extends ConsumerStatefulWidget {
  final UserModel user;
  final int conversationId;
  final String currentUserId;
  final VoidCallback? onTap;

  const ChatListItemPage({
    super.key,
    required this.user,
    required this.conversationId,
    required this.currentUserId,
    this.onTap,
  });

  @override
  ConsumerState<ChatListItemPage> createState() => _ChatListItemPageState();
}

class _ChatListItemPageState extends ConsumerState<ChatListItemPage> {
  MessageModel? _lastMessage;
  int unreadCount = 0;
  bool isLoading = true;
  RealtimeChannel? _messageChannel;

  @override
  void initState() {
    super.initState();
    _loadConversationData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;

    _messageChannel = supabase.channel('messages:${widget.conversationId}');

    _messageChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: widget.conversationId,
      ),
      callback: (payload) {
        // New message received, refresh data
        _loadConversationData();
      },
    );

    _messageChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: widget.conversationId,
      ),
      callback: (payload) {
        // Message updated (e.g., marked as read), refresh data
        _loadConversationData();
      },
    );

    _messageChannel!.subscribe();
  }

  Future<void> _loadConversationData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load last message and unread count in parallel
      final messageNotifier = ref.read(messageNotifierProvider.notifier);

      final lastMessageFuture = messageNotifier.getLastMessage(
        conversationId: widget.conversationId,
      );

      final unreadCountFuture = messageNotifier.getUnreadMessageCount(
        userId: widget.currentUserId,
        conversationId: widget.conversationId,
      );

      final results = await Future.wait([
        lastMessageFuture,
        unreadCountFuture,
      ]);

      final lastMsg = results[0] as MessageModel?;
      final unread = results[1] as int;

      setState(() {
        _lastMessage = lastMsg;
        unreadCount = unread;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastMessage = null;
        unreadCount = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Use custom onTap if provided
        if (widget.onTap != null) {
          widget.onTap!();
          return;
        }

        // Default behavior: Mark messages as read when user taps on the chat item
        if (unreadCount > 0) {
          final messageNotifier = ref.read(messageNotifierProvider.notifier);
          await messageNotifier.markAllMessagesAsRead(
            userId: widget.currentUserId,
            conversationId: widget.conversationId,
          );

          // Refresh the conversation data to update unread count
          _loadConversationData();
        }

        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              senderId: widget.currentUserId,
              otherUserName: widget.user.displayName,
              otherUserAvatar: widget.user.profilePictureUrl ??
                  'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
              receiverId: widget.user.id?.toString() ?? '',
              conversationId: widget.conversationId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: unreadCount > 0 ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
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
                        widget.user.profilePictureUrl ??
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
                      color: widget.user.isOnline == true
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
                // Unread indicator dot
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D7FF2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF111827),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.user.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Message time
                      if (_lastMessage != null && _lastMessage!.createdAt != null)
                        Text(
                          _formatMessageTime(_lastMessage!.createdAt!),
                          style: TextStyle(
                            color: unreadCount > 0 ? const Color(0xFF0D7FF2) : Colors.grey,
                            fontSize: 12,
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
                            color: unreadCount > 0 ? Colors.white : Colors.grey,
                            fontSize: 14,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // Message status indicator for sent messages
                      if (_lastMessage != null && _lastMessage!.senderId == widget.currentUserId)
                        _buildMessageStatusIndicator(),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Unread count badge
            if (unreadCount > 0)
              Container(
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D7FF2),
                  borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildMessageStatusIndicator() {
    if (_lastMessage == null) return const SizedBox.shrink();

    // For messages sent by current user
    if (_lastMessage!.senderId == widget.currentUserId) {
      return Icon(
        Icons.done_all,
        size: 16,
        color: _lastMessage!.readAt != null
            ? const Color(0xFF0D7FF2)
            : Colors.grey,
      );
    }

    return const SizedBox.shrink();
  }

  String _getLastMessageText() {
    if (_lastMessage == null) return 'No messages yet';

    if (_lastMessage!.senderId == widget.currentUserId) {
      if (_lastMessage!.isEdited == true) {
        return 'You: ${_lastMessage!.content} (edited)';
      }
      return 'You: ${_lastMessage!.content}';
    }

    return _lastMessage!.content ?? '';
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
