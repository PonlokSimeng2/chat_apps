// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationUsersHash() => r'44c35f4525f2127af83ac777311fe20177d0b110';

/// See also [conversationUsers].
@ProviderFor(conversationUsers)
final conversationUsersProvider =
    AutoDisposeFutureProvider<List<UserModel>>.internal(
      conversationUsers,
      name: r'conversationUsersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationUsersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationUsersRef = AutoDisposeFutureProviderRef<List<UserModel>>;
String _$getLastMessagesHash() => r'7d39343fcb2752404ce76235e71d0cc77b615ed8';

/// See also [getLastMessages].
@ProviderFor(getLastMessages)
final getLastMessagesProvider =
    AutoDisposeStreamProvider<Map<String, MessageModel>>.internal(
      getLastMessages,
      name: r'getLastMessagesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getLastMessagesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetLastMessagesRef =
    AutoDisposeStreamProviderRef<Map<String, MessageModel>>;
String _$getUnreadMessageCountsHash() =>
    r'd610d04c4c3aeec67732e23d526ab3c8ccf941c2';

/// See also [getUnreadMessageCounts].
@ProviderFor(getUnreadMessageCounts)
final getUnreadMessageCountsProvider =
    AutoDisposeStreamProvider<Map<String, int>>.internal(
      getUnreadMessageCounts,
      name: r'getUnreadMessageCountsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getUnreadMessageCountsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetUnreadMessageCountsRef =
    AutoDisposeStreamProviderRef<Map<String, int>>;
String _$messageNotifierHash() => r'01702de043b0dbda72ac484a9129a1442acc1c09';

/// See also [MessageNotifier].
@ProviderFor(MessageNotifier)
final messageNotifierProvider =
    NotifierProvider<MessageNotifier, AsyncValue<List<MessageModel>>>.internal(
      MessageNotifier.new,
      name: r'messageNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MessageNotifier = Notifier<AsyncValue<List<MessageModel>>>;
String _$messagePaginationHash() => r'59d6a4486c4aa9a1bd04d054f796a3b3343d01ab';

/// See also [MessagePagination].
@ProviderFor(MessagePagination)
final messagePaginationProvider =
    AutoDisposeNotifierProvider<
      MessagePagination,
      AsyncValue<List<MessageModel>>
    >.internal(
      MessagePagination.new,
      name: r'messagePaginationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messagePaginationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MessagePagination =
    AutoDisposeNotifier<AsyncValue<List<MessageModel>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
