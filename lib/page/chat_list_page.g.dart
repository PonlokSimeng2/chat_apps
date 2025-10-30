// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_list_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getConversationUsersHash() =>
    r'b4fbecc47ec87260b46e3c15184f748c4802b5b7';

/// See also [getConversationUsers].
@ProviderFor(getConversationUsers)
final getConversationUsersProvider =
    AutoDisposeFutureProvider<List<UserModel>>.internal(
      getConversationUsers,
      name: r'getConversationUsersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getConversationUsersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetConversationUsersRef = AutoDisposeFutureProviderRef<List<UserModel>>;
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
