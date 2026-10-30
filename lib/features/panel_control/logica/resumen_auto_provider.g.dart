// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resumen_auto_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$resumenAutoHash() => r'2b671f0332a6faa5614488b4bc0c5ea034dab951';

/// Indica si hay un resumen del mes anterior por mostrar (al arrancar el mes
/// nuevo). Devuelve la fecha del mes a resumir, o null si ya se vio / no hubo
/// movimientos.
///
/// Copied from [ResumenAuto].
@ProviderFor(ResumenAuto)
final resumenAutoProvider =
    AutoDisposeAsyncNotifierProvider<ResumenAuto, DateTime?>.internal(
  ResumenAuto.new,
  name: r'resumenAutoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$resumenAutoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ResumenAuto = AutoDisposeAsyncNotifier<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
