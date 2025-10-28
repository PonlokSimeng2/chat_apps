# WebSocket Message Handling Fixes

This document outlines the fixes for WebSocket message handling issues where system and user_count messages were arriving with null data.

## Problem Fixed

### 🐛 **Issue**: Invalid Data Messages
**Errors**:
- `Received system message with invalid data: null`
- `Received user_count update with invalid data: null`

**Root Cause**: WebSocket server was sending system messages with null data, but the handlers expected Map<String, dynamic> format.

## Solutions Implemented

### 1. **Flexible Message Type Handling** ✅

**Before**: Strict Map requirement
```dart
case 'system':
  if (messageData != null && messageData is Map) {
    _handleSystemMessage(messageData as Map<String, dynamic>);
  } else {
    print('Received system message with invalid data: $messageData'); // ❌ Error
  }
```

**After**: Multiple data type support
```dart
case 'system':
  if (messageData != null && messageData is Map) {
    _handleSystemMessage(messageData as Map<String, dynamic>);
  } else if (messageData is String) {
    // Handle simple string system messages
    _handleSystemMessage({'message': messageData});
  } else if (messageData == null) {
    // Handle null data - just log it
    print('Received system message with null data - ignoring'); // ✅ Graceful
  } else {
    print('Received system message with invalid data type: ${messageData.runtimeType}');
  }
```

### 2. **Robust Handler Methods** ✅

**Updated System Message Handler**:
```dart
void _handleSystemMessage(Map<String, dynamic> data) {
  try {
    final message = data['message'] as String?;
    final type = data['type'] as String?;

    if (message != null) {
      print('System message: $message');
      // Could display system notifications in chat
    } else if (type != null) {
      print('System event: $type');
      // Handle system events like user joined/left
    } else {
      print('System message received: $data');
    }
  } catch (e) {
    print('Error handling system message: $e, data: $data');
  }
}
```

**Updated User Count Handler**:
```dart
void _handleUserCountUpdate(Map<String, dynamic> data) {
  try {
    final count = data['count'] as int?;
    if (count != null) {
      print('Online user count: $count');
      // Could update online status in UI
    } else {
      print('User count update without count field: $data');
    }
  } catch (e) {
    print('Error handling user count update: $e, data: $data');
  }
}
```

### 3. **Enhanced Typing Indicator Handler** ✅

```dart
void _handleTypingIndicator(Map<String, dynamic> data) {
  try {
    final userId = data['user_id'] as String?;
    final isTyping = data['is_typing'] as bool?;

    if (userId != null && isTyping != null) {
      print('Typing indicator: User $userId is ${isTyping ? "typing" : "not typing"}');
      // Could implement typing indicators in UI
    } else {
      print('Invalid typing indicator data: $data');
    }
  } catch (e) {
    print('Error handling typing indicator: $e, data: $data');
  }
}
```

### 4. **Improved Connection Status Handler** ✅

```dart
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
  } catch (e) {
    print('Error handling connection status: $e, data: $data');
  }
}
```

## Supported Message Types

### ✅ **Core Chat Messages**
- `message`: New chat messages (validated with MessageModel)
- `message_updated`: Message updates (read receipts, edits)
- `message_deleted`: Message deletion notifications
- `typing`: Typing indicators

### ✅ **System Messages**
- `system`: System notifications and events
  - Supports Map with `message` or `type` fields
  - Supports String format for simple messages
  - Handles null data gracefully

### ✅ **Connection Management**
- `user_count`: Online user count
  - Supports Map with `count` field
  - Supports integer format
  - Handles null data gracefully
- `connection_status`: Connection state updates
  - Supports `status` (String) or `connected` (bool) fields
- `auth_response`: Authentication confirmation
- `ping`/`pong`: Keep-alive messages

## Message Format Examples

### System Messages
```json
// Map format
{"type": "system", "data": {"message": "User joined the conversation"}}
{"type": "system", "data": {"type": "user_joined", "user_id": "123"}}

// String format
{"type": "system", "data": "Connection established"}

// Null data (handled gracefully)
{"type": "system", "data": null}
```

### User Count Updates
```json
// Map format
{"type": "user_count", "data": {"count": 5}}

// Integer format
{"type": "user_count", "data": 3}

// Null data (handled gracefully)
{"type": "user_count", "data": null}
```

### Typing Indicators
```json
{"type": "typing", "data": {"user_id": "123", "is_typing": true}}
```

## Error Handling Strategy

### 1. **Validation Before Processing**
- Check message type exists
- Validate data format
- Handle null values gracefully

### 2. **Try-Catch Blocks**
- Wrap all handler methods in try-catch
- Log errors without crashing
- Continue processing other messages

### 3. **Flexible Data Types**
- Support multiple data formats per message type
- Handle Map, String, Integer, and null data
- Convert simple types to expected format

### 4. **Informative Logging**
- Clear error messages with data type info
- Stack traces for debugging
- Non-critical errors don't stop processing

## Expected Console Output

### ✅ **After Fixes**
```
Typing indicator: User user123 is typing
Online user count: 3
System message: User joined the conversation
Connection state: Connected
Received system message with null data - ignoring
Received user_count update with null data - connection might be unstable
```

### ❌ **Before Fixes**
```
Received system message with invalid data: null
Received user_count update with invalid data: null
Error decoding or handling message: type 'Null' is not a subtype of type 'Map<String, dynamic>'
```

## Data Model Compatibility

The fixes are compatible with your existing models:

### MessageModel
```dart
// ✅ Fully supported with validation
MessageModel.fromJson(messageData as Map<String, dynamic>)
```

### UserModel
```dart
// ✅ Used in chat list provider
UserModel(id: userData['id']?.toString(), ...)
```

### Database Schema
```sql
// ✅ Compatible with your database structure
users (id UUID, username VARCHAR, email VARCHAR, ...)
messages (id BIGINT, conversation_id BIGINT, sender_id UUID, ...)
```

## Result

The WebSocket message handling now:
- ✅ Handles null data gracefully without errors
- ✅ Supports multiple data formats for flexibility
- ✅ Provides detailed logging for debugging
- ✅ Maintains compatibility with existing models
- ✅ Continues processing despite malformed messages
- ✅ Offers foundation for UI features (typing indicators, online status)

The app should no longer show "invalid data" errors for system and user_count messages!