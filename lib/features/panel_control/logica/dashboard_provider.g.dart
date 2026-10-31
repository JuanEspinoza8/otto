// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$totalesMesHash() => r'34b1eafc6fe97a10e013f38436a0351f2dc284b0';

/// Totales del mes seleccionado (sobre todos sus movimientos).
///
/// Copied from [totalesMes].
@ProviderFor(totalesMes)
final totalesMesProvider = AutoDisposeFutureProvider<TotalesMes>.internal(
  totalesMes,
  name: r'totalesMesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$totalesMesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalesMesRef = AutoDisposeFutureProviderRef<TotalesMes>;
String _$gastosPorCategoriaHash() =>
    r'4fa4df7927d2b5b09a30dcd5a5870dcb591af7b3';

/// Gastos del mes seleccionado por categoría ({categoriaId: total}).
///
/// Copied from [gastosPorCategoria].
@ProviderFor(gastosPorCategoria)
final gastosPorCategoriaProvider =
    AutoDisposeFutureProvider<Map<int, Dinero>>.internal(
  gastosPorCategoria,
  name: r'gastosPorCategoriaProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gastosPorCategoriaHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GastosPorCategoriaRef = AutoDisposeFutureProviderRef<Map<int, Dinero>>;
String _$rankingGastosHash() => r'eefd025fde42f1bd9f947ceffc30a48d9282eb5c';

/// Gastos del mes por categoría, de mayor a menor, con la categoría resuelta.
///
/// Copied from [rankingGastos].
@ProviderFor(rankingGastos)
final rankingGastosProvider =
    AutoDisposeFutureProvider<List<TotalCategoria>>.internal(
  rankingGastos,
  name: r'rankingGastosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rankingGastosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RankingGastosRef = AutoDisposeFutureProviderRef<List<TotalCategoria>>;
String _$resumenDelMesHash() => r'669b135d61fef78a5882ff9a126d7d18c034a0de';

/// Ingresos y egresos por categoría del mes seleccionado.
///
/// Copied from [resumenDelMes].
@ProviderFor(resumenDelMes)
final resumenDelMesProvider =
    AutoDisposeFutureProvider<ResumenMesData>.internal(
  resumenDelMes,
  name: r'resumenDelMesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$resumenDelMesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ResumenDelMesRef = AutoDisposeFutureProviderRef<ResumenMesData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
