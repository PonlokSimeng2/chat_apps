// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageNotifierHash() => r'cb77764881730e5cc5b0d795b28227a95ab84c90';

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
