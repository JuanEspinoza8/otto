// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movimientos_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$movimientosFiltradosHash() =>
    r'a4ab7bb18bcaf1b86b902ef053081c4126c02640';

/// See also [movimientosFiltrados].
@ProviderFor(movimientosFiltrados)
final movimientosFiltradosProvider =
    AutoDisposeProvider<List<Movimiento>>.internal(
  movimientosFiltrados,
  name: r'movimientosFiltradosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$movimientosFiltradosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MovimientosFiltradosRef = AutoDisposeProviderRef<List<Movimiento>>;
String _$movimientosControladorHash() =>
    r'26a463a1b0adb9e28cf008633a3ea519f3520655';

/// See also [MovimientosControlador].
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
String _$filtroMovimientosHash() => r'8ff29c52dd94109d4a3a7d59bd719da6d80f892b';

/// See also [FiltroMovimientos].
@ProviderFor(FiltroMovimientos)
final filtroMovimientosProvider =
    AutoDisposeNotifierProvider<FiltroMovimientos, String>.internal(
  FiltroMovimientos.new,
  name: r'filtroMovimientosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filtroMovimientosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FiltroMovimientos = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
