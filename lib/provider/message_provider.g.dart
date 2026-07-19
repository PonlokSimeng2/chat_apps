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

String _$messageNotifierHash() => r'91a5154e30ea08de8039b64997b1d27bdd22d758';

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

@ProviderFor(conversationUsers)
final conversationUsersProvider = ConversationUsersProvider._();

final class ConversationUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserModel>>,
          List<UserModel>,
          Stream<List<UserModel>>
        >
    with $FutureModifier<List<UserModel>>, $StreamProvider<List<UserModel>> {
  ConversationUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationUsersHash();

  @$internal
  @override
  $StreamProviderElement<List<UserModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<UserModel>> create(Ref ref) {
    return conversationUsers(ref);
  }
}

String _$conversationUsersHash() => r'3bbfd6fe8dcbf42378c5899e382608936696069e';

@ProviderFor(getLastMessages)
final getLastMessagesProvider = GetLastMessagesProvider._();

final class GetLastMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, MessageModel>>,
          Map<String, MessageModel>,
          Stream<Map<String, MessageModel>>
        >
    with
        $FutureModifier<Map<String, MessageModel>>,
        $StreamProvider<Map<String, MessageModel>> {
  GetLastMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getLastMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getLastMessagesHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, MessageModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, MessageModel>> create(Ref ref) {
    return getLastMessages(ref);
  }
}

String _$getLastMessagesHash() => r'bcfc88106dd05dad911fde82d7876c52fad27d65';

@ProviderFor(getUnreadMessageCounts)
final getUnreadMessageCountsProvider = GetUnreadMessageCountsProvider._();

final class GetUnreadMessageCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          Stream<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  GetUnreadMessageCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getUnreadMessageCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getUnreadMessageCountsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    return getUnreadMessageCounts(ref);
  }
}

String _$getUnreadMessageCountsHash() =>
    r'682666b5dc95fbe28dfbf00ae20a72aab1380b6d';
