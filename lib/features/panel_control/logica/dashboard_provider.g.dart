// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$resumenMensualHash() => r'9e31c9a839bfaafbf34bf7dc3d1468dfe4f458ae';

/// Resumen de ingresos/gastos/ahorro del mes seleccionado.
///
/// IMPORTANTE: calcula sobre TODOS los movimientos del mes consultando la base
/// (no la lista paginada de 30), para evitar totales incorrectos. Observa el
/// controlador de movimientos sólo como disparador de recálculo.
///
/// Copied from [ResumenMensual].
@ProviderFor(ResumenMensual)
final resumenMensualProvider = AutoDisposeAsyncNotifierProvider<ResumenMensual,
    Map<String, double>>.internal(
  ResumenMensual.new,
  name: r'resumenMensualProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$resumenMensualHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ResumenMensual = AutoDisposeAsyncNotifier<Map<String, double>>;
String _$totalesGlobalesHash() => r'579b97b037dc7d1f29f519afb943edcded60de40';

/// Totales de TODO el histórico (no de un mes): {ingresos, gastos, ahorros}.
/// Es la base para calcular la plata realmente disponible (saldo corrido).
///
/// Copied from [TotalesGlobales].
@ProviderFor(TotalesGlobales)
final totalesGlobalesProvider = AutoDisposeAsyncNotifierProvider<
    TotalesGlobales, Map<String, double>>.internal(
  TotalesGlobales.new,
  name: r'totalesGlobalesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalesGlobalesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TotalesGlobales = AutoDisposeAsyncNotifier<Map<String, double>>;
String _$gastosPorCategoriaHash() =>
    r'222be420145ce703c175af5451a25fad3761bc70';

/// Gastos del mes agrupados por categoría (clave "nombre|colorHex" → total).
/// También sobre todos los movimientos del mes (no la lista paginada).
///
/// Copied from [GastosPorCategoria].
@ProviderFor(GastosPorCategoria)
final gastosPorCategoriaProvider = AutoDisposeAsyncNotifierProvider<
    GastosPorCategoria, Map<String, double>>.internal(
  GastosPorCategoria.new,
  name: r'gastosPorCategoriaProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gastosPorCategoriaHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GastosPorCategoria = AutoDisposeAsyncNotifier<Map<String, double>>;
String _$gastoPorCategoriaIdHash() =>
    r'daeb7de4bbb094238855d40929bc19c781f5b4e0';

/// Gastos del mes por categoria_id (para los presupuestos). Sobre TODOS los
/// movimientos del mes (no la lista paginada de 30).
///
/// Copied from [GastoPorCategoriaId].
@ProviderFor(GastoPorCategoriaId)
final gastoPorCategoriaIdProvider = AutoDisposeAsyncNotifierProvider<
    GastoPorCategoriaId, Map<int, double>>.internal(
  GastoPorCategoriaId.new,
  name: r'gastoPorCategoriaIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gastoPorCategoriaIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GastoPorCategoriaId = AutoDisposeAsyncNotifier<Map<int, double>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
