// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getUser)
final getUserProvider = GetUserFamily._();

final class GetUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserModel?>,
          UserModel?,
          FutureOr<UserModel?>
        >
    with $FutureModifier<UserModel?>, $FutureProvider<UserModel?> {
  GetUserProvider._({
    required GetUserFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getUserProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getUserHash();

  @override
  String toString() {
    return r'getUserProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserModel?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserModel?> create(Ref ref) {
    final argument = this.argument as String;
    return getUser(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetUserProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getUserHash() => r'ee63d20e3b90d1e5174234ea4742f7d159af7811';

final class GetUserFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserModel?>, String> {
  GetUserFamily._()
    : super(
        retry: null,
        name: r'getUserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetUserProvider call(String userId) =>
      GetUserProvider._(argument: userId, from: this);

  @override
  String toString() => r'getUserProvider';
}

@ProviderFor(getAllUsers)
final getAllUsersProvider = GetAllUsersProvider._();

final class GetAllUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserModel>>,
          List<UserModel>,
          FutureOr<List<UserModel>>
        >
    with $FutureModifier<List<UserModel>>, $FutureProvider<List<UserModel>> {
  GetAllUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getAllUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getAllUsersHash();

  @$internal
  @override
  $FutureProviderElement<List<UserModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserModel>> create(Ref ref) {
    return getAllUsers(ref);
  }
}

String _$getAllUsersHash() => r'046b58f42e604c9fe2f2d5d41299c91a3bc6b86e';

@ProviderFor(getContactUsers)
final getContactUsersProvider = GetContactUsersProvider._();

final class GetContactUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserModel>>,
          List<UserModel>,
          FutureOr<List<UserModel>>
        >
    with $FutureModifier<List<UserModel>>, $FutureProvider<List<UserModel>> {
  GetContactUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getContactUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getContactUsersHash();

  @$internal
  @override
  $FutureProviderElement<List<UserModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserModel>> create(Ref ref) {
    return getContactUsers(ref);
  }
}

String _$getContactUsersHash() => r'add72d1e3fc5c19609bc6e8531c779b4b9fd7e7d';

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

final class CurrentUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserModel?>,
          UserModel?,
          FutureOr<UserModel?>
        >
    with $FutureModifier<UserModel?>, $FutureProvider<UserModel?> {
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $FutureProviderElement<UserModel?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserModel?> create(Ref ref) {
    return currentUser(ref);
  }
}

String _$currentUserHash() => r'9768a7de0ee6a015ca8bc7cea76ae5fb1f870b98';

@ProviderFor(createOrGetPrivateConversation)
final createOrGetPrivateConversationProvider =
    CreateOrGetPrivateConversationFamily._();

final class CreateOrGetPrivateConversationProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  CreateOrGetPrivateConversationProvider._({
    required CreateOrGetPrivateConversationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'createOrGetPrivateConversationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$createOrGetPrivateConversationHash();

  @override
  String toString() {
    return r'createOrGetPrivateConversationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return createOrGetPrivateConversation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateOrGetPrivateConversationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$createOrGetPrivateConversationHash() =>
    r'786d3f602f826300fd3a145f4b4b7ff98bdcbf50';

final class CreateOrGetPrivateConversationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  CreateOrGetPrivateConversationFamily._()
    : super(
        retry: null,
        name: r'createOrGetPrivateConversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CreateOrGetPrivateConversationProvider call(String otherUserId) =>
      CreateOrGetPrivateConversationProvider._(
        argument: otherUserId,
        from: this,
      );

  @override
  String toString() => r'createOrGetPrivateConversationProvider';
}
