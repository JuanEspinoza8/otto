// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pendientes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendientesMesHash() => r'8e1025e679bb8d482c5c4d1478a84687492ce7dd';

/// Calcula y aplica (con confirmación manual) los movimientos recurrentes del
/// mes seleccionado: sueldo como ingreso, gastos fijos y cuotas como gastos.
///
/// Copied from [PendientesMes].
@ProviderFor(PendientesMes)
final pendientesMesProvider = AutoDisposeAsyncNotifierProvider<PendientesMes,
    List<PendienteRecurrencia>>.internal(
  PendientesMes.new,
  name: r'pendientesMesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendientesMesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendientesMes = AutoDisposeAsyncNotifier<List<PendienteRecurrencia>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
