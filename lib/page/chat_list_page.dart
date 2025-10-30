import 'package:chat_apps/page/chat_screen.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:chat_apps/model/user_model.dart';
import 'package:chat_apps/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

part 'chat_list_page.g.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final newMessageAlertProvider = StateProvider<NewMessageAlert?>((ref) => null);

class NewMessageAlert {
  final String userName;
  final String messageContent;
  final DateTime timestamp;
  final bool isNewConversation;

  NewMessageAlert({
    required this.userName,
    required this.messageContent,
    required this.timestamp,
    this.isNewConversation = false,
  });
}

// Provider to get users who have conversations with current user
@riverpod
Future<List<UserModel>> getConversationUsers(GetConversationUsersRef ref) async {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) return [];

  try {
    // Get unique users that current user has sent messages to or received messages from
    final response = await supabase
        .from('messages')
        .select('sender_id, receiver_id')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .neq('is_deleted', true);

    final Set<String> conversationUserIds = {};
    for (final message in response as List) {
      final senderId = message['sender_id'] as String?;
      final receiverId = message['receiver_id'] as String?;

      if (senderId != null && senderId != currentUserId) {
        conversationUserIds.add(senderId);
      }
      if (receiverId != null && receiverId != currentUserId) {
        conversationUserIds.add(receiverId);
      }
    }

    if (conversationUserIds.isEmpty) return [];

    // Get user details for these conversation users
    final usersResponse = await supabase
        .from('users')
        .select()
        .inFilter('id', conversationUserIds.toList());

    return usersResponse.map((json) => UserModel.fromJson(json)).toList();
  } catch (e) {
    // Error handling without print in production
    return [];
  }
}

// Provider to get the last message for each conversation
@riverpod
Future<Map<String, MessageModel>> getLastMessages(GetLastMessagesRef ref) async {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) return {};

  try {
    // Get the most recent message from each conversation
    final response = await supabase
        .from('messages')
        .select('''
          *,
          conversations!inner(
            name
          )
        ''')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .neq('is_deleted', true)
        .order('created_at', ascending: false);

    final Map<String, MessageModel> lastMessages = {};
    final Set<String> processedConversations = {};

    for (final messageData in response as List) {
      final message = MessageModel.fromJson(messageData);
      final conversationKey = _getConversationKey(currentUserId, message.senderId, message.receiverId);

      if (!processedConversations.contains(conversationKey)) {
        lastMessages[conversationKey] = message;
        processedConversations.add(conversationKey);
      }
    }

    return lastMessages;
  } catch (e) {
    // Error handling without print in production
    return {};
  }
}

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
  Timer? _alertTimer;
  Timer? _pollingTimer;
  final Set<String> _seenMessages = {};

  @override
  void initState() {
    super.initState();
    // Start periodic polling for new messages
    _startMessagePolling();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startMessagePolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkForNewMessages();
    });
  }

  void _checkForNewMessages() {
    final lastMessages = ref.read(getLastMessagesProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (lastMessages.value == null || currentUserId == null) return;

    final now = DateTime.now();

    for (final entry in lastMessages.value!.entries) {
      final message = entry.value;
      final messageKey = '${message.id}_${message.createdAt?.millisecondsSinceEpoch ?? 0}';

      // Check if message is new and from another user
      if (message.senderId != currentUserId &&
          !_seenMessages.contains(messageKey) &&
          message.createdAt != null &&
          now.difference(message.createdAt!).inMinutes < 1) {

        _seenMessages.add(messageKey);
        _showNewMessageAlert(message);

        // Auto-dismiss alert after 5 seconds
        _alertTimer?.cancel();
        _alertTimer = Timer(const Duration(seconds: 5), () {
          ref.read(newMessageAlertProvider.notifier).state = null;
        });
      }
    }
  }

  void _showNewMessageAlert(MessageModel message) {
    // Create a user-friendly alert
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isFromCurrentUser = message.senderId == currentUserId;
    final userName = isFromCurrentUser ? 'You' : 'New message';
    final messageContent = isFromCurrentUser
        ? 'You: ${message.content ?? 'sent a message'}'
        : message.content ?? 'sent you a message';

    final alert = NewMessageAlert(
      userName: userName,
      messageContent: messageContent,
      timestamp: message.createdAt ?? DateTime.now(),
      isNewConversation: false,
    );

    ref.read(newMessageAlertProvider.notifier).state = alert;
  }

  Widget _buildNewMessageAlert(NewMessageAlert alert) {
    return Dismissible(
      key: Key('alert_${alert.timestamp.millisecondsSinceEpoch}'),
      direction: DismissDirection.up,
      onDismissed: (_) {
        ref.read(newMessageAlertProvider.notifier).state = null;
        _alertTimer?.cancel();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D7FF2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.messageContent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              _formatAlertTime(alert.timestamp),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAlertTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final getConversationUsers = ref.watch(getConversationUsersProvider);
    final getLastMessages = ref.watch(getLastMessagesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currentUser = ref.watch(currentUserProvider);
    final newMessageAlert = ref.watch(newMessageAlertProvider);

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
                child: const Icon(Icons.chat, color: Colors.white, size: 20),
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
              return getConversationUsers.when(
                data: (conversationUsers) {
                  return getLastMessages.when(
                    data: (lastMessages) {
                      // Get users with conversations, filtered by search query
                      final currentUserId = currentUserData?.id;
                      final conversationUsersList = conversationUsers.where((user) {
                        return user.displayName.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );
                      }).toList();

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
                                    currentUserId!,
                                    currentUserId!,
                                    user.id!,
                                  );
                                  final lastMessage = lastMessages[conversationKey];

                                  return ConversationTile(
                                    user: user,
                                    lastMessage: lastMessage,
                                    currentUserId: currentUserId!,
                                    onTap: () async {
                                      final conversationId = await ref.read(
                                        createOrGetPrivateConversationProvider(user.id!).future,
                                      );

                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              senderId: currentUserId!,
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
          ),
        ),
          ],
        ),
        // New Message Alert Overlay
        if (newMessageAlert != null)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: _buildNewMessageAlert(newMessageAlert!),
          ),
      ],
    );
  }
}


class ConversationTile extends StatelessWidget {
  final UserModel user;
  final MessageModel? lastMessage;
  final String currentUserId;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.user,
    this.lastMessage,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Message time
                      if (lastMessage?.createdAt != null)
                        Text(
                          _formatMessageTime(lastMessage!.createdAt!),
                          style: const TextStyle(
                            color: Color(0xFF0D7FF2),
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
                          style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 14,
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
        return 'You: ${lastMessage!.content} (edited)';
      }
      return 'You: ${lastMessage!.content}';
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
