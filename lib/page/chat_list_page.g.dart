// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_list_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getConversationUsersHash() =>
    r'450bc6ac27aa1877b4ff27f1fb81a2f530053903';

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
String _$getLastMessagesHash() => r'ae5a2ac0b7ceca9a53c65085d66caad3c4eaf281';

/// See also [getLastMessages].
@ProviderFor(getLastMessages)
final getLastMessagesProvider =
    AutoDisposeFutureProvider<Map<String, MessageModel>>.internal(
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
    AutoDisposeFutureProviderRef<Map<String, MessageModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
