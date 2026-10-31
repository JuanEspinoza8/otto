// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saldo_mes_anterior_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$saldoMesAnteriorHash() => r'0f1731e6af28153e349a4065c6edf249546aebd9';

/// El "sobrante" del mes anterior: lo que quedó libre ese mes, ofrecido para
/// guardarlo en una meta. Nunca se ofrece más que el disponible de hoy.
///
/// Copied from [SaldoMesAnterior].
@ProviderFor(SaldoMesAnterior)
final saldoMesAnteriorProvider =
    AutoDisposeAsyncNotifierProvider<SaldoMesAnterior, Dinero>.internal(
  SaldoMesAnterior.new,
  name: r'saldoMesAnteriorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$saldoMesAnteriorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SaldoMesAnterior = AutoDisposeAsyncNotifier<Dinero>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
