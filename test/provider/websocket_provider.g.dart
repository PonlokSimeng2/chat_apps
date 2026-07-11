// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WebSocketNotifier)
final webSocketProvider = WebSocketNotifierProvider._();

final class WebSocketNotifierProvider
    extends
        $NotifierProvider<
          WebSocketNotifier,
          AsyncValue<WebSocketConnectionState>
        > {
  WebSocketNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webSocketProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webSocketNotifierHash();

  @$internal
  @override
  WebSocketNotifier create() => WebSocketNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<WebSocketConnectionState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<WebSocketConnectionState>>(value),
    );
  }
}

String _$webSocketNotifierHash() => r'9a5b4da213cedb70501d5aa63bb5214072f53e8e';

abstract class _$WebSocketNotifier
    extends $Notifier<AsyncValue<WebSocketConnectionState>> {
  AsyncValue<WebSocketConnectionState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<WebSocketConnectionState>,
              AsyncValue<WebSocketConnectionState>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<WebSocketConnectionState>,
                AsyncValue<WebSocketConnectionState>
              >,
              AsyncValue<WebSocketConnectionState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(isWebSocketConnected)
final isWebSocketConnectedProvider = IsWebSocketConnectedProvider._();

final class IsWebSocketConnectedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsWebSocketConnectedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isWebSocketConnectedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isWebSocketConnectedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isWebSocketConnected(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isWebSocketConnectedHash() =>
    r'56b1a7570fc4fa5c517c897498948cbc45918fab';

@ProviderFor(webSocketStatus)
final webSocketStatusProvider = WebSocketStatusProvider._();

final class WebSocketStatusProvider
    extends
        $FunctionalProvider<WebSocketStatus, WebSocketStatus, WebSocketStatus>
    with $Provider<WebSocketStatus> {
  WebSocketStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webSocketStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webSocketStatusHash();

  @$internal
  @override
  $ProviderElement<WebSocketStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WebSocketStatus create(Ref ref) {
    return webSocketStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebSocketStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebSocketStatus>(value),
    );
  }
}

String _$webSocketStatusHash() => r'9912033cf39a8d7881d5838966c07c083ed83546';
