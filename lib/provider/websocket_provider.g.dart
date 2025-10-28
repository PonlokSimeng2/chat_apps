// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isWebSocketConnectedHash() =>
    r'840999dce801a1de2b087cd604af5da329413e76';

/// See also [isWebSocketConnected].
@ProviderFor(isWebSocketConnected)
final isWebSocketConnectedProvider = AutoDisposeProvider<bool>.internal(
  isWebSocketConnected,
  name: r'isWebSocketConnectedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isWebSocketConnectedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsWebSocketConnectedRef = AutoDisposeProviderRef<bool>;
String _$webSocketStatusHash() => r'36f00562d60850b3c9ab90217e29843287a2f67d';

/// See also [webSocketStatus].
@ProviderFor(webSocketStatus)
final webSocketStatusProvider = AutoDisposeProvider<WebSocketStatus>.internal(
  webSocketStatus,
  name: r'webSocketStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$webSocketStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WebSocketStatusRef = AutoDisposeProviderRef<WebSocketStatus>;
String _$webSocketNotifierHash() => r'c5fc2d26c927e28d6ba137b09d9a1a4d21cddfe0';

/// See also [WebSocketNotifier].
@ProviderFor(WebSocketNotifier)
final webSocketNotifierProvider =
    AutoDisposeNotifierProvider<
      WebSocketNotifier,
      AsyncValue<WebSocketConnectionState>
    >.internal(
      WebSocketNotifier.new,
      name: r'webSocketNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$webSocketNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WebSocketNotifier =
    AutoDisposeNotifier<AsyncValue<WebSocketConnectionState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
