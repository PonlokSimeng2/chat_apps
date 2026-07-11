# Chat App Providers

This directory contains Riverpod providers for the chat application with Supabase and WebSocket integration.

## Provider Files

### 1. Message Provider (`message_provider.dart`)
Handles all message-related operations with real-time support.

#### Features:
- Load messages for a conversation
- Send new messages
- Edit existing messages
- Delete messages (soft delete)
- Mark messages as read
- Search messages
- Real-time updates via Supabase subscriptions
- Pagination support

#### Usage:
```dart
// Load messages for a conversation
ref.read(messageNotifierProvider.notifier).loadMessages(conversationId);

// Watch messages
final messagesAsync = ref.watch(messageNotifierProvider);

// Send a message
await ref.read(messageNotifierProvider.notifier).sendMessage(
  conversationId: 1,
  senderId: 'user123',
  content: 'Hello!',
);

// Edit a message
await ref.read(messageNotifierProvider.notifier).editMessage(
  messageId: 1,
  newContent: 'Updated message',
);

// Delete a message
await ref.read(messageNotifierProvider.notifier).deleteMessage(1);
```

### 2. Conversation Provider (`conversation_provider.dart`)
Manages conversations and participants with real-time updates.

#### Features:
- Load user conversations
- Create new conversations
- Update conversation details
- Leave conversations
- Add/remove participants
- Search conversations
- Get conversation by ID
- Real-time updates for conversation changes

#### Usage:
```dart
// Load user conversations
ref.read(conversationNotifierProvider.notifier).loadUserConversations(userId);

// Watch conversations
final conversationsAsync = ref.watch(conversationNotifierProvider);

// Create a new conversation
final conversation = await ref.read(conversationNotifierProvider.notifier).createConversation(
  name: 'Group Chat',
  createdBy: userId,
  description: 'Our group chat',
  participantIds: ['user1', 'user2'],
);

// Add a participant
await ref.read(conversationNotifierProvider.notifier).addParticipant(
  conversationId: 1,
  userId: 'newUser',
);
```

### 3. WebSocket Provider (`websocket_provider.dart`)
Provides real-time WebSocket communication with fallback to Supabase.

#### Features:
- WebSocket connection management
- Automatic reconnection with exponential backoff
- Heartbeat mechanism
- Message broadcasting
- Typing indicators
- Online/offline status
- Real-time message updates
- Connection status monitoring

#### Usage:
```dart
// Connect to WebSocket
ref.read(webSocketNotifierProvider.notifier).connect(
  userId: 'user123',
  token: 'auth_token',
  serverUrl: 'ws://localhost:8080',
);

// Watch connection status
final isConnected = ref.watch(isWebSocketConnectedProvider);

// Send a message via WebSocket
ref.read(webSocketNotifierProvider.notifier).sendMessage(
  conversationId: 1,
  senderId: 'user123',
  content: 'Hello!',
);

// Send typing indicator
ref.read(webSocketNotifierProvider.notifier).sendTypingIndicator(
  conversationId: 1,
  userId: 'user123',
  isTyping: true,
);

// Watch online users
final onlineUsers = ref.watch(onlineUsersProvider);

// Watch typing indicators
final typingUsers = ref.watch(typingUsersProvider);
```

## Database Schema Requirements

### Messages Table
```sql
CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  conversation_id INTEGER REFERENCES conversations(id),
  sender_id VARCHAR(255) NOT NULL,
  content TEXT,
  message_type VARCHAR(50) DEFAULT 'text',
  file_url VARCHAR(500),
  file_name VARCHAR(255),
  file_size INTEGER,
  reply_to_message_id INTEGER REFERENCES messages(id),
  is_edited BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Conversations Table
```sql
CREATE TABLE conversations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  description TEXT,
  created_by VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Conversation Participants Table
```sql
CREATE TABLE conversation_participants (
  id SERIAL PRIMARY KEY,
  conversation_id INTEGER REFERENCES conversations(id),
  user_id VARCHAR(255) NOT NULL,
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);
```

## WebSocket Message Types

### Client to Server:
- `connection` - Connect/disconnect
- `send_message` - Send a new message
- `typing` - Send typing indicator
- `mark_read` - Mark message as read

### Server to Client:
- `new_message` - New message received
- `message_updated` - Message was updated
- `message_deleted` - Message was deleted
- `typing` - User typing indicator
- `user_online` - User came online
- `user_offline` - User went offline
- `heartbeat` - Connection heartbeat
- `conversation_updated` - Conversation was updated

## Error Handling

All providers use `AsyncValue` to handle loading, error, and data states:

```dart
final messagesAsync = ref.watch(messageNotifierProvider);

messagesAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
  data: (messages) => ListView.builder(
    itemCount: messages.length,
    itemBuilder: (context, index) => MessageWidget(messages[index]),
  ),
);
```

## Real-time Updates

The providers use two mechanisms for real-time updates:

1. **Supabase Realtime Subscriptions**: Automatically sync database changes
2. **WebSocket**: Custom real-time events like typing indicators and online status

## Code Generation

Run the following command to generate provider code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Best Practices

1. **Always watch providers, don't call them directly in build methods**
2. **Handle loading and error states properly**
3. **Dispose of WebSocket connections when not needed**
4. **Use proper error handling for network operations**
5. **Implement proper authentication checks**
6. **Use appropriate pagination for large datasets**

## Example Widget Integration

```dart
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messageNotifierProvider);
    final isConnected = ref.watch(isWebSocketConnectedProvider);

    useEffect(() {
      // Load messages and connect WebSocket when screen opens
      ref.read(messageNotifierProvider.notifier).loadMessages(conversationId);
      ref.read(webSocketNotifierProvider.notifier).connect(
        userId: currentUserId,
        token: authToken,
      );

      return () {
        // Disconnect when screen closes
        ref.read(webSocketNotifierProvider.notifier).disconnect();
      };
    }, []);

    return Scaffold(
      body: messagesAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (messages) => Column(
          children: [
            // Connection status indicator
            if (!isConnected)
              Container(
                color: Colors.red,
                child: Text('Reconnecting...'),
              ),
            // Messages list
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) => MessageWidget(messages[index]),
              ),
            ),
            // Message input
            MessageInput(
              onSend: (content) {
                ref.read(messageNotifierProvider.notifier).sendMessage(
                  conversationId: conversationId,
                  senderId: currentUserId,
                  content: content,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```