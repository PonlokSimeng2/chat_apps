// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(emojisBySingleCategory)
final emojisBySingleCategoryProvider = EmojisBySingleCategoryFamily._();

final class EmojisBySingleCategoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EmojiModel>>,
          List<EmojiModel>,
          FutureOr<List<EmojiModel>>
        >
    with $FutureModifier<List<EmojiModel>>, $FutureProvider<List<EmojiModel>> {
  EmojisBySingleCategoryProvider._({
    required EmojisBySingleCategoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'emojisBySingleCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$emojisBySingleCategoryHash();

  @override
  String toString() {
    return r'emojisBySingleCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EmojiModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EmojiModel>> create(Ref ref) {
    final argument = this.argument as String;
    return emojisBySingleCategory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmojisBySingleCategoryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$emojisBySingleCategoryHash() =>
    r'a9c21d1638c08aeb9bf516f006624ed76fb3ccb5';

final class EmojisBySingleCategoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EmojiModel>>, String> {
  EmojisBySingleCategoryFamily._()
    : super(
        retry: null,
        name: r'emojisBySingleCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmojisBySingleCategoryProvider call(String category) =>
      EmojisBySingleCategoryProvider._(argument: category, from: this);

  @override
  String toString() => r'emojisBySingleCategoryProvider';
}

@ProviderFor(emojiCategories)
final emojiCategoriesProvider = EmojiCategoriesProvider._();

final class EmojiCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  EmojiCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emojiCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emojiCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return emojiCategories(ref);
  }
}

String _$emojiCategoriesHash() => r'4b888b155a9f6592575971d21030b2d0a95170ea';

@ProviderFor(SelectedEmojiCategory)
final selectedEmojiCategoryProvider = SelectedEmojiCategoryProvider._();

final class SelectedEmojiCategoryProvider
    extends $NotifierProvider<SelectedEmojiCategory, String> {
  SelectedEmojiCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedEmojiCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedEmojiCategoryHash();

  @$internal
  @override
  SelectedEmojiCategory create() => SelectedEmojiCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedEmojiCategoryHash() =>
    r'231375f3fc4c59363784f335d70665640e4187a0';

abstract class _$SelectedEmojiCategory extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
