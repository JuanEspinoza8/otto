// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movimientos_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$movimientosControladorHash() =>
    r'5c8d36c1d1da7398b6045683dc5ad58d2dc4c642';

/// Movimientos del mes seleccionado, de a páginas de 30.
///
/// Copied from [MovimientosControlador].
@ProviderFor(MovimientosControlador)
final movimientosControladorProvider = AutoDisposeAsyncNotifierProvider<
    MovimientosControlador, List<Movimiento>>.internal(
  MovimientosControlador.new,
  name: r'movimientosControladorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$movimientosControladorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MovimientosControlador = AutoDisposeAsyncNotifier<List<Movimiento>>;
String _$criteriosBusquedaHash() => r'e66eddfdc2eb10b5463f8250b39324f3df6fca95';

/// See also [CriteriosBusqueda].
@ProviderFor(CriteriosBusqueda)
final criteriosBusquedaProvider = AutoDisposeNotifierProvider<CriteriosBusqueda,
    BusquedaMovimientos>.internal(
  CriteriosBusqueda.new,
  name: r'criteriosBusquedaProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$criteriosBusquedaHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CriteriosBusqueda = AutoDisposeNotifier<BusquedaMovimientos>;
String _$movimientosBuscadosHash() =>
    r'7ba7b98ea9d75b6d05b27174ab148a490d8b68fe';

/// Movimientos del mes seleccionado con filtro y búsqueda resueltos en SQL
/// (no sobre la página ya cargada), de a páginas.
///
/// Copied from [MovimientosBuscados].
@ProviderFor(MovimientosBuscados)
final movimientosBuscadosProvider = AutoDisposeAsyncNotifierProvider<
    MovimientosBuscados, List<Movimiento>>.internal(
  MovimientosBuscados.new,
  name: r'movimientosBuscadosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$movimientosBuscadosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MovimientosBuscados = AutoDisposeAsyncNotifier<List<Movimiento>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
