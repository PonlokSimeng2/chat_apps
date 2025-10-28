// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationNotifierHash() =>
    r'aa2ac84158f5b63a843ab2670de06a0f22a85030';

/// See also [ConversationNotifier].
@ProviderFor(ConversationNotifier)
final conversationNotifierProvider =
    NotifierProvider<
      ConversationNotifier,
      AsyncValue<List<ConversationModel>>
    >.internal(
      ConversationNotifier.new,
      name: r'conversationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConversationNotifier = Notifier<AsyncValue<List<ConversationModel>>>;
String _$singleConversationNotifierHash() =>
    r'07d3bc1319571aafe88ce988b4bb1bc5cf32c263';

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

abstract class _$SingleConversationNotifier
    extends BuildlessAutoDisposeNotifier<AsyncValue<ConversationModel?>> {
  late final int conversationId;

  AsyncValue<ConversationModel?> build(int conversationId);
}

/// See also [SingleConversationNotifier].
@ProviderFor(SingleConversationNotifier)
const singleConversationNotifierProvider = SingleConversationNotifierFamily();

/// See also [SingleConversationNotifier].
class SingleConversationNotifierFamily
    extends Family<AsyncValue<ConversationModel?>> {
  /// See also [SingleConversationNotifier].
  const SingleConversationNotifierFamily();

  /// See also [SingleConversationNotifier].
  SingleConversationNotifierProvider call(int conversationId) {
    return SingleConversationNotifierProvider(conversationId);
  }

  @override
  SingleConversationNotifierProvider getProviderOverride(
    covariant SingleConversationNotifierProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'singleConversationNotifierProvider';
}

/// See also [SingleConversationNotifier].
class SingleConversationNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          SingleConversationNotifier,
          AsyncValue<ConversationModel?>
        > {
  /// See also [SingleConversationNotifier].
  SingleConversationNotifierProvider(int conversationId)
    : this._internal(
        () => SingleConversationNotifier()..conversationId = conversationId,
        from: singleConversationNotifierProvider,
        name: r'singleConversationNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$singleConversationNotifierHash,
        dependencies: SingleConversationNotifierFamily._dependencies,
        allTransitiveDependencies:
            SingleConversationNotifierFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  SingleConversationNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final int conversationId;

  @override
  AsyncValue<ConversationModel?> runNotifierBuild(
    covariant SingleConversationNotifier notifier,
  ) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(SingleConversationNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SingleConversationNotifierProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    SingleConversationNotifier,
    AsyncValue<ConversationModel?>
  >
  createElement() {
    return _SingleConversationNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleConversationNotifierProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SingleConversationNotifierRef
    on AutoDisposeNotifierProviderRef<AsyncValue<ConversationModel?>> {
  /// The parameter `conversationId` of this provider.
  int get conversationId;
}

class _SingleConversationNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          SingleConversationNotifier,
          AsyncValue<ConversationModel?>
        >
    with SingleConversationNotifierRef {
  _SingleConversationNotifierProviderElement(super.provider);

  @override
  int get conversationId =>
      (origin as SingleConversationNotifierProvider).conversationId;
}

String _$conversationParticipantsNotifierHash() =>
    r'5f81063dca04685179e3572663f8a9ebcff21134';

abstract class _$ConversationParticipantsNotifier
    extends
        BuildlessAutoDisposeNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  late final int conversationId;

  AsyncValue<List<Map<String, dynamic>>> build(int conversationId);
}

/// See also [ConversationParticipantsNotifier].
@ProviderFor(ConversationParticipantsNotifier)
const conversationParticipantsNotifierProvider =
    ConversationParticipantsNotifierFamily();

/// See also [ConversationParticipantsNotifier].
class ConversationParticipantsNotifierFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [ConversationParticipantsNotifier].
  const ConversationParticipantsNotifierFamily();

  /// See also [ConversationParticipantsNotifier].
  ConversationParticipantsNotifierProvider call(int conversationId) {
    return ConversationParticipantsNotifierProvider(conversationId);
  }

  @override
  ConversationParticipantsNotifierProvider getProviderOverride(
    covariant ConversationParticipantsNotifierProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationParticipantsNotifierProvider';
}

/// See also [ConversationParticipantsNotifier].
class ConversationParticipantsNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          ConversationParticipantsNotifier,
          AsyncValue<List<Map<String, dynamic>>>
        > {
  /// See also [ConversationParticipantsNotifier].
  ConversationParticipantsNotifierProvider(int conversationId)
    : this._internal(
        () =>
            ConversationParticipantsNotifier()..conversationId = conversationId,
        from: conversationParticipantsNotifierProvider,
        name: r'conversationParticipantsNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationParticipantsNotifierHash,
        dependencies: ConversationParticipantsNotifierFamily._dependencies,
        allTransitiveDependencies:
            ConversationParticipantsNotifierFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ConversationParticipantsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final int conversationId;

  @override
  AsyncValue<List<Map<String, dynamic>>> runNotifierBuild(
    covariant ConversationParticipantsNotifier notifier,
  ) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(ConversationParticipantsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ConversationParticipantsNotifierProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    ConversationParticipantsNotifier,
    AsyncValue<List<Map<String, dynamic>>>
  >
  createElement() {
    return _ConversationParticipantsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationParticipantsNotifierProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationParticipantsNotifierRef
    on AutoDisposeNotifierProviderRef<AsyncValue<List<Map<String, dynamic>>>> {
  /// The parameter `conversationId` of this provider.
  int get conversationId;
}

class _ConversationParticipantsNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          ConversationParticipantsNotifier,
          AsyncValue<List<Map<String, dynamic>>>
        >
    with ConversationParticipantsNotifierRef {
  _ConversationParticipantsNotifierProviderElement(super.provider);

  @override
  int get conversationId =>
      (origin as ConversationParticipantsNotifierProvider).conversationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
