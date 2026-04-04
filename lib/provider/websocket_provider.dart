import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'websocket_provider.g.dart';

enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

@riverpod
class WebSocketNotifier extends _$WebSocketNotifier {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  String? _currentUserId;
  String? _currentToken;
  String? _currentServerUrl;

  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const String _defaultServerUrl = 'https://communist-alexi-kfa-8f51d6f6.koyeb.app';

  @override
  AsyncValue<WebSocketConnectionState> build() {
    return const AsyncValue.data(WebSocketConnectionState(
      status: WebSocketStatus.disconnected,
      connectedAt: null,
      lastError: null,
    ));
  }

  Future<void> connect({
    required String userId,
    required String token,
    String? serverUrl,
  }) async {
    _currentUserId = userId;
    _currentToken = token;
    _currentServerUrl = serverUrl ?? _defaultServerUrl;

    if (state.value?.status == WebSocketStatus.connected) {
      print('⚠️ WebSocket already connected');
      return;
    }

    try {
      state = const AsyncValue.data(WebSocketConnectionState(
        status: WebSocketStatus.connecting,
        connectedAt: null,
        lastError: null,
      ));

      // Use wss:// for secure WebSocket connection
      final wsUrl = Uri.parse('${_currentServerUrl}/chat?userId=$userId&token=$token');
      print('🔌 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);

      await _channel!.ready;

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: true,
      );

      // Send connection confirmation
      _sendMessage({
        'type': 'connection',
        'action': 'connect',
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Start heartbeat
      _startHeartbeat();

      state = AsyncValue.data(WebSocketConnectionState(
        status: WebSocketStatus.connected,
        connectedAt: DateTime.now(),
        lastError: null,
      ));

      _reconnectAttempts = 0;
      _isReconnecting = false;

      print('✅ WebSocket connected successfully');
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      state = AsyncValue.data(WebSocketConnectionState(
        status: WebSocketStatus.failed,
        connectedAt: null,
        lastError: e.toString(),
      ));
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;

      switch (data['type']) {
        case 'heartbeat':
          _handleHeartbeat(data);
          break;
        case 'connection':
          print('📨 Connection message: ${data['action']}');
          break;
        case 'error':
          print('❌ Server error: ${data['error']}');
          break;
        default:
          print('📨 Received message: ${data['type']}');
      }
    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
    }
  }

  void _handleHeartbeat(Map<String, dynamic> data) {
    if (data['action'] == 'ping') {
      _sendMessage({
        'type': 'heartbeat',
        'action': 'pong',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _handleError(Object error) {
    print('❌ WebSocket error: $error');
    state = AsyncValue.data(WebSocketConnectionState(
      status: WebSocketStatus.failed,
      connectedAt: state.value?.connectedAt,
      lastError: error.toString(),
    ));
  }

  void _handleDisconnect() {
    print('🔌 WebSocket disconnected');

    state = AsyncValue.data(WebSocketConnectionState(
      status: WebSocketStatus.disconnected,
      connectedAt: state.value?.connectedAt,
      lastError: 'Connection lost',
    ));

    _heartbeatTimer?.cancel();

    // Attempt to reconnect if not intentional and we have credentials
    if (_isReconnecting == false && _currentUserId != null && _currentToken != null) {
      _scheduleReconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (state.value?.status == WebSocketStatus.connected) {
        _sendMessage({
          'type': 'heartbeat',
          'action': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && state.value?.status == WebSocketStatus.connected) {
      try {
        final messageString = jsonEncode(message);
        _channel!.sink.add(messageString);
        print('📤 Sent: ${message['type']}');
      } catch (e) {
        print('❌ Error sending message: $e');
        _handleDisconnect();
      }
    } else {
      print('⚠️ Cannot send message - WebSocket not connected');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _currentUserId == null || _currentToken == null) {
      print('❌ Cannot reconnect: max attempts reached or missing credentials');
      state = AsyncValue.data(WebSocketConnectionState(
        status: WebSocketStatus.failed,
        connectedAt: state.value?.connectedAt,
        lastError: 'Max reconnect attempts reached',
      ));
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    final delay = _reconnectDelay * _reconnectAttempts;
    print('🔄 Scheduling reconnect in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)');

    state = AsyncValue.data(WebSocketConnectionState(
      status: WebSocketStatus.reconnecting,
      connectedAt: state.value?.connectedAt,
      lastError: 'Reconnecting... attempt $_reconnectAttempts',
    ));

    Timer(delay, () {
      if (_isReconnecting && _currentUserId != null && _currentToken != null) {
        connect(
          userId: _currentUserId!,
          token: _currentToken!,
          serverUrl: _currentServerUrl,
        );
      }
    });
  }

  void disconnect() {
    print('👋 Manually disconnecting WebSocket');
    _isReconnecting = false;
    _heartbeatTimer?.cancel();

    if (_channel != null) {
      _sendMessage({
        'type': 'connection',
        'action': 'disconnect',
        'timestamp': DateTime.now().toIso8601String(),
      });

      _channel!.sink.close();
      _channel = null;
    }

    state = const AsyncValue.data(WebSocketConnectionState(
      status: WebSocketStatus.disconnected,
      connectedAt: null,
      lastError: null,
    ));

    _currentUserId = null;
    _currentToken = null;
    _currentServerUrl = null;
  }

  // Helper method to check connection status
  bool get isConnected => state.value?.status == WebSocketStatus.connected;

  // Generic message sending method
  void sendMessage(Map<String, dynamic> message) {
    _sendMessage(message);
  }
}

class WebSocketConnectionState {
  final WebSocketStatus status;
  final DateTime? connectedAt;
  final String? lastError;

  const WebSocketConnectionState({
    required this.status,
    this.connectedAt,
    this.lastError,
  });

  @override
  String toString() => 'WebSocketConnectionState(status: $status, connectedAt: $connectedAt, lastError: $lastError)';
}

// Utility provider for WebSocket status
// @riverpod
// bool isWebSocketConnected(Ref ref) {
//   final wsState = ref.watch(webSocketNotifierProvider);
//   return wsState.value?.status == WebSocketStatus.connected;
// }

// // Provider for WebSocket status enum
// @riverpod
// WebSocketStatus webSocketStatus(Ref ref) {
//   final wsState = ref.watch(webSocketNotifierProvider);
//   return wsState.value?.status ?? WebSocketStatus.disconnected;
// }