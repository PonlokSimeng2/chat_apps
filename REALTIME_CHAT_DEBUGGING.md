# Real-Time Chat Debugging Guide

This document outlines debugging steps for resolving real-time messaging issues when users are in the same chat screen.

## Issue Description

**Problem**: When both users are in the same chat screen, new messages are not showing up in real-time for the receiving user.

## Root Cause Analysis

The issue is likely one of the following:

1. **WebSocket Server Configuration**: Server not properly broadcasting messages to all conversation participants
2. **Client-Side WebSocket Handling**: Client not properly processing incoming messages
3. **Authentication/Authorization**: User not properly authenticated for real-time updates
4. **Message Routing**: Messages not being routed to the correct conversation participants

## Debugging Steps

### 1. **Check WebSocket Connection Logs**

Look for these specific log messages:

```bash
flutter run --debug
```

**Expected logs:**
```
WebSocket: Connecting to conversation 1 for user user123
WebSocket: Sending auth message: {type: auth, user_id: user123, conversation_id: 1, ...}
WebSocket: Connected successfully to conversation 1
WebSocket: Received message from user456 to user123 in conversation 1
```

**Problem indicators:**
```
❌ No "Connecting to conversation" message
❌ "Connection failed" or "WebSocket closed"
❌ No "Received message" logs
❌ Authentication errors
```

### 2. **Test Message Flow**

**Test Scenario**: User A sends message to User B

**Expected flow:**
```
User A:
1. WebSocket: Sending auth message
2. WebSocket: Connected successfully
3. WebSocket: Message sent (via optimistic UI)
4. WebSocket: Message confirmed from server

User B:
1. WebSocket: Connecting to conversation 1
2. WebSocket: Connected successfully
3. WebSocket: Received message from user456 to user123 in conversation 1
4. Message appears in UI immediately
```

### 3. **Check WebSocket Server Requirements**

Your WebSocket server should support:

#### **Authentication Message Format**
```json
{
  "type": "auth",
  "user_id": "user_id_here",
  "conversation_id": 123,
  "token": "access_token_here",
  "subscribe_to_messages": true,
  "subscribe_to_typing": true
}
```

#### **Message Broadcasting**
When User A sends a message, the server should send to BOTH User A and User B:
```json
{
  "type": "message",
  "data": {
    "id": 123,
    "conversation_id": 1,
    "sender_id": "user456",
    "receiver_id": "user123",
    "content": "Hello!",
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

### 4. **Verify WebSocket URL Parameters**

The client connects with these parameters:
```dart
final wsUrl = Uri.parse('wss://desirable-moira-kfa-f246aea1.koyeb.app').replace(
  queryParameters: {
    'conversation_id': conversationId.toString(),
    'user_id': currentUser.id,
    'token': _client.auth.currentSession?.accessToken ?? '',
    'subscribe_to_conversation': 'true',
  },
);
```

### 5. **Check Message Processing Logic**

The client processes messages like this:
```dart
case 'message':
  if (messageData != null && messageData is Map) {
    final newMessage = MessageModel.fromJson(messageData);
    print('WebSocket: Received message from ${newMessage.senderId} to ${newMessage.receiverId}');
    addMessage(newMessage); // This should add to UI
  }
```

## Common Issues & Solutions

### **Issue 1: Messages Only Appear for Sender**
**Cause**: Server only sending messages back to sender
**Solution**: Ensure server broadcasts to ALL participants in the conversation

### **Issue 2: No WebSocket Connection**
**Cause**: Authentication failure or server unreachable
**Solution**: Check token validity and server URL

### **Issue 3: Messages Appear Late**
**Cause**: WebSocket delay or server processing delay
**Solution**: Check server performance and WebSocket message queue

### **Issue 4: Messages Don't Appear at All**
**Cause**: Client not properly subscribing to conversation
**Solution**: Verify `subscribe_to_conversation` parameter

## Testing Checklist

### **Connection Tests**
- [ ] Both users can connect to WebSocket
- [ ] Authentication succeeds for both users
- [ ] Connection stays stable

### **Message Tests**
- [ ] User A sends message → appears immediately
- [ ] User B receives message → appears immediately
- [ ] Message content matches exactly
- [ ] Timestamps are correct

### **Real-time Tests**
- [ ] Messages appear while both users are in chat
- [ ] Messages appear when users navigate to chat
- [ ] Connection recovers after network issues

## Enhanced WebSocket Client Features

### **Improved Connection**
```dart
// Enhanced authentication
final authMessage = {
  'type': 'auth',
  'user_id': currentUser.id,
  'conversation_id': conversationId,
  'token': _client.auth.currentSession?.accessToken,
  'subscribe_to_messages': true,
  'subscribe_to_typing': true,
};

// Connection status monitoring
_wsChannel!.ready.then((_) {
  print('WebSocket: Connected successfully to conversation $conversationId');
});
```

### **Better Message Handling**
```dart
case 'message':
  final newMessage = MessageModel.fromJson(messageData);
  print('WebSocket: Received message from ${newMessage.senderId} to ${newMessage.receiverId} in conversation ${newMessage.conversationId}');
  addMessage(newMessage); // Works for both sender and receiver
```

### **Additional Message Types**
- `auth_response`: Authentication confirmation
- `message_received`: Message received confirmation
- `conversation_joined`: Conversation joined notification
- `ping`/`pong`: Keep-alive messages

## Server-Side Implementation

Your WebSocket server should:

1. **Accept Authentication**: Validate tokens and user permissions
2. **Join Conversations**: Allow users to subscribe to specific conversations
3. **Broadcast Messages**: Send messages to ALL participants in a conversation
4. **Handle Real-time Events**: Support typing indicators, read receipts, etc.

### **Example Server Logic**
```javascript
// When user connects to WebSocket
socket.on('message', (data) => {
  const { type, user_id, conversation_id, token } = JSON.parse(data);

  if (type === 'auth') {
    // Validate token and user
    const user = validateToken(token);
    if (user && canAccessConversation(user, conversation_id)) {
      // Join user to conversation room
      socket.join(`conversation_${conversation_id}`);

      // Send confirmation
      socket.send(JSON.stringify({
        type: 'auth_response',
        data: { status: 'success', conversation_id }
      }));
    }
  }
});

// When user sends message
socket.on('message', (data) => {
  const { type, data: messageData } = JSON.parse(data);

  if (type === 'message') {
    // Save to database
    const savedMessage = await saveMessage(messageData);

    // Broadcast to ALL users in conversation
    io.to(`conversation_${savedMessage.conversation_id}`).emit('message', {
      type: 'message',
      data: savedMessage
    });
  }
});
```

## Expected Results

After fixing the issue:

1. **✅ Both users connect successfully to WebSocket**
2. **✅ Messages appear immediately for both sender and receiver**
3. **✅ Real-time updates work while users are in chat**
4. **✅ Connection remains stable**
5. **✅ Clear debugging logs help identify issues**

## Troubleshooting

If messages still don't appear:

1. **Check Server Logs**: Verify server is receiving and broadcasting messages
2. **Check Network**: Ensure WebSocket server is reachable
3. **Check Authentication**: Verify tokens are valid and not expired
4. **Check Conversation IDs**: Ensure both users are using the same conversation_id
5. **Test with Simple Messages**: Try sending plain text messages first

The enhanced WebSocket implementation should provide clear debugging information to help identify any remaining issues.