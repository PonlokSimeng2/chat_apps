# Complete Chat App Architecture - Flutter + Supabase + Riverpod

## Phase 1: Project Foundation & Planning

### Step 1: Define Requirements
- **Core Features:**
  - User authentication (signup/login)
  - One-on-one messaging
  - Group chats
  - Real-time message delivery
  - Message history
  - Online/offline status
  - Read receipts
  - File/image sharing
  - Push notifications

### Step 2: Technology Stack ✅

**Frontend:**
- Flutter (cross-platform mobile app)
- Riverpod (state management)
- go_router (navigation)
- freezed (immutable models)
- flutter_hooks (UI logic)

**Backend:**
- Supabase (PostgreSQL + Auth + Storage + Realtime)
- Supabase Realtime (WebSocket channels)
- Supabase Storage (file uploads)
- Supabase Edge Functions (serverless functions if needed)

**Additional Packages:**
- supabase_flutter (official SDK)
- image_picker (image selection)
- file_picker (file selection)
- cached_network_image (image caching)
- flutter_local_notifications (push notifications)
- timeago (relative timestamps)

---

## Phase 2: Supabase Backend Setup

### Step 3: Create Supabase Project
1. Go to supabase.com and create new project
2. Note your project URL and anon key
3. Wait for database to initialize

### Step 4: Design Database Schema

**Create Tables in Supabase SQL Editor:**

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'away')),
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations table
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL CHECK (type IN ('direct', 'group')),
  name TEXT,
  avatar_url TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversation participants
CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id),
  content TEXT,
  type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'file', 'audio')),
  file_url TEXT,
  reply_to UUID REFERENCES messages(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message read receipts
CREATE TABLE message_reads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- Typing indicators (ephemeral, can use Realtime Presence instead)
CREATE TABLE typing_indicators (
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_conversation_participants_user ON conversation_participants(user_id);
CREATE INDEX idx_message_reads_message ON message_reads(message_id);
```

### Step 5: Set Up Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Conversations policies
CREATE POLICY "Users can view their conversations" ON conversations FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_id = id AND user_id = auth.uid()
  )
);

CREATE POLICY "Users can create conversations" ON conversations FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- Participants policies
CREATE POLICY "Users can view participants of their conversations" ON conversation_participants FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM conversation_participants cp 
    WHERE cp.conversation_id = conversation_id AND cp.user_id = auth.uid()
  )
);

-- Messages policies
CREATE POLICY "Users can view messages in their conversations" ON messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
  )
);

CREATE POLICY "Users can insert messages in their conversations" ON messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
  )
);

-- Message reads policies
CREATE POLICY "Users can view read receipts in their conversations" ON message_reads FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM messages m
    JOIN conversation_participants cp ON m.conversation_id = cp.conversation_id
    WHERE m.id = message_id AND cp.user_id = auth.uid()
  )
);

CREATE POLICY "Users can mark messages as read" ON message_reads FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

### Step 6: Create Database Functions

```sql
-- Function to get user's conversations with last message
CREATE OR REPLACE FUNCTION get_user_conversations(user_uuid UUID)
RETURNS TABLE (
  conversation_id UUID,
  conversation_type TEXT,
  conversation_name TEXT,
  conversation_avatar TEXT,
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  last_message_sender UUID,
  unread_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.type,
    c.name,
    c.avatar_url,
    m.content,
    m.created_at,
    m.sender_id,
    COUNT(DISTINCT m2.id) FILTER (
      WHERE m2.sender_id != user_uuid 
      AND NOT EXISTS (
        SELECT 1 FROM message_reads mr 
        WHERE mr.message_id = m2.id AND mr.user_id = user_uuid
      )
    ) as unread_count
  FROM conversations c
  INNER JOIN conversation_participants cp ON c.id = cp.conversation_id
  LEFT JOIN LATERAL (
    SELECT * FROM messages 
    WHERE conversation_id = c.id 
    ORDER BY created_at DESC LIMIT 1
  ) m ON true
  LEFT JOIN messages m2 ON m2.conversation_id = c.id
  WHERE cp.user_id = user_uuid
  GROUP BY c.id, c.type, c.name, c.avatar_url, m.content, m.created_at, m.sender_id
  ORDER BY m.created_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Function to create direct conversation
CREATE OR REPLACE FUNCTION create_direct_conversation(
  user1_id UUID,
  user2_id UUID
)
RETURNS UUID AS $$
DECLARE
  conversation_id UUID;
  existing_conversation UUID;
BEGIN
  -- Check if conversation already exists
  SELECT c.id INTO existing_conversation
  FROM conversations c
  WHERE c.type = 'direct'
    AND EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = c.id AND user_id = user1_id
    )
    AND EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = c.id AND user_id = user2_id
    );
  
  IF existing_conversation IS NOT NULL THEN
    RETURN existing_conversation;
  END IF;
  
  -- Create new conversation
  INSERT INTO conversations (type, created_by)
  VALUES ('direct', user1_id)
  RETURNING id INTO conversation_id;
  
  -- Add participants
  INSERT INTO conversation_participants (conversation_id, user_id)
  VALUES (conversation_id, user1_id), (conversation_id, user2_id);
  
  RETURN conversation_id;
END;
$$ LANGUAGE plpgsql;
```

### Step 7: Set Up Supabase Storage

```sql
-- Create storage bucket for chat files
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-files', 'chat-files', true);

-- Storage policies
CREATE POLICY "Users can upload chat files" ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chat-files' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Anyone can view chat files" ON storage.objects FOR SELECT
USING (bucket_id = 'chat-files');
```

### Step 8: Enable Realtime

In Supabase Dashboard:
1. Go to Database → Replication
2. Enable replication for: `messages`, `typing_indicators`, `profiles`
3. Or use SQL:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_indicators;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
```

---

## Phase 3: Flutter Project Setup

### Step 9: Create Flutter Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   │   └── supabase_config.dart
│   ├── constants/
│   │   └── app_constants.dart
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── models/
│   │   │       └── user_model.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── register_page.dart
│   │       └── widgets/
│   ├── chat/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   ├── conversation_repository.dart
│   │   │   │   └── message_repository.dart
│   │   │   └── models/
│   │   │       ├── conversation_model.dart
│   │   │       ├── message_model.dart
│   │   │       └── participant_model.dart
│   │   ├── providers/
│   │   │   ├── conversation_provider.dart
│   │   │   ├── message_provider.dart
│   │   │   └── typing_provider.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── chat_list_page.dart
│   │       │   └── chat_room_page.dart
│   │       └── widgets/
│   │           ├── conversation_tile.dart
│   │           ├── message_bubble.dart
│   │           ├── message_input.dart
│   │           └── typing_indicator.dart
│   └── profile/
│       ├── data/
│       ├── providers/
│       └── presentation/
└── shared/
    ├── widgets/
    ├── utils/
    └── extensions/
```

### Step 10: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Supabase
  supabase_flutter: ^2.0.0
  
  # Models & Serialization
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # Navigation
  go_router: ^12.0.0
  
  # UI
  flutter_hooks: ^0.20.3
  hooks_riverpod: ^2.4.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.4
  file_picker: ^6.0.0
  
  # Utilities
  timeago: ^3.5.0
  uuid: ^4.1.0
  intl: ^0.18.1
  
  # Notifications
  flutter_local_notifications: ^16.1.0

dev_dependencies:
  build_runner: ^2.4.6
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.0
```

### Step 11: Initialize Supabase

```dart
// lib/core/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }
}

// Helper to get Supabase client
final supabase = Supabase.instance.client;
```

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

---

## Phase 4: Authentication Implementation

### Step 12: Create User Model

```dart
// lib/features/auth/data/models/user_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String username,
    String? avatarUrl,
    @Default('offline') String status,
    DateTime? lastSeen,
    required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

### Step 13: Create Auth Repository

```dart
// lib/features/auth/data/repositories/auth_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/user_model.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository();
}

class AuthRepository {
  final SupabaseClient _supabase = supabase;

  // Sign up
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to create user');
    }

    // Create profile
    await _supabase.from('profiles').insert({
      'id': response.user!.id,
      'username': username,
    });

    return await getProfile(response.user!.id);
  }

  // Sign in
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to sign in');
    }

    return await getProfile(response.user!.id);
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get profile
  Future<UserModel> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  // Update online status
  Future<void> updateStatus(String status) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('profiles').update({
      'status': status,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // Auth state stream
  Stream<User?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((data) => data.session?.user);
  }

  // Current user
  User? get currentUser => _supabase.auth.currentUser;
}
```

### Step 14: Create Auth Providers

```dart
// lib/features/auth/providers/auth_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthState extends _$AuthState {
  @override
  Future<UserModel?> build() async {
    final authRepo = ref.watch(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    
    if (currentUser == null) return null;
    
    try {
      return await authRepo.getProfile(currentUser.id);
    } catch (e) {
      return null;
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      return await authRepo.signIn(email: email, password: password);
    });
  }

  Future<void> signUp(String email, String password, String username) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      return await authRepo.signUp(
        email: email,
        password: password,
        username: username,
      );
    });
  }

  Future<void> signOut() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signOut();
    state = const AsyncValue.data(null);
  }
}

// Stream provider for auth changes
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
}
```

### Step 15: Create Login/Register UI

```dart
// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            context.go('/chat');
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                        ref.read(authStateProvider.notifier).signIn(
                              emailController.text,
                              passwordController.text,
                            );
                      },
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Phase 5: Chat Feature Implementation

### Step 16: Create Chat Models

```dart
// lib/features/chat/data/models/conversation_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required String id,
    required String type,
    String? name,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSender,
    @Default(0) int unreadCount,
    List<ParticipantModel>? participants,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);
}

// lib/features/chat/data/models/message_model.dart
@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    @Default('text') String type,
    String? fileUrl,
    String? replyTo,
    required DateTime createdAt,
    @Default(false) bool isRead,
    List<String>? readBy,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

// lib/features/chat/data/models/participant_model.dart
@freezed
class ParticipantModel with _$ParticipantModel {
  const factory ParticipantModel({
    required String id,
    required String userId,
    required String username,
    String? avatarUrl,
    @Default('offline') String status,
  }) = _ParticipantModel;

  factory ParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ParticipantModelFromJson(json);
}
```

### Step 17: Create Conversation Repository

```dart
// lib/features/chat/data/repositories/conversation_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/conversation_model.dart';

part 'conversation_repository.g.dart';

@riverpod
ConversationRepository conversationRepository(ConversationRepositoryRef ref) {
  return ConversationRepository();
}

class ConversationRepository {
  final _supabase = supabase;

  // Get user conversations
  Stream<List<ConversationModel>> getConversations() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq('conversation_participants.user_id', userId)
        .map((data) {
          return data.map((json) => ConversationModel.fromJson(json)).toList();
        });
  }

  // Create direct conversation
  Future<String> createDirectConversation(String otherUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final result = await _supabase.rpc(
      'create_direct_conversation',
      params: {
        'user1_id': userId,
        'user2_id': otherUserId,
      },
    );

    return result as String;
  }

  // Create group conversation
  Future<String> createGroupConversation({
    required String name,
    required List<String> participantIds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final conversation = await _supabase.from('conversations').insert({
      'type': 'group',
      'name': name,
      'created_by': userId,
    }).select().single();

    final participants = participantIds.map((id) => {
      'conversation_id': conversation['id'],
      'user_id': id,
    }).toList();

    await _supabase.from('conversation_participants').insert(participants);

    return conversation['id'] as String;
  }
}
```

### Step 18: Create Message Repository

```dart
// lib/features/chat/data/repositories/message_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/message_model.dart';

part 'message_repository.g.dart';

@riverpod
MessageRepository messageRepository(MessageRepositoryRef ref) {
  return MessageRepository();
}

class MessageRepository {
  final _supabase = supabase;

  // Stream messages in real-time
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) {
          return data.map((json) => MessageModel.fromJson(json)).toList();
        });
  }

  // Send message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? fileUrl,
    String? replyTo,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final message = await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
      'type': type,
      'file_url': fileUrl,
      'reply_to': replyTo,
    }).select().single();

    return MessageModel.fromJson(message);
  }

  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('message_reads').insert({
      'message_id': messageId,
      'user_id': userId,
    });
  }

  // Upload file
  Future<String> uploadFile(String filePath, List<int> fileBytes) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
    
    await _supabase.storage
        .from('chat-files')
        .uploadBinary(fileName, fileBytes);

    return _supabase.storage.from('chat-files').getPublicUrl(fileName);
  }
}
```

### Step 19: Create Chat Providers

```dart
// lib/features/chat/providers/conversation_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/conversation_model.dart';
import '../data/repositories/conversation_repository.dart';

part 'conversation_provider.g.dart';

@riverpod
Stream<List<ConversationModel>> conversations(ConversationsRef ref) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.getConversations();
}

// lib/features/chat/providers/message_provider.dart
@riverpod
Stream<List<MessageModel>> messages(MessagesRef ref, String conversationId) {
  final repo = ref.watch(messageRepositoryProvider);
  return repo.getMessages(conversationId);
}

@riverpod
class MessageSender extends _$MessageSender {
  @override
  FutureOr<void> build() {}

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? fileUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(messageRepositoryProvider);
      await repo.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
        fileUrl: fileUrl,
      );
    });
  }

  Future<void> sendFileMessage({
    required String conversationId,
    required String filePath,
    required List<int> fileBytes,
    required String type,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(messageRepositoryProvider);
      
      // Upload file first
      final fileUrl = await repo.uploadFile(filePath, fileBytes);
      
      // Send message with file URL
      await repo.sendMessage(
        conversationId: conversationId,
        content: 'Sent a file',
        type: type,
        fileUrl: fileUrl,
      );
    });
  }
}
```

---

## Phase 6: UI Implementation

### Step 20: Create Chat List Page

```dart
// lib/features/chat/presentation/pages/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/conversation_provider.dart';
import '../../providers/auth_provider.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search users
              context.push('/users');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Text('No conversations yet'),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ConversationTile(
                conversation: conversation,
                onTap: () {
                  context.push('/chat/${conversation.id}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/users');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// lib/features/chat/presentation/widgets/conversation_tile.dart
class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: conversation.avatarUrl != null
            ? NetworkImage(conversation.avatarUrl!)
            : null,
        child: conversation.avatarUrl == null
            ? Text(conversation.name?[0] ?? '?')
            : null,
      ),
      title: Text(
        conversation.name ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              timeago.format(conversation.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
```

### Step 21: Create Chat Room Page

```dart
// lib/features/chat/presentation/pages/chat_room_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/message_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';

class ChatRoomPage extends HookConsumerWidget {
  final String conversationId;

  const ChatRoomPage({
    super.key,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final scrollController = useScrollController();

    // Auto-scroll to bottom when new messages arrive
    useEffect(() {
      messagesAsync.whenData((messages) {
        if (messages.isNotEmpty && scrollController.hasClients) {
          Future.microtask(() {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      });
      return null;
    }, [messagesAsync]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show conversation info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == 
                        ref.read(authStateProvider).value?.id;
                    
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          const TypingIndicator(),
          MessageInput(conversationId: conversationId),
        ],
      ),
    );
  }
}
```

### Step 22: Create Message Bubble Widget

```dart
// lib/features/chat/presentation/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == 'image' && message.fileUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: message.fileUrl!,
                  placeholder: (context, url) => 
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => 
                      const Icon(Icons.error),
                ),
              ),
            if (message.type == 'text')
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead ? Colors.blue[200] : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 23: Create Message Input Widget

```dart
// lib/features/chat/presentation/widgets/message_input.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/message_provider.dart';

class MessageInput extends HookConsumerWidget {
  final String conversationId;

  const MessageInput({
    super.key,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final isComposing = useState(false);

    void handleSubmit() {
      if (textController.text.trim().isEmpty) return;

      ref.read(messageSenderProvider.notifier).sendMessage(
            conversationId: conversationId,
            content: textController.text.trim(),
          );

      textController.clear();
      isComposing.value = false;
    }

    Future<void> handleImagePick() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes();
        ref.read(messageSenderProvider.notifier).sendFileMessage(
              conversationId: conversationId,
              filePath: image.path,
              fileBytes: bytes,
              type: 'image',
            );
      }
    }

    Future<void> handleFilePick() async {
      final result = await FilePicker.platform.pickFiles();

      if (result != null) {
        final file = result.files.first;
        ref.read(messageSenderProvider.notifier).sendFileMessage(
              conversationId: conversationId,
              filePath: file.name,
              fileBytes: file.bytes!,
              type: 'file',
            );
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: handleFilePick,
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: handleImagePick,
          ),
          Expanded(
            child: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onChanged: (text) {
                isComposing.value = text.trim().isNotEmpty;
              },
              onSubmitted: (_) => handleSubmit(),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: Icon(
              isComposing.value ? Icons.send : Icons.mic,
              color: Colors.blue,
            ),
            onPressed: isComposing.value ? handleSubmit : null,
          ),
        ],
      ),
    );
  }
}
```

---

## Phase 7: Advanced Real-time Features

### Step 24: Implement Typing Indicators

```dart
// lib/features/chat/providers/typing_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';

part 'typing_provider.g.dart';

@riverpod
class TypingNotifier extends _$TypingNotifier {
  RealtimeChannel? _channel;

  @override
  Set<String> build(String conversationId) {
    _setupRealtimeSubscription();
    return {};
  }

  void _setupRealtimeSubscription() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _channel = supabase.channel('typing:$conversationId');
    
    _channel!
        .onPresenceSync((payload) {
          final presenceState = _channel!.presenceState();
          final typingUsers = <String>{};
          
          for (var entry in presenceState.entries) {
            final userIds = entry.value as List;
            for (var user in userIds) {
              final id = user['user_id'] as String;
              if (id != userId) {
                typingUsers.add(id);
              }
            }
          }
          
          state = typingUsers;
        })
        .subscribe();
  }

  void startTyping() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _channel?.track({'user_id': userId});
  }

  void stopTyping() {
    _channel?.untrack();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// lib/features/chat/presentation/widgets/typing_indicator.dart
class TypingIndicator extends ConsumerWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current conversation ID from router or state
    final conversationId = ''; // Get from context
    
    if (conversationId.isEmpty) return const SizedBox.shrink();
    
    final typingUsers = ref.watch(typingNotifierProvider(conversationId));

    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Someone is typing',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 25: Implement Online Presence

```dart
// lib/features/chat/providers/presence_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';

part 'presence_provider.g.dart';

@riverpod
class PresenceNotifier extends _$PresenceNotifier {
  @override
  void build() {
    _setupPresence();
  }

  void _setupPresence() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Update status to online
    supabase.from('profiles').update({
      'status': 'online',
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    // Listen to app lifecycle to update status
    // Update to offline when app goes to background
  }

  Future<void> updateStatus(String status) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('profiles').update({
      'status': status,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}

// Listen to user status changes
@riverpod
Stream<String> userStatus(UserStatusRef ref, String userId) {
  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((data) => data.first['status'] as String);
}
```

### Step 26: Implement Read Receipts

Add to message_input.dart to mark messages as read when viewing:

```dart
// In ChatRoomPage, add this effect
useEffect(() {
  messagesAsync.whenData((messages) {
    // Mark unread messages as read
    for (var message in messages) {
      if (!message.isRead && message.senderId != currentUserId) {
        ref.read(messageRepositoryProvider).markAsRead(message.id);
      }
    }
  });
  return null;
}, [messagesAsync]);
```

---

## Phase 8: Push Notifications

### Step 27: Set Up Firebase Cloud Messaging

1. Add Firebase to your Flutter project
2. Configure iOS and Android
3. Add to pubspec.yaml:

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.1.0
```

### Step 28: Implement Notification Service

```dart
// lib/core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Save token to Supabase
    await _saveTokenToDatabase(token);

    // Initialize local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _saveTokenToDatabase(String? token) async {
    if (token == null) return;
    
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('profiles').update({
      'fcm_token': token,
    }).eq('id', userId);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_channel',
          'Chat Notifications',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}
```

### Step 29: Create Supabase Edge Function for Notifications

Create in Supabase Dashboard → Edge Functions:

```typescript
// supabase/functions/send-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { conversationId, senderId, content } = await req.json()

  // Get participants
  const { data: participants } = await supabase
    .from('conversation_participants')
    .select('user_id, profiles(fcm_token)')
    .eq('conversation_id', conversationId)
    .neq('user_id', senderId)

  // Send FCM notifications
  for (const participant of participants) {
    if (participant.profiles.fcm_token) {
      await sendFCM(participant.profiles.fcm_token, {
        title: 'New Message',
        body: content,
      })
    }
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

---

## Phase 9: Optimization & Testing

### Step 30: Implement Pagination for Messages

```dart
// Update message repository with pagination
Future<List<MessageModel>> getMessagesPaginated({
  required String conversationId,
  int limit = 50,
  DateTime? before,
}) async {
  var query = _supabase
      .from('messages')
      .select()
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: false)
      .limit(limit);

  if (before != null) {
    query = query.lt('created_at', before.toIso8601String());
  }

  final data = await query;
  return data.map((json) => MessageModel.fromJson(json)).toList();
}
```

### Step 31: Add Error Handling & Retry Logic

```dart
// lib/core/utils/error_handler.dart
class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    } else if (error is AuthException) {
      return error.message;
    } else if (error is StorageException) {
      return error.message;
    }
    return 'An unexpected error occurred';
  }

  static void showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Step 32: Testing

```dart
// test/features/chat/repositories/message_repository_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageRepository', () {
    late MessageRepository repository;

    setUp(() {
      repository = MessageRepository();
    });

    test('sendMessage creates a new message', () async {
      // Arrange
      const conversationId = 'test-conversation-id';
      const content = 'Test message';

      // Act
      final message = await repository.sendMessage(
        conversationId: conversationId,
        content: content,
      );

      // Assert
      expect(message.content, content);
      expect(message.conversationId, conversationId);
    });
  });
}
```

---

## Phase 10: Deployment

### Step 33: Build & Release

**For Android:**
```bash
flutter build appbundle --release
```

**For iOS:**
```bash
flutter build ipa --release
```

### Step 34: Supabase Production Checklist

- [ ] Enable RLS on all tables
- [ ] Set up proper indexes
- [ ] Configure rate limiting
- [ ] Set up database backups
- [ ] Configure CORS for your domain
- [ ] Set up monitoring and alerts
- [ ] Configure Supabase Edge Functions
- [ ] Set up CDN for storage files

---

## Complete File Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   │   └── supabase_config.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── services/
│   │   └── notification_service.dart
│   └── utils/
│       └── error_handler.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── register_page.dart
│   │       └── widgets/
│   └── chat/
│       ├── data/
│       │   ├── models/
│       │   │   ├── conversation_model.dart
│       │   │   ├── message_model.dart
│       │   │   └── participant_model.dart
│       │   └── repositories/
│       │       ├── conversation_repository.dart
│       │       └── message_repository.dart
│       ├── providers/
│       │   ├── conversation_provider.dart
│       │   ├── message_provider.dart
│       │   ├── typing_provider.dart
│       │   └── presence_provider.dart
│       └── presentation/
│           ├── pages/
│           │   ├── chat_list_page.dart
│           │   └── chat_room_page.dart
│           └── widgets/
│               ├── conversation_tile.dart
│               ├── message_bubble.dart
│               ├── message_input.dart
│               └── typing_indicator.dart
└── shared/
    ├── widgets/
    └── utils/
```

---

## Timeline Estimate

- **Week 1:** Supabase setup, database schema, RLS policies
- **Week 2:** Flutter project setup, authentication
- **Week 3-4:** Core chat features (messaging, conversations)
- **Week 5:** Real-time features (typing, presence, read receipts)
- **Week 6:** File sharing and media handling
- **Week 7:** Push notifications
- **Week 8:** UI polish and optimization
- **Week 9:** Testing and bug fixes
- **Week 10:** Deployment and launch

**Total:** 10 weeks for production-ready app

---

## Key Benefits of This Stack

✅ **Supabase advantages:**
- Built-in real-time with WebSockets
- Automatic REST API generation
- Row Level Security for data protection
- Built-in file storage
- PostgreSQL power and reliability

✅ **Riverpod advantages:**
- Compile-time safety
- Better testability
- Auto-disposal of resources
- DevTools integration

✅ **Flutter advantages:**
- Single codebase for iOS & Android
- Beautiful, customizable UI
- Hot reload for fast development
- Excellent performance