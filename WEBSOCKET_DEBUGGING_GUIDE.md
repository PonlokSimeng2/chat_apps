# WebSocket Real-Time Messaging Debugging Guide

## Issue Description

**Problem**: Users stay in the chat screen but don't receive new messages in real-time. Messages only appear when they navigate away and come back.

## Enhanced Debugging Features

I've added comprehensive logging to help identify the issue:

### 🔍 **What to Look For in Console Logs**

Run the app with `flutter run --debug` and watch for these specific log messages:

#### **1. Connection Logs**
```
✅ WebSocket: Connecting to conversation 1 for user user123
✅ WebSocket: Sending auth message: {type: auth, ...}
✅ WebSocket: Connected successfully to conversation 1
✅ WebSocket: 💓 Sent ping to maintain connection
```

#### **2. Message Reception Logs**
```
✅ WebSocket: Raw message received: {"type":"message","data":{...}}
✅ WebSocket: Processing message type: message
✅ WebSocket: 📨 Received message from user456 to user123 in conversation 1
✅ WebSocket: ✅ Message added to UI: Hello there!
```

#### **3. Error Logs to Watch For**
```
❌ WebSocket: Connection failed: error_message
❌ WebSocket: Failed to decode JSON message
❌ WebSocket: ❌ Error parsing message data
❌ WebSocket: ❌ Error sending ping message
```

## Step-by-Step Debugging Process

### **Step 1: Verify WebSocket Connection**

1. **Open chat screen** on both devices
2. **Check console** for connection logs:
   ```
   flutter run --debug
   ```
3. **Expected logs**:
   ```
   WebSocket: Connecting to conversation [ID]
   WebSocket: Connected successfully to conversation [ID]
   ```

### **Step 2: Test Message Flow**

**User A sends message:**
```
1. User A: WebSocket: 📨 Received message from userA to userB
2. User B: WebSocket: Raw message received: {"type":"message",...}
3. User B: WebSocket: 📨 Received message from userA to userB
4. User B: WebSocket: ✅ Message added to UI: [message content]
```

### **Step 3: Check Connection Health**

**Look for ping messages (every minute):**
```
WebSocket: 💓 Sent ping to maintain connection
WebSocket: Received pong from server
```

### **Step 4: Identify the Issue**

**If you see this pattern:**
```
✅ User A: Message appears immediately (optimistic UI)
❌ User B: No "Raw message received" logs
❌ User B: No "Message added to UI" logs
```

**The issue is likely:**
- WebSocket server not broadcasting to both participants
- Server not recognizing User B as active participant
- Network issues preventing message delivery

## Enhanced WebSocket Features Added

### **1. Better Connection Tracking**
```dart
int? _currentConversationId; // Track current conversation
```

### **2. Enhanced Logging**
```dart
print('WebSocket: 📨 Received message from ${newMessage.senderId} to ${newMessage.receiverId}');
print('WebSocket: ✅ Message added to UI: ${newMessage.content?.substring(0, 50)}');
```

### **3. Heartbeat System**
```dart
// Ping every minute to maintain connection
final pingMessage = {
  'type': 'ping',
  'timestamp': DateTime.now().toIso8601String(),
  'conversation_id': _currentConversationId,
};
```

### **4. Auto-Reconnection**
```dart
// Try to reconnect on ping failure
if (_currentConversationId != null) {
  _connectWebSocket(_currentConversationId!);
}
```

## Server-Side Requirements

Your WebSocket server must:

### **1. Accept Enhanced Authentication**
```json
{
  "type": "auth",
  "user_id": "user123",
  "conversation_id": 1,
  "token": "access_token",
  "subscribe_to_messages": true,
  "subscribe_to_typing": true
}
```

### **2. Broadcast to ALL Participants**
When User A sends a message, server should send to BOTH users:
```javascript
// BAD: Only sends back to sender
socket.emit('message', messageData);

// GOOD: Sends to all participants in conversation
io.to(`conversation_${conversationId}`).emit('message', {
  type: 'message',
  data: messageData
});
```

### **3. Handle Connection Events**
```javascript
socket.on('connect', () => {
  console.log('User connected:', socket.id);
});

socket.on('message', (data) => {
  const { type, conversation_id, user_id } = JSON.parse(data);

  if (type === 'auth') {
    // Join user to conversation room
    socket.join(`conversation_${conversation_id}`);
    console.log(`User ${user_id} joined conversation ${conversation_id}`);
  }
});
```

## Testing Scenarios

### **Test 1: Basic Real-time Messaging**
1. **Device A**: Send message "Hello World"
2. **Device B**: Should see logs: "Raw message received" → "Message added to UI"
3. **Result**: Message appears on Device B immediately

### **Test 2: Connection Stability**
1. Both devices stay in chat for 5+ minutes
2. Watch for ping/pong messages every minute
3. Verify connection stays active

### **Test 3: Message Broadcasting**
1. Device A sends multiple messages rapidly
2. Device B should receive all messages
3. No messages should be lost

### **Test 4: Reconnection**
1. Disconnect Device B's internet
2. Send message from Device A
3. Reconnect Device B
4. Device B should receive new messages automatically

## Common Issues & Solutions

### **Issue 1: No "Raw message received" logs**
**Cause**: WebSocket server not sending messages to receiver
**Solution**: Check server broadcasting logic

### **Issue 2: "Connection failed" logs**
**Cause**: Authentication or network issues
**Solution**: Verify tokens and server URL

### **Issue 3: Messages appear after navigation**
**Cause**: Only HTTP polling works, WebSocket fails
**Solution**: Check WebSocket server configuration

### **Issue 4: Ping messages fail**
**Cause**: Connection timeout or server issues
**Solution**: Auto-reconnection should handle this

## Quick Diagnostic Command

To test the WebSocket connection, run:
```bash
flutter run --debug
# Then open the chat screen and watch for these specific logs:
# 1. "WebSocket: Connecting to conversation"
# 2. "WebSocket: Connected successfully"
# 3. "WebSocket: 💓 Sent ping"
# 4. "WebSocket: Raw message received" (when other user sends message)
```

## Expected Console Output (Working Correctly)

```
Launching lib/main.dart on device...
WebSocket: Connecting to conversation 1 for user user123
WebSocket: Sending auth message: {type: auth, user_id: user123, ...}
WebSocket: Connected successfully to conversation 1
WebSocket: 💓 Sent ping to maintain connection
// User A sends message
WebSocket: Raw message received: {"type":"message","data":{...}}
WebSocket: Processing message type: message
WebSocket: 📨 Received message from user456 to user123 in conversation 1
WebSocket: ✅ Message added to UI: Hello there!
```

## If Still Not Working

1. **Check server logs** for message broadcasting
2. **Verify both users are in the same conversation_id**
3. **Test with a simple WebSocket client** to isolate the issue
4. **Check network connectivity** between devices and server

The enhanced logging should now help identify exactly where the real-time messaging is failing!