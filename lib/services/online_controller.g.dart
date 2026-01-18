// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnlineGame)
final onlineGameProvider = OnlineGameFamily._();

final class OnlineGameProvider
    extends $NotifierProvider<OnlineGame, GameState> {
  OnlineGameProvider._({
    required OnlineGameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'onlineGameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$onlineGameHash();

  @override
  String toString() {
    return r'onlineGameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OnlineGame create() => OnlineGame();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OnlineGameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$onlineGameHash() => r'f28c7291b50713cd72c48cc3e1a04d985a883695';

final class OnlineGameFamily extends $Family
    with
        $ClassFamilyOverride<
          OnlineGame,
          GameState,
          GameState,
          GameState,
          String
        > {
  OnlineGameFamily._()
    : super(
        retry: null,
        name: r'onlineGameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OnlineGameProvider call(String roomId) =>
      OnlineGameProvider._(argument: roomId, from: this);

  @override
  String toString() => r'onlineGameProvider';
}

abstract class _$OnlineGame extends $Notifier<GameState> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  GameState build(String roomId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GameState, GameState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GameState, GameState>,
              GameState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
