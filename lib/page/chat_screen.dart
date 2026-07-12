import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_apps/component/las_seen.dart';
import 'package:chat_apps/component/online_status_badge.dart';
import 'package:chat_apps/utils/responsive_helper.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../model/message_model.dart';
import '../model/message_status.dart';
import '../provider/message_provider.dart';
import '../provider/error_provider.dart';
import '../provider/emoji_provider.dart';
import '../provider/message_reactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String senderId;
  final String otherUserName;
  final String otherUserAvatar;
  final String receiverId;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.senderId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.isOnline = false,
    this.lastSeenAt,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;
  bool _hasScrolledToBottom = false;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    try {
      talker.info(
        'Initializing ChatScreen for conversation: ${widget.conversationId}',
      );
      Future.microtask(
        () => ref
            .read(messageProvider.notifier)
            .loadMessages(widget.conversationId, widget.receiverId),
      );
    } catch (e, st) {
      talker.error('Error initializing ChatScreen', e, st);
      ref
          .read(errorProvider.notifier)
          .addError(
            'Failed to load chat messages',
            details: e.toString(),
            severity: ErrorSeverity.error,
          );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    if (!mounted) return;
    void doScroll() {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: immediate
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => doScroll());
    });
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) return;

      setState(() => _isUploadingImage = true);
      await ref
          .read(messageProvider.notifier)
          .sendImageMessage(
            conversationId: widget.conversationId,
            senderId: widget.senderId,
            receiverId: widget.receiverId,
            imageFile: File(picked.path),
          );
      _scrollToBottom();
    } catch (e, st) {
      talker.error('Error sending image', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send image'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Photo Library',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    try {
      if (_messageController.text.trim().isEmpty) return;
      ref
          .read(messageProvider.notifier)
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Failed to send message'),
              const Spacer(),
              GestureDetector(
                onTap: _sendMessage,
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
        ),
      );
    }
  }

  void _handleEmojiReaction(String emoji, MessageModel message) {
    try {
      if (message.id == null) return;
      ref
          .read(messageReactionProvider.notifier)
          .toggleEmojiReaction(
            messageId: message.id!,
            emoji: emoji,
            currentUserId: widget.senderId,
          );
    } catch (e, st) {
      talker.error('Error reacting to message', e, st);
    }
  }

  String _formatDateSeparator(DateTime dateUtc) {
    final local = dateUtc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(messageDay).inDays;

    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final time = '$displayHour:$minute $period';

    if (diffDays == 0) return 'Today $time';
    if (diffDays == 1) return 'Yesterday $time';
    return '${local.day}/${local.month} $time';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messageProvider);
    ResponsiveHelper.getSmallAvatarSize(context);
    ref.listen<AsyncValue<List<MessageModel>>>(messageProvider, (_, next) {
      if (next is AsyncData) {
        final newCount = next.value?.length ?? 0;
        if (newCount > _previousMessageCount) {
          _previousMessageCount = newCount;
          _scrollToBottom();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 70, // ✅ give it more height
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // ✅ Use Row layout instead of Column — more like WhatsApp/Telegram style
        titleSpacing: 0, // ✅ remove extra left padding
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.otherUserAvatar,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 45,
                      height: 45,
                      color: Colors.grey[800],
                      child: const CircularProgressIndicator(
                        strokeWidth: 1,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 45,
                      height: 45,
                      color: Colors.blue[700],
                      child: Center(
                        child: Text(
                          widget.otherUserName.isNotEmpty
                              ? widget.otherUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: OnlineStatusBadge(
                    isOnline: widget.isOnline,
                    lastSeenAt: widget.lastSeenAt,
                    avatarSize: 45,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // ✅ Name and status next to avatar
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isOnline
                      ? 'Online'
                      : formatLastSeenShort(widget.lastSeenAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
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
          if (_isUploadingImage)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFF2C2C2E),
              color: Colors.blue,
              minHeight: 3,
            ),
          Expanded(
            child: messagesState.when(
              data: (messages) {
                if (!_hasScrolledToBottom && messages.isNotEmpty) {
                  _hasScrolledToBottom = true;
                  _previousMessageCount = messages.length;
                  _scrollToBottom();
                }
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSentByMe = message.senderId == widget.senderId;
                    final previous = index > 0 ? messages[index - 1] : null;

                    final showDateSeparator =
                        message.createdAt != null &&
                        (previous?.createdAt == null ||
                            !_isSameDay(
                              previous!.createdAt!,
                              message.createdAt!,
                            ));

                    final isFirstInGroup =
                        previous == null ||
                        previous.senderId != message.senderId ||
                        showDateSeparator;

                    return Column(
                      children: [
                        if (showDateSeparator && message.createdAt != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1E),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _formatDateSeparator(message.createdAt!),
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        MessageBubble(
                          key: ValueKey('msg_${message.uniqueId}'),
                          message: message,
                          isSentByMe: isSentByMe,
                          senderId: widget.senderId,
                          otherUserAvatar: widget.otherUserAvatar,
                          conversationId: widget.conversationId,
                          receiverId: widget.receiverId,
                          showAvatar: isFirstInGroup,
                          onLongPress: () =>
                              _showMessageOptions(context, message, isSentByMe),
                          onReact: (emoji) =>
                              _handleEmojiReaction(emoji, message),
                        ),
                      ],
                    );
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(color: Colors.black),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: _isUploadingImage ? null : _showImageSourceSheet,
              child: Icon(
                Icons.add,
                color: _isUploadingImage ? Colors.grey : Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.text,
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.mic_none, color: Colors.grey, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    MessageModel message,
    bool isSentByMe,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final emojisAsync = ref.watch(emojisProvider);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: emojisAsync.when(
                        loading: () => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        error: (_, __) => Row(
                          children: ['❤️', '😆', '😮', '😢', '😡', '👍']
                              .map(
                                (e) => GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _handleEmojiReaction(e, message);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      e,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        data: (emojis) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: emojis
                              .where((e) => e.category == 'reaction')
                              .map(
                                (e) => GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _handleEmojiReaction(e.emoji, message);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      e.emoji,
                                      style: TextStyle(
                                        fontSize:
                                            28 *
                                            (foundation.defaultTargetPlatform ==
                                                    TargetPlatform.iOS
                                                ? 1.20
                                                : 1.0),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showFullEmojiPicker(context, message);
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3A3A3C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: isSentByMe
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(right: 16, bottom: 8, left: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSentByMe ? Colors.blue : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.content ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildMessengerOption(
                      label: 'Reply',
                      icon: Icons.reply,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDivider(),
                    _buildMessengerOption(
                      label: 'Copy',
                      icon: Icons.copy,
                      onTap: () {
                        Navigator.pop(context);
                        Clipboard.setData(
                          ClipboardData(text: message.content ?? ''),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMessengerOption(
                      label: 'Delete',
                      icon: Icons.delete,
                      isDestructive: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDivider(),
                    _buildMessengerOption(
                      label: 'More',
                      icon: Icons.more_horiz,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          );
        },
      ),
    );
  }

  void _showFullEmojiPicker(BuildContext context, MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: 350,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            Navigator.pop(context);
            _handleEmojiReaction(emoji.emoji, message);
          },
          config: Config(
            height: 350,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              backgroundColor: const Color(0xFF2C2C2E),
              emojiSizeMax:
                  28 *
                  (foundation.defaultTargetPlatform == TargetPlatform.iOS
                      ? 1.20
                      : 1.0),
            ),
            searchViewConfig: const SearchViewConfig(
              backgroundColor: Color(0xFF2C2C2E),
              buttonIconColor: Colors.white,
            ),
            categoryViewConfig: const CategoryViewConfig(
              backgroundColor: Color(0xFF2C2C2E),
              iconColorSelected: Colors.blue,
              iconColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(
              backgroundColor: Color(0xFF2C2C2E),
              buttonIconColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessengerOption({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 16)),
            Icon(icon, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    thickness: 0.5,
    color: Colors.white12,
    indent: 20,
    endIndent: 20,
  );

  int _getUnreadCount(List<MessageModel> messages) =>
      messages.where((m) => m.senderId != widget.senderId && m.isUnread).length;

  Future<void> _markAllAsRead(List<MessageModel> messages) async {
    try {
      final notifier = ref.read(messageProvider.notifier);
      for (final message in messages) {
        if (message.senderId != widget.senderId &&
            message.isUnread &&
            message.id != null) {
          await notifier.markAsRead(message.id!);
        }
      }
    } catch (e, st) {
      talker.error('Error marking messages as read', e, st);
    }
  }
}

// ============================================
// MESSAGE BUBBLE
// ============================================
class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isSentByMe;
  final String senderId;
  final String otherUserAvatar;
  final int conversationId;
  final String receiverId;
  final bool showAvatar;
  final VoidCallback onLongPress;
  final void Function(String emoji) onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    required this.senderId,
    required this.otherUserAvatar,
    required this.conversationId,
    required this.receiverId,
    required this.onLongPress,
    required this.onReact,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isSentByMe && message.isUnread && message.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(messageProvider.notifier).markAsRead(message.id!);
      });
    }

    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar ? 12 : 4),
      child: Row(
        mainAxisAlignment: isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            SizedBox(
              width: 32,
              child: showAvatar
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(otherUserAvatar),
                      radius: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSentByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onLongPress: onLongPress,
                      child: message.messageType == 'image'
                          ? _ImageBubble(
                              message: message,
                              isSentByMe: isSentByMe,
                            )
                          : Container(
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                    if (message.id != null && !message.isTemp)
                      Positioned(
                        bottom: -14,
                        right: isSentByMe ? 8 : null,
                        left: isSentByMe ? null : 8,
                        child: _EmojiStackBadge(
                          messageId: message.id!,
                          senderId: senderId,
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
    switch (message.status) {
      case MessageStatus.sending:
        return Colors.blue.shade300;
      case MessageStatus.sent:
        return Colors.blue.shade600;
      case MessageStatus.delivered:
        return Colors.blue.shade700;
      case MessageStatus.read:
        return Colors.blue.shade600;
      case MessageStatus.failed:
        return Colors.red.shade400;
    }
  }
}

// ─── Image Bubble ─────────────────────────────────────────────────────────────
class _ImageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSentByMe;

  const _ImageBubble({required this.message, required this.isSentByMe});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    if (message.isTemp || message.fileUrl == null) {
      return Container(
        width: 220,
        height: 160,
        decoration: BoxDecoration(
          color: isSentByMe ? Colors.blue.shade300 : const Color(0xFF2C2C2E),
          borderRadius: borderRadius,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
              SizedBox(height: 8),
              Text(
                'Uploading...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          message.fileUrl!,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 220,
              height: 160,
              color: const Color(0xFF2C2C2E),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                  color: Colors.white70,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            width: 220,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: borderRadius,
            ),
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(child: Image.network(message.fileUrl!)),
          ),
        ),
      ),
    );
  }
}

// ─── Emoji Stack Badge ────────────────────────────────────────────────────────
class _EmojiStackBadge extends ConsumerWidget {
  final int messageId;
  final String senderId;

  const _EmojiStackBadge({required this.messageId, required this.senderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionsAsync = ref.watch(messageReactionsProvider(messageId));

    return reactionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reactions) {
        if (reactions.isEmpty) return const SizedBox.shrink();

        final uniqueEmojis = reactions
            .map((r) => r.emoji)
            .toSet()
            .take(3)
            .toList();
        final totalCount = reactions.length;
        final iReacted = reactions.any((r) => r.userId == senderId);
        final myEmoji = reactions
            .where((r) => r.userId == senderId)
            .firstOrNull
            ?.emoji;

        return GestureDetector(
          onTap: () {
            if (myEmoji != null) {
              ref
                  .read(messageReactionProvider.notifier)
                  .toggleEmojiReaction(
                    messageId: messageId,
                    emoji: myEmoji,
                    currentUserId: senderId,
                  );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: iReacted
                  ? const Color(0xFF1A237E)
                  : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: iReacted
                    ? const Color(0xFF0D7FF2)
                    : const Color(0xFF1a1a1a),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...uniqueEmojis.map(
                  (e) => Text(e, style: const TextStyle(fontSize: 13)),
                ),
                if (totalCount > 1) ...[
                  const SizedBox(width: 3),
                  Text(
                    '$totalCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: iReacted ? const Color(0xFF90CAF9) : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
