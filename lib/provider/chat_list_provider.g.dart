// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatListNotifier)
final chatListProvider = ChatListNotifierProvider._();

final class ChatListNotifierProvider
    extends
        $NotifierProvider<ChatListNotifier, AsyncValue<List<ChatListItem>>> {
  ChatListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatListNotifierHash();

  @$internal
  @override
  ChatListNotifier create() => ChatListNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<ChatListItem>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<ChatListItem>>>(
        value,
      ),
    );
  }
}

String _$chatListNotifierHash() => r'7ccce03b215d46b3f225e23d8b21b01822b56cd5';

abstract class _$ChatListNotifier
    extends $Notifier<AsyncValue<List<ChatListItem>>> {
  AsyncValue<List<ChatListItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ChatListItem>>,
              AsyncValue<List<ChatListItem>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ChatListItem>>,
                AsyncValue<List<ChatListItem>>
              >,
              AsyncValue<List<ChatListItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
