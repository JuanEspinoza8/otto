// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dolar_blue_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dolarBlueHash() => r'cf966e5b6e1bca93f15eee8b3641f3634e183c0e';

/// Provider que obtiene la cotización del dólar blue desde DolarApi.com.
/// API pública, gratuita, sin key. Devuelve compra/venta o null si falla.
///
/// Copied from [DolarBlue].
@ProviderFor(DolarBlue)
final dolarBlueProvider =
    AutoDisposeAsyncNotifierProvider<DolarBlue, Map<String, double>?>.internal(
  DolarBlue.new,
  name: r'dolarBlueProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dolarBlueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DolarBlue = AutoDisposeAsyncNotifier<Map<String, double>?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
