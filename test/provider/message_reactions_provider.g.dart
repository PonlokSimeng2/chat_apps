// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_reactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messageReactions)
final messageReactionsProvider = MessageReactionsFamily._();

final class MessageReactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageReactionModel>>,
          List<MessageReactionModel>,
          Stream<List<MessageReactionModel>>
        >
    with
        $FutureModifier<List<MessageReactionModel>>,
        $StreamProvider<List<MessageReactionModel>> {
  MessageReactionsProvider._({
    required MessageReactionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'messageReactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageReactionsHash();

  @override
  String toString() {
    return r'messageReactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MessageReactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MessageReactionModel>> create(Ref ref) {
    final argument = this.argument as int;
    return messageReactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageReactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageReactionsHash() => r'146c0d4d3ca65657a08e3cc115c6c2291cc5a0dd';

final class MessageReactionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MessageReactionModel>>, int> {
  MessageReactionsFamily._()
    : super(
        retry: null,
        name: r'messageReactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MessageReactionsProvider call(int messageId) =>
      MessageReactionsProvider._(argument: messageId, from: this);

  @override
  String toString() => r'messageReactionsProvider';
}

@ProviderFor(MessageReactionNotifier)
final messageReactionProvider = MessageReactionNotifierProvider._();

final class MessageReactionNotifierProvider
    extends $NotifierProvider<MessageReactionNotifier, AsyncValue<void>> {
  MessageReactionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageReactionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageReactionNotifierHash();

  @$internal
  @override
  MessageReactionNotifier create() => MessageReactionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$messageReactionNotifierHash() =>
    r'2683e0c55b873435c67c47cd96e3fd021c57719c';

abstract class _$MessageReactionNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
