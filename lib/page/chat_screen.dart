import 'dart:async';
import '../model/message_model.dart';
import '../model/message_status.dart';
import '../provider/message_provider.dart';
import '../provider/error_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String senderId;
  final String otherUserName;
  final String otherUserAvatar;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.senderId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    try {
      talker.info('Initializing ChatScreen for conversation: ${widget.conversationId}');
      // Load messages and setup Realtime subscription
      Future.microtask(
        () => ref
            .read(messageNotifierProvider.notifier)
            .loadMessages(widget.conversationId, widget.receiverId),
      );
    } catch (e, st) {
      talker.error('Error initializing ChatScreen', e, st);
      // Add to visual error tracking
      ref.read(errorProvider.notifier).addError(
        'Failed to load chat messages',
        details: e.toString(),
        severity: ErrorSeverity.error,
      );
    }
  }

  void _sendMessage() {
    try {
      if (_messageController.text.trim().isEmpty) {
        talker.warning('Attempted to send empty message');
        return;
      }

      talker.info('Sending message: ${_messageController.text.trim()}');

      // Send message - Realtime will handle updates automatically
      ref
          .read(messageNotifierProvider.notifier)
          .sendMessage(
            conversationId: widget.conversationId,
            senderId: widget.senderId,
            receiverId: widget.receiverId,
            content: _messageController.text.trim(),
          );

      _messageController.clear();
      _scrollToBottom();
    } catch (e, st) {
      talker.error('Error sending message', e, st);
      // Add to visual error tracking
      ref.read(errorProvider.notifier).addError(
        'Failed to send message',
        details: e.toString(),
        severity: ErrorSeverity.error,
      );
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Failed to send message'),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Retry sending
                  _sendMessage();
                },
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () => _sendMessage(),
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    try {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e, st) {
      talker.error('Error scrolling to bottom', e, st);
      // Add to visual error tracking (less severe)
      ref.read(errorProvider.notifier).addError(
        'Chat scrolling issue',
        details: e.toString(),
        severity: ErrorSeverity.warning,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messageNotifierProvider);

    // Auto-scroll when new messages arrive
    ref.listen<AsyncValue<List<MessageModel>>>(messageNotifierProvider, (
      _,
      next,
    ) {
      try {
        if (next is AsyncData) {
          talker.debug('New messages loaded: ${next.value?.length ?? 0} messages');
          _scrollToBottom();
        } else if (next is AsyncError) {
          talker.error('Error in messages state', next.error, next.stackTrace);
          // Add to visual error tracking
          ref.read(errorProvider.notifier).addError(
            'Failed to load messages',
            details: next.error.toString(),
            severity: ErrorSeverity.error,
          );
        }
      } catch (e, st) {
        talker.error('Error handling messages state change', e, st);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.otherUserAvatar),
                  radius: 20,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Unread count header
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = _getUnreadCount(messagesState.value ?? []);
              if (unreadCount == 0) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFF1C1C1E),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D7FF2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$unreadCount unread message${unreadCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF0D7FF2),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          _markAllAsRead(messagesState.value ?? []),
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: Color(0xFF0D7FF2),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: messagesState.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSentByMe = message.senderId == widget.senderId;
                    return _buildMessageBubble(message, isSentByMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isSentByMe) {
    // Auto-mark received messages as read when they are displayed
    if (!isSentByMe && message.isUnread && message.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(messageNotifierProvider.notifier).markAsRead(message.id!);
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(widget.otherUserAvatar),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSentByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _getMessageColor(message, isSentByMe),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.content ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Message status indicator (only for sent messages)
                    if (isSentByMe) ...[
                      _buildMessageStatusIndicator(message),
                      const SizedBox(width: 8),
                    ],
                    // Unread indicator for received messages
                    if (!isSentByMe && message.isUnread) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D7FF2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Unread',
                        style: TextStyle(
                          color: Color(0xFF0D7FF2),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Timestamp for all messages
                    if (message.createdAt != null)
                      Text(
                        _formatMessageTime(message.createdAt!),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMessageColor(MessageModel message, bool isSentByMe) {
    if (!isSentByMe) return const Color(0xFF2C2C2E);

    // Different colors based on message status
    switch (message.status) {
      case MessageStatus.sending:
        return Colors.blue.shade300; // Lighter blue for sending
      case MessageStatus.sent:
        return Colors.blue.shade600; // Normal blue for sent
      case MessageStatus.delivered:
        return Colors.blue.shade700; // Darker blue for delivered
      case MessageStatus.read:
        return Colors.blue.shade800; // Darkest blue for read
      case MessageStatus.failed:
        return Colors.red.shade400; // Red for failed
    }
  }

  Widget _buildMessageStatusIndicator(MessageModel message) {
    switch (message.status) {
      case MessageStatus.sending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Sending...',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        );

      case MessageStatus.sent:
        return Icon(Icons.done, size: 16, color: Colors.white70);

      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 16, color: Colors.white70);

      case MessageStatus.read:
        return Icon(Icons.done_all, size: 16, color: const Color(0xFF0D7FF2));

      case MessageStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red.shade200),
            const SizedBox(width: 4),
            Text(
              'Failed',
              style: TextStyle(color: Colors.red.shade200, fontSize: 11),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                // Retry sending the message
                if (message.id != null) {
                  ref
                      .read(messageNotifierProvider.notifier)
                      .sendMessage(
                        conversationId: widget.conversationId,
                        senderId: widget.senderId,
                        receiverId: widget.receiverId,
                        content: message.content ?? '',
                      );
                }
              },
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.blue.shade200,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
    }
  }

  String _formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${messageTime.day}/${messageTime.month}';
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF1C1C1E)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                keyboardType: TextInputType.text,
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to count unread messages
  int _getUnreadCount(List<MessageModel> messages) {
    return messages
        .where(
          (message) => message.senderId != widget.senderId && message.isUnread,
        )
        .length;
  }

  // Helper method to mark all messages as read
  Future<void> _markAllAsRead(List<MessageModel> messages) async {
    try {
      talker.info('Marking all messages as read');
      final messageNotifier = ref.read(messageNotifierProvider.notifier);

      for (final message in messages) {
        if (message.senderId != widget.senderId &&
            message.isUnread &&
            message.id != null) {
          await messageNotifier.markAsRead(message.id!);
        }
      }
    } catch (e, st) {
      talker.error('Error marking messages as read', e, st);
    }
  }
}
