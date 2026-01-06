// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_schedule_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(intakeScheduleGenerator)
const intakeScheduleGeneratorProvider = IntakeScheduleGeneratorProvider._();

final class IntakeScheduleGeneratorProvider
    extends
        $FunctionalProvider<
          IntakeScheduleGenerator,
          IntakeScheduleGenerator,
          IntakeScheduleGenerator
        >
    with $Provider<IntakeScheduleGenerator> {
  const IntakeScheduleGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'intakeScheduleGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$intakeScheduleGeneratorHash();

  @$internal
  @override
  $ProviderElement<IntakeScheduleGenerator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IntakeScheduleGenerator create(Ref ref) {
    return intakeScheduleGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IntakeScheduleGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IntakeScheduleGenerator>(value),
    );
  }
}

String _$intakeScheduleGeneratorHash() =>
    r'61cae6f88085218e902bb294e9c4d3bba56ef68a';

@ProviderFor(planService)
const planServiceProvider = PlanServiceProvider._();

final class PlanServiceProvider
    extends $FunctionalProvider<PlanService, PlanService, PlanService>
    with $Provider<PlanService> {
  const PlanServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planServiceHash();

  @$internal
  @override
  $ProviderElement<PlanService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanService create(Ref ref) {
    return planService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanService>(value),
    );
  }
}

String _$planServiceHash() => r'8f8566755a3956988f130c0994c68a4112beea38';
