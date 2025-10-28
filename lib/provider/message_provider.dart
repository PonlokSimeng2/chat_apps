import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../model/message_model.dart';
import '../model/message_status.dart';

part 'message_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageNotifier extends _$MessageNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  WebSocketChannel? _wsChannel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _baseReconnectDelay = 2000; // 2 seconds
  static const Duration _pingInterval = Duration(minutes: 1); // Keep-alive ping

  @override
  AsyncValue<List<MessageModel>> build() {
    ref.onDispose(() {
      _wsChannel?.sink.close();
      _reconnectTimer?.cancel();
      _pingTimer?.cancel();
    });
    return const AsyncValue.data([]);
  }

  void _connectWebSocket(int conversationId) {
    // Close any existing channel
    _wsChannel?.sink.close();

    // Reset reconnection state on successful connection
    _resetReconnectionState();

    // Start ping timer for connection keep-alive
    _startPingTimer();

    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      print('User not authenticated for WebSocket connection');
      return;
    }

    // Connect to the WebSocket server with authentication and conversation context
    final wsUrl = Uri.parse('wss://desirable-moira-kfa-f246aea1.koyeb.app').replace(
      queryParameters: {
        'conversation_id': conversationId.toString(),
        'user_id': currentUser.id,
        'token': _client.auth.currentSession?.accessToken ?? '',
        'subscribe_to_conversation': 'true', // Explicit subscription to conversation
      },
    );

    print('WebSocket: Connecting to conversation $conversationId for user ${currentUser.id}');
    _wsChannel = WebSocketChannel.connect(wsUrl);

    // Send authentication message upon connection
    final authMessage = {
      'type': 'auth',
      'user_id': currentUser.id,
      'conversation_id': conversationId,
      'token': _client.auth.currentSession?.accessToken,
      'subscribe_to_messages': true, // Subscribe to all messages in this conversation
      'subscribe_to_typing': true, // Subscribe to typing indicators
    };

    print('WebSocket: Sending auth message: ${authMessage.toString()}');
    _wsChannel!.sink.add(jsonEncode(authMessage));

    // Listen for connection success
    _wsChannel!.ready.then((_) {
      print('WebSocket: Connected successfully to conversation $conversationId');
    }).catchError((error) {
      print('WebSocket: Connection failed: $error');
    });

    // Listen to incoming messages
    _wsChannel!.stream.listen(
      (message) {
        try {
          if (message.isEmpty || message.trim().isEmpty) {
            print('Received empty WebSocket message, ignoring');
            return;
          }

          dynamic decodedMessage;
          try {
            decodedMessage = jsonDecode(message);
          } catch (e) {
            print('Failed to decode JSON message: $message, error: $e');
            return;
          }

          // Validate message structure
          if (decodedMessage == null) {
            print('Received null WebSocket message, ignoring');
            return;
          }

          if (decodedMessage is! Map) {
            print('Received non-map WebSocket message: $decodedMessage, type: ${decodedMessage.runtimeType}');
            return;
          }

          final messageType = decodedMessage['type'] as String?;
          final messageData = decodedMessage['data'];

          if (messageType == null) {
            print('Received WebSocket message without type: $decodedMessage');
            return;
          }

          // Handle different message types with proper validation
          switch (messageType) {
            case 'message':
              if (messageData != null && messageData is Map) {
                try {
                  final newMessage = MessageModel.fromJson(messageData as Map<String, dynamic>);
                  print('WebSocket: Received message from ${newMessage.senderId} to ${newMessage.receiverId} in conversation ${newMessage.conversationId}');

                  // Always add the message - this will work for both sender and receiver
                  addMessage(newMessage);
                } catch (e) {
                  print('Error parsing message data: $messageData, error: $e');
                }
              } else {
                print('Received message with invalid data: $messageData');
              }
              break;

            case 'message_updated':
              if (messageData != null && messageData is Map) {
                try {
                  final updatedMessage = MessageModel.fromJson(messageData as Map<String, dynamic>);
                  updateMessage(updatedMessage);
                } catch (e) {
                  print('Error parsing updated message data: $messageData, error: $e');
                }
              } else {
                print('Received message_updated with invalid data: $messageData');
              }
              break;

            case 'message_deleted':
              if (messageData != null && messageData is Map) {
                final messageId = messageData['message_id'];
                if (messageId != null && messageId is int) {
                  deleteMessage(messageId);
                } else {
                  print('Received message_deleted with invalid message_id: $messageId');
                }
              } else {
                print('Received message_deleted with invalid data: $messageData');
              }
              break;

            case 'typing':
              if (messageData != null && messageData is Map) {
                _handleTypingIndicator(messageData as Map<String, dynamic>);
              } else if (messageData == null) {
                // Handle null data silently - server might send empty typing updates
                // print('Received typing indicator with null data - ignoring');
              } else {
                print('Received typing indicator with invalid data type: ${messageData.runtimeType}, data: $messageData');
              }
              break;

            case 'user_count':
              if (messageData != null && messageData is Map) {
                _handleUserCountUpdate(messageData as Map<String, dynamic>);
              } else if (messageData is int) {
                // Handle simple integer count
                _handleUserCountUpdate({'count': messageData});
              } else if (messageData == null) {
                // Handle null data silently - server might send empty updates
                // print('Received user_count update with null data - connection might be unstable');
              } else {
                print('Received user_count update with invalid data type: ${messageData.runtimeType}, data: $messageData');
              }
              break;

            case 'system':
              if (messageData != null && messageData is Map) {
                _handleSystemMessage(messageData as Map<String, dynamic>);
              } else if (messageData is String) {
                // Handle simple string system messages
                _handleSystemMessage({'message': messageData});
              } else if (messageData == null) {
                // Handle null data silently - server might send empty updates
                // print('Received system message with null data - ignoring');
              } else {
                print('Received system message with invalid data type: ${messageData.runtimeType}, data: $messageData');
              }
              break;

            case 'connection_status':
              if (messageData != null && messageData is Map) {
                _handleConnectionStatus(messageData as Map<String, dynamic>);
              } else if (messageData == null) {
                // Handle null data silently - server might send empty status updates
                // print('Received connection status with null data - ignoring');
              } else {
                print('Received connection status with invalid data type: ${messageData.runtimeType}, data: $messageData');
              }
              break;

            case 'auth_response':
              // Handle authentication response
              if (messageData != null) {
                print('WebSocket authentication response: $messageData');
              } else {
                print('WebSocket authentication response: null - connection established');
              }
              break;

            case 'message_received':
              // Handle message received confirmation
              if (messageData != null && messageData is Map) {
                print('WebSocket: Message received confirmation: $messageData');
              }
              break;

            case 'conversation_joined':
              // Handle conversation joined notification
              if (messageData != null && messageData is Map) {
                print('WebSocket: Joined conversation: $messageData');
              }
              break;

            case 'ping':
              // Handle ping messages (keep-alive)
              _sendPongMessage();
              break;

            case 'pong':
              // Handle pong responses
              print('Received pong from server');
              break;

            default:
              print('Unknown message type: $messageType, data: $messageData');
          }
        } catch (e, stackTrace) {
          print('Error handling WebSocket message: $e\nStack trace: $stackTrace');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        // Attempt to reconnect with exponential backoff
        _scheduleReconnect(conversationId);
      },
      onDone: () {
        print('WebSocket closed');
        // Attempt to reconnect with exponential backoff
        _scheduleReconnect(conversationId);
      },
    );
  }

  void _handleTypingIndicator(Map<String, dynamic> data) {
    try {
      final userId = data['user_id'] as String?;
      final isTyping = data['is_typing'] as bool?;

      if (userId != null && isTyping != null) {
        print('Typing indicator: User $userId is ${isTyping ? "typing" : "not typing"}');

        // You could use this to show typing indicators in the UI
        // For example: _updateTypingStatus(userId, isTyping);

        // If you want to implement typing indicators, you could:
        // 1. Store typing status in a state management system
        // 2. Update the UI to show "User is typing..."
        // 3. Clear typing status after a timeout
      } else {
        print('Invalid typing indicator data: $data');
      }
    } catch (e) {
      print('Error handling typing indicator: $e, data: $data');
    }
  }

  void _handleUserCountUpdate(Map<String, dynamic> data) {
    try {
      final count = data['count'] as int?;
      if (count != null) {
        print('Online user count: $count');
        // You could use this to update online status in the UI
        // For example: _updateOnlineUserCount(count);
      } else {
        print('User count update without count field: $data');
      }
    } catch (e) {
      print('Error handling user count update: $e, data: $data');
    }
  }

  void _handleSystemMessage(Map<String, dynamic> data) {
    try {
      final message = data['message'] as String?;
      final type = data['type'] as String?;

      if (message != null) {
        print('System message: $message');
        // You could display system notifications in the chat
        // For example: _addSystemMessageToChat(message);
      } else if (type != null) {
        print('System event: $type');
        // Handle system events like user joined/left
        // For example: _handleSystemEvent(type, data);
      } else {
        print('System message received: $data');
      }
    } catch (e) {
      print('Error handling system message: $e, data: $data');
    }
  }

  void _handleConnectionStatus(Map<String, dynamic> data) {
    try {
      final status = data['status'] as String?;
      final connected = data['connected'] as bool?;

      if (status != null) {
        print('Connection status: $status');
      } else if (connected != null) {
        print('Connection state: ${connected ? "Connected" : "Disconnected"}');
      } else {
        print('Connection status update: $data');
      }
      // You could use this to show connection status in the UI
      // For example: _updateConnectionStatus(status);
    } catch (e) {
      print('Error handling connection status: $e, data: $data');
    }
  }

  void _scheduleReconnect(int conversationId) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached. Giving up.');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = _baseReconnectDelay * (1 << _reconnectAttempts); // Exponential backoff

    print('Scheduling reconnection attempt ${_reconnectAttempts + 1} in ${delay}ms');

    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      _reconnectAttempts++;
      if (state.value != null) { // Only reconnect if we have messages loaded
        print('Attempting to reconnect...');
        _connectWebSocket(conversationId);
      }
    });
  }

  void _resetReconnectionState() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
  }

  void _sendPongMessage() {
    if (_wsChannel != null) {
      try {
        _wsChannel!.sink.add(jsonEncode({
          'type': 'pong',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      } catch (e) {
        print('Error sending pong message: $e');
      }
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_wsChannel != null) {
        try {
          _wsChannel!.sink.add(jsonEncode({
            'type': 'ping',
            'timestamp': DateTime.now().toIso8601String(),
          }));
        } catch (e) {
          print('Error sending ping message: $e');
        }
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> loadMessages(int conversationId) async {
    state = const AsyncValue.loading();

    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      state = AsyncValue.data(messages);

      // Setup WebSocket connection
      _connectWebSocket(conversationId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Public method to add message (for WebSocket integration)
  void addMessage(MessageModel message) {
    final currentData = state.value ?? [];

    // Check if message already exists to avoid duplicates
    final existingMessageIndex = currentData.indexWhere((msg) =>
        (msg.id != null && msg.id == message.id) ||
        (msg.tempId != null && msg.tempId == message.tempId));

    if (existingMessageIndex != -1) {
      // Update existing message (useful for updating status of temp messages)
      final updatedList = [...currentData];
      updatedList[existingMessageIndex] = message;
      state = AsyncValue.data(updatedList);
    } else {
      // Add new message
      state = AsyncValue.data([...currentData, message]);
    }
  }

  // Public method to update message (for WebSocket integration)
  void updateMessage(MessageModel message) {
    final currentData = state.value ?? [];
    final updatedList = currentData.map((msg) {
      return msg.id == message.id ? message : msg;
    }).toList();
    state = AsyncValue.data(updatedList);
  }

  // Public method to delete message (for WebSocket integration)
  void deleteMessage(int messageId) {
    final currentData = state.value ?? [];
    final filteredList = currentData
        .where((msg) => msg.id != messageId)
        .toList();
    state = AsyncValue.data(filteredList);
  }

  Future<void> sendMessage({
    required int conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
    String? fileName,
    int? fileSize,
    int? replyToMessageId,
  }) async {
    // 1. Create temporary message for optimistic UI update
    final tempMessage = MessageModel.createTemp(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      messageType: messageType,
    );

    // 2. Add temporary message to UI immediately
    addMessage(tempMessage);

    try {
      // 3. Send message to server
      final newMessageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'reply_to_message_id': replyToMessageId,
        'is_edited': false,
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values
      newMessageData.removeWhere((key, value) => value == null);

      final response = await _client
          .from('messages')
          .insert(newMessageData)
          .select()
          .single();

      // 4. Create permanent message from server response
      final permanentMessage = MessageModel.fromJson(response).copyWith(
        tempId: tempMessage.tempId, // Keep tempId for replacement
        status: MessageStatus.sent,
      );

      // 5. Send the persisted message over WebSocket
      _wsChannel?.sink.add(jsonEncode({
        'type': 'message',
        'data': response,
      }));

      // 6. Replace temporary message with permanent one
      addMessage(permanentMessage);
    } catch (e) {
      // 7. Handle send failure - update message status to failed
      final failedMessage = tempMessage.copyWith(status: MessageStatus.failed);
      addMessage(failedMessage);

      // Optionally remove failed message after a delay
      Future.delayed(const Duration(seconds: 5), () {
        final currentData = state.value ?? [];
        final updatedList = currentData.where((msg) => msg.uniqueId != tempMessage.uniqueId).toList();
        state = AsyncValue.data(updatedList);
      });

      throw Exception('Failed to send message: $e');
    }
  }

  Future<MessageModel> editMessage({
    required int messageId,
    required String newContent,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .select()
          .single();

      final updatedMessage = MessageModel.fromJson(response);

      // Update local state immediately
      updateMessage(updatedMessage);

      return updatedMessage;
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  Future<void> deleteMessagePermanently(int messageId) async {
    try {
      await _client
          .from('messages')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);

      // Update local state immediately
      deleteMessage(messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> markAsRead(int messageId) async {
    try {
      await _client
          .from('messages')
          .update({
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      // Don't throw error for read receipts as they're not critical
      print('Failed to mark message as read: $e');
    }
  }

  Future<void> markAllMessagesAsRead({
    required String userId,
    required int conversationId,
  }) async {
    try {
      await _client
          .from('messages')
          .update({
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .filter('read_at', 'is', null);
    } catch (e) {
      // Don't throw error for read receipts as they're not critical
      print('Failed to mark all messages as read: $e');
    }
  }

  Future<List<MessageModel>> searchMessages({
    required int conversationId,
    required String query,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Get messages for a specific conversation
  List<MessageModel> getMessagesForConversation(int conversationId) {
    final allMessages = state.value ?? [];
    return allMessages
        .where(
          (msg) =>
              msg.conversationId == conversationId && msg.isDeleted != true,
        )
        .toList();
  }

  Future<int> getUnreadMessageCount({
    required String userId,
    required int conversationId,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_deleted', false)
          .filter('read_at', 'is', null)
          .count();
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<MessageModel?> getLastMessage({required int conversationId}) async {
    try {
      final response = await _client
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? MessageModel.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  // Send typing indicator
  void sendTypingIndicator({
    required int conversationId,
    required bool isTyping,
  }) {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return;

    _wsChannel?.sink.add(jsonEncode({
      'type': 'typing',
      'data': {
        'user_id': currentUser.id,
        'conversation_id': conversationId,
        'is_typing': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      },
    }));
  }

  // Clear all messages (useful when logging out)
  void clearMessages() {
    state = const AsyncValue.data([]);
  }

  // Disconnect WebSocket
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _wsChannel?.sink.close();
    _wsChannel = null;
    _resetReconnectionState();
  }
}

// Convenience providers
@riverpod
class MessagePagination extends _$MessagePagination {
  final int _limit = 50;
  int _offset = 0;
  bool _hasMore = true;
  int? _currentConversationId;

  @override
  AsyncValue<List<MessageModel>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> loadMoreMessages(int conversationId) async {
    if (!_hasMore) return;

    // If conversation changed, reset pagination
    if (_currentConversationId != conversationId) {
      _offset = 0;
      _hasMore = true;
      _currentConversationId = conversationId;
      state = const AsyncValue.data([]);
    }

    state = const AsyncValue.loading();

    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      final newMessages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      // Reverse to maintain chronological order
      final chronologicalMessages = newMessages.reversed.toList();

      if (newMessages.length < _limit) {
        _hasMore = false;
      }

      _offset += newMessages.length;

      state = AsyncValue.data([...state.value ?? [], ...chronologicalMessages]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    _offset = 0;
    _hasMore = true;
    _currentConversationId = null;
    state = const AsyncValue.data([]);
  }

  bool get hasMore => _hasMore;
}
