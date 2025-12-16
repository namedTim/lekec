// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dev_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(devActions)
const devActionsProvider = DevActionsProvider._();

final class DevActionsProvider
    extends $FunctionalProvider<DevActions, DevActions, DevActions>
    with $Provider<DevActions> {
  const DevActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devActionsHash();

  @$internal
  @override
  $ProviderElement<DevActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DevActions create(Ref ref) {
    return devActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DevActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DevActions>(value),
    );
  }
}

String _$devActionsHash() => r'3ffe9d8a96685d873c4b71feb9dd85fec338d4ba';
