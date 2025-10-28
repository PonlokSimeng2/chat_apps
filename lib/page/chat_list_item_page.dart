import 'package:chat_app/model/user_model.dart';
import 'package:chat_app/model/message_model.dart';
import 'package:chat_app/provider/message_provider.dart';
import 'package:chat_app/page/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatListItemPage extends ConsumerStatefulWidget {
  final UserModel user;
  final int conversationId;
  final String currentUserId;

  const ChatListItemPage({
    super.key,
    required this.user,
    required this.conversationId,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatListItemPage> createState() => _ChatListItemPageState();
}

class _ChatListItemPageState extends ConsumerState<ChatListItemPage> {
  String? lastMessage;
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
        lastMessage = lastMsg?.content ?? 'No messages yet';
        unreadCount = unread;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        lastMessage = 'Error loading messages';
        unreadCount = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Mark messages as read when user taps on the chat item
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
              if (widget.user.isOnline == true)
                Positioned(
                  right: 0,
                  bottom: 0,
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
                Text(
                  widget.user.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage ?? 'No messages yet',
                  style: TextStyle(
                    color: unreadCount > 0 ? Colors.white : Colors.grey,
                    fontSize: 14,
                    fontWeight: unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Unread count
          if (unreadCount > 0)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF0D7FF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
}
