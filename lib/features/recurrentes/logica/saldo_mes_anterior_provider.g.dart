// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saldo_mes_anterior_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$saldoMesAnteriorHash() => r'1392784e7b284fa0ed0d6507f792b19c82e3badf';

/// Maneja el "sobrante" del mes anterior: si quedó plata, se ofrece trasladarla
/// al mes actual o aportarla a una meta. Devuelve el monto sobrante (0 si no
/// hay o si ya se resolvió este mes).
///
/// Copied from [SaldoMesAnterior].
@ProviderFor(SaldoMesAnterior)
final saldoMesAnteriorProvider =
    AutoDisposeAsyncNotifierProvider<SaldoMesAnterior, double>.internal(
  SaldoMesAnterior.new,
  name: r'saldoMesAnteriorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$saldoMesAnteriorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SaldoMesAnterior = AutoDisposeAsyncNotifier<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
