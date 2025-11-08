// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getUserHash() => r'ee63d20e3b90d1e5174234ea4742f7d159af7811';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [getUser].
@ProviderFor(getUser)
const getUserProvider = GetUserFamily();

/// See also [getUser].
class GetUserFamily extends Family<AsyncValue<UserModel?>> {
  /// See also [getUser].
  const GetUserFamily();

  /// See also [getUser].
  GetUserProvider call(String userId) {
    return GetUserProvider(userId);
  }

  @override
  GetUserProvider getProviderOverride(covariant GetUserProvider provider) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getUserProvider';
}

/// See also [getUser].
class GetUserProvider extends AutoDisposeFutureProvider<UserModel?> {
  /// See also [getUser].
  GetUserProvider(String userId)
    : this._internal(
        (ref) => getUser(ref as GetUserRef, userId),
        from: getUserProvider,
        name: r'getUserProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$getUserHash,
        dependencies: GetUserFamily._dependencies,
        allTransitiveDependencies: GetUserFamily._allTransitiveDependencies,
        userId: userId,
      );

  GetUserProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<UserModel?> Function(GetUserRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetUserProvider._internal(
        (ref) => create(ref as GetUserRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<UserModel?> createElement() {
    return _GetUserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetUserProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetUserRef on AutoDisposeFutureProviderRef<UserModel?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _GetUserProviderElement
    extends AutoDisposeFutureProviderElement<UserModel?>
    with GetUserRef {
  _GetUserProviderElement(super.provider);

  @override
  String get userId => (origin as GetUserProvider).userId;
}

String _$getAllUsersHash() => r'046b58f42e604c9fe2f2d5d41299c91a3bc6b86e';

/// See also [getAllUsers].
@ProviderFor(getAllUsers)
final getAllUsersProvider = AutoDisposeFutureProvider<List<UserModel>>.internal(
  getAllUsers,
  name: r'getAllUsersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getAllUsersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetAllUsersRef = AutoDisposeFutureProviderRef<List<UserModel>>;
String _$getContactUsersHash() => r'add72d1e3fc5c19609bc6e8531c779b4b9fd7e7d';

/// See also [getContactUsers].
@ProviderFor(getContactUsers)
final getContactUsersProvider =
    AutoDisposeFutureProvider<List<UserModel>>.internal(
      getContactUsers,
      name: r'getContactUsersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getContactUsersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetContactUsersRef = AutoDisposeFutureProviderRef<List<UserModel>>;
String _$currentUserHash() => r'9768a7de0ee6a015ca8bc7cea76ae5fb1f870b98';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeFutureProvider<UserModel?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeFutureProviderRef<UserModel?>;
String _$createOrGetPrivateConversationHash() =>
    r'786d3f602f826300fd3a145f4b4b7ff98bdcbf50';

/// See also [createOrGetPrivateConversation].
@ProviderFor(createOrGetPrivateConversation)
const createOrGetPrivateConversationProvider =
    CreateOrGetPrivateConversationFamily();

/// See also [createOrGetPrivateConversation].
class CreateOrGetPrivateConversationFamily extends Family<AsyncValue<int>> {
  /// See also [createOrGetPrivateConversation].
  const CreateOrGetPrivateConversationFamily();

  /// See also [createOrGetPrivateConversation].
  CreateOrGetPrivateConversationProvider call(String otherUserId) {
    return CreateOrGetPrivateConversationProvider(otherUserId);
  }

  @override
  CreateOrGetPrivateConversationProvider getProviderOverride(
    covariant CreateOrGetPrivateConversationProvider provider,
  ) {
    return call(provider.otherUserId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'createOrGetPrivateConversationProvider';
}

/// See also [createOrGetPrivateConversation].
class CreateOrGetPrivateConversationProvider
    extends AutoDisposeFutureProvider<int> {
  /// See also [createOrGetPrivateConversation].
  CreateOrGetPrivateConversationProvider(String otherUserId)
    : this._internal(
        (ref) => createOrGetPrivateConversation(
          ref as CreateOrGetPrivateConversationRef,
          otherUserId,
        ),
        from: createOrGetPrivateConversationProvider,
        name: r'createOrGetPrivateConversationProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$createOrGetPrivateConversationHash,
        dependencies: CreateOrGetPrivateConversationFamily._dependencies,
        allTransitiveDependencies:
            CreateOrGetPrivateConversationFamily._allTransitiveDependencies,
        otherUserId: otherUserId,
      );

  CreateOrGetPrivateConversationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherUserId,
  }) : super.internal();

  final String otherUserId;

  @override
  Override overrideWith(
    FutureOr<int> Function(CreateOrGetPrivateConversationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreateOrGetPrivateConversationProvider._internal(
        (ref) => create(ref as CreateOrGetPrivateConversationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherUserId: otherUserId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _CreateOrGetPrivateConversationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateOrGetPrivateConversationProvider &&
        other.otherUserId == otherUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CreateOrGetPrivateConversationRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `otherUserId` of this provider.
  String get otherUserId;
}

class _CreateOrGetPrivateConversationProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with CreateOrGetPrivateConversationRef {
  _CreateOrGetPrivateConversationProviderElement(super.provider);

  @override
  String get otherUserId =>
      (origin as CreateOrGetPrivateConversationProvider).otherUserId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
