// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dolar_blue_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dolarBlueHash() => r'a8ac1f3d1158d84fdd4bcb780a1fd59d2a49fc04';

/// Cotización del blue desde DolarApi.com (pública, sin clave). Solo se usa
/// para convertir aportes a metas en dólares y para mostrar el patrimonio en
/// dólares: el disponible no depende de ella.
///
/// Copied from [DolarBlue].
@ProviderFor(DolarBlue)
final dolarBlueProvider =
    AutoDisposeAsyncNotifierProvider<DolarBlue, Cotizacion?>.internal(
  DolarBlue.new,
  name: r'dolarBlueProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dolarBlueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DolarBlue = AutoDisposeAsyncNotifier<Cotizacion?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
