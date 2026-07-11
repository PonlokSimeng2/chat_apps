// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConversationNotifier)
final conversationProvider = ConversationNotifierProvider._();

final class ConversationNotifierProvider
    extends
        $NotifierProvider<
          ConversationNotifier,
          AsyncValue<List<ConversationModel>>
        > {
  ConversationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationNotifierHash();

  @$internal
  @override
  ConversationNotifier create() => ConversationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<ConversationModel>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<ConversationModel>>>(
        value,
      ),
    );
  }
}

String _$conversationNotifierHash() =>
    r'aa2ac84158f5b63a843ab2670de06a0f22a85030';

abstract class _$ConversationNotifier
    extends $Notifier<AsyncValue<List<ConversationModel>>> {
  AsyncValue<List<ConversationModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ConversationModel>>,
              AsyncValue<List<ConversationModel>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ConversationModel>>,
                AsyncValue<List<ConversationModel>>
              >,
              AsyncValue<List<ConversationModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SingleConversationNotifier)
final singleConversationProvider = SingleConversationNotifierFamily._();

final class SingleConversationNotifierProvider
    extends
        $NotifierProvider<
          SingleConversationNotifier,
          AsyncValue<ConversationModel?>
        > {
  SingleConversationNotifierProvider._({
    required SingleConversationNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'singleConversationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$singleConversationNotifierHash();

  @override
  String toString() {
    return r'singleConversationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SingleConversationNotifier create() => SingleConversationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ConversationModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ConversationModel?>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SingleConversationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$singleConversationNotifierHash() =>
    r'07d3bc1319571aafe88ce988b4bb1bc5cf32c263';

final class SingleConversationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SingleConversationNotifier,
          AsyncValue<ConversationModel?>,
          AsyncValue<ConversationModel?>,
          AsyncValue<ConversationModel?>,
          int
        > {
  SingleConversationNotifierFamily._()
    : super(
        retry: null,
        name: r'singleConversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SingleConversationNotifierProvider call(int conversationId) =>
      SingleConversationNotifierProvider._(
        argument: conversationId,
        from: this,
      );

  @override
  String toString() => r'singleConversationProvider';
}

abstract class _$SingleConversationNotifier
    extends $Notifier<AsyncValue<ConversationModel?>> {
  late final _$args = ref.$arg as int;
  int get conversationId => _$args;

  AsyncValue<ConversationModel?> build(int conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ConversationModel?>,
              AsyncValue<ConversationModel?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ConversationModel?>,
                AsyncValue<ConversationModel?>
              >,
              AsyncValue<ConversationModel?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ConversationParticipantsNotifier)
final conversationParticipantsProvider =
    ConversationParticipantsNotifierFamily._();

final class ConversationParticipantsNotifierProvider
    extends
        $NotifierProvider<
          ConversationParticipantsNotifier,
          AsyncValue<List<Map<String, dynamic>>>
        > {
  ConversationParticipantsNotifierProvider._({
    required ConversationParticipantsNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'conversationParticipantsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationParticipantsNotifierHash();

  @override
  String toString() {
    return r'conversationParticipantsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ConversationParticipantsNotifier create() =>
      ConversationParticipantsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Map<String, dynamic>>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<Map<String, dynamic>>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationParticipantsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationParticipantsNotifierHash() =>
    r'5f81063dca04685179e3572663f8a9ebcff21134';

final class ConversationParticipantsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationParticipantsNotifier,
          AsyncValue<List<Map<String, dynamic>>>,
          AsyncValue<List<Map<String, dynamic>>>,
          AsyncValue<List<Map<String, dynamic>>>,
          int
        > {
  ConversationParticipantsNotifierFamily._()
    : super(
        retry: null,
        name: r'conversationParticipantsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationParticipantsNotifierProvider call(int conversationId) =>
      ConversationParticipantsNotifierProvider._(
        argument: conversationId,
        from: this,
      );

  @override
  String toString() => r'conversationParticipantsProvider';
}

abstract class _$ConversationParticipantsNotifier
    extends $Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  late final _$args = ref.$arg as int;
  int get conversationId => _$args;

  AsyncValue<List<Map<String, dynamic>>> build(int conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              AsyncValue<List<Map<String, dynamic>>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                AsyncValue<List<Map<String, dynamic>>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
