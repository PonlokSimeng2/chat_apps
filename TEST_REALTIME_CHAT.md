# Testing Real-Time Chat Functionality

This guide will help you test the real-time chat features we've implemented.

## Prerequisites

1. **Two Simulators/Devices**: Set up two iOS simulators or physical devices
2. **Different User Accounts**: Use two different user accounts to test real-time messaging
3. **WebSocket Server**: Ensure your WebSocket server at `wss://desirable-moira-kfa-f246aea1.koyeb.app` is running

## Step-by-Step Testing

### 1. Basic Setup

1. **Install the App**: Install the chat app on both simulators/devices
2. **Login**: Log in with different user accounts on each device
3. **Navigate to Chat**: Open the chat list screen on both devices

### 2. Test Real-Time Messaging

1. **User A**: Send a message to User B
2. **User B**: Should receive the message instantly without refreshing
3. **User B**: Reply to the message
4. **User A**: Should receive the reply instantly

**Expected Results:**
- ✅ Messages appear in real-time on both devices
- ✅ No need to refresh the app
- ✅ Messages are saved to the database

### 3. Test Chat List Updates

1. **User A**: Send a new message to User B
2. **User B's Chat List**: Should show:
   - New message preview in the chat list
   - Updated unread count badge
   - Correct timestamp
   - "You:" prefix for sent messages

3. **User B**: Open the chat to read the message
4. **User B's Chat List**: Unread count should disappear
5. **User A's Chat List**: Should show read receipt (blue checkmarks)

**Expected Results:**
- ✅ Chat list updates in real-time
- ✅ Unread counts work correctly
- ✅ Message status indicators update

### 4. Test WebSocket Connection

1. **Monitor Console**: Watch the debug console for WebSocket messages
2. **Expected Messages**:
   ```
   WebSocket connected successfully
   Typing indicator: {user_id: xxx, is_typing: true}
   Typing indicator: {user_id: xxx, is_typing: false}
   User count update: {count: 2}
   System message: {message: "User joined"}
   ```

3. **Connection Loss**: Turn off WiFi/data on one device
4. **Reconnection**: Turn WiFi/data back on
5. **Auto-reconnect**: WebSocket should automatically reconnect

**Expected Results:**
- ✅ No "Unknown message type" errors
- ✅ WebSocket stays connected
- ✅ Auto-reconnection works after connection loss

### 5. Test Typing Indicators

1. **User A**: Start typing a message (don't send)
2. **User B**: Should see typing indicator (if implemented in UI)
3. **User A**: Stop typing for 3+ seconds
4. **User B**: Typing indicator should disappear

**Expected Results:**
- ✅ Typing events are sent/received via WebSocket
- ✅ Auto-stop after 3 seconds of inactivity
- ✅ Stop typing when message is sent

## Common Issues & Solutions

### Issue: "Unknown message type" errors
**Solution**: ✅ FIXED - We now handle `user_count`, `system`, and `connection_status` message types

### Issue: Chat list doesn't update in real-time
**Solution**: ✅ FIXED - Implemented real-time conversation provider with live updates

### Issue: WebSocket connection keeps dropping
**Solution**: ✅ FIXED - Added exponential backoff reconnection logic

### Issue: Messages don't sync between devices
**Solution**:
1. Check WebSocket server is running
2. Verify both users are authenticated
3. Check conversation IDs match
4. Monitor network connectivity

## Debug Mode

Enable detailed logging by running the app in debug mode:

```bash
flutter run --debug
```

Look for these log messages:
- `WebSocket connected successfully`
- `Message received via WebSocket`
- `Real-time chat list updated`
- `Typing indicator sent/received`

## Performance Testing

1. **Multiple Messages**: Send 10+ messages quickly
2. **Long Messages**: Test with long text content
3. **Multiple Conversations**: Test with multiple active chats
4. **Background/Foreground**: Test app switching behavior

## Server-Side Requirements

Your WebSocket server should:

1. **Accept Authentication**: Handle auth messages with tokens
2. **Route Messages**: Route messages to correct conversation participants
3. **Handle Types**: Support these message types:
   - `auth`: Authentication
   - `message`: New messages
   - `typing`: Typing indicators
   - `user_count`: Online user count
   - `system`: System notifications

**Expected Server Message Format:**
```json
{
  "type": "message",
  "data": {
    "id": 123,
    "conversation_id": 1,
    "sender_id": "user1",
    "receiver_id": "user2",
    "content": "Hello!",
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

## Success Criteria

✅ **Real-time Messaging**: Messages appear instantly across devices
✅ **Live Chat List**: Chat list updates without manual refresh
✅ **Unread Counts**: Accurate unread message tracking
✅ **Connection Stability**: Stable WebSocket connection with reconnection
✅ **No Error Messages**: No "Unknown message type" or connection errors

If all these tests pass, your real-time chat implementation is working correctly!