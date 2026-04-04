// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MessageNotifier)
final messageProvider = MessageNotifierProvider._();

final class MessageNotifierProvider
    extends $NotifierProvider<MessageNotifier, AsyncValue<List<MessageModel>>> {
  MessageNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageNotifierHash();

  @$internal
  @override
  MessageNotifier create() => MessageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<MessageModel>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<MessageModel>>>(
        value,
      ),
    );
  }
}

String _$messageNotifierHash() => r'01702de043b0dbda72ac484a9129a1442acc1c09';

abstract class _$MessageNotifier
    extends $Notifier<AsyncValue<List<MessageModel>>> {
  AsyncValue<List<MessageModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<MessageModel>>,
              AsyncValue<List<MessageModel>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MessageModel>>,
                AsyncValue<List<MessageModel>>
              >,
              AsyncValue<List<MessageModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(MessagePagination)
final messagePaginationProvider = MessagePaginationProvider._();

final class MessagePaginationProvider
    extends
        $NotifierProvider<MessagePagination, AsyncValue<List<MessageModel>>> {
  MessagePaginationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagePaginationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagePaginationHash();

  @$internal
  @override
  MessagePagination create() => MessagePagination();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<MessageModel>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<MessageModel>>>(
        value,
      ),
    );
  }
}

String _$messagePaginationHash() => r'59d6a4486c4aa9a1bd04d054f796a3b3343d01ab';

abstract class _$MessagePagination
    extends $Notifier<AsyncValue<List<MessageModel>>> {
  AsyncValue<List<MessageModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<MessageModel>>,
              AsyncValue<List<MessageModel>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MessageModel>>,
                AsyncValue<List<MessageModel>>
              >,
              AsyncValue<List<MessageModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
