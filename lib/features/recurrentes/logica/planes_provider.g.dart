// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fijosHash() => r'576e2281f4d96b9ae54e50957c3e07328402f09d';

/// See also [fijos].
@ProviderFor(fijos)
final fijosProvider = AutoDisposeProvider<List<Plan>>.internal(
  fijos,
  name: r'fijosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fijosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FijosRef = AutoDisposeProviderRef<List<Plan>>;
String _$cuotasHash() => r'17843ebfe4dec1249d10501a795243115a35197d';

/// See also [cuotas].
@ProviderFor(cuotas)
final cuotasProvider = AutoDisposeProvider<List<Plan>>.internal(
  cuotas,
  name: r'cuotasProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cuotasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CuotasRef = AutoDisposeProviderRef<List<Plan>>;
String _$pendientesMesHash() => r'dd18e09dc048adda3d90f2dfbd919d5ffa38b17b';

/// Pendientes del mes seleccionado.
///
/// Copied from [pendientesMes].
@ProviderFor(pendientesMes)
final pendientesMesProvider =
    AutoDisposeFutureProvider<List<Pendiente>>.internal(
  pendientesMes,
  name: r'pendientesMesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendientesMesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendientesMesRef = AutoDisposeFutureProviderRef<List<Pendiente>>;
String _$planesControladorHash() => r'08bdc060366ecfad8f2809b185a2f4095b79c880';

/// Sueldo, gastos fijos y cuotas.
///
/// Copied from [PlanesControlador].
@ProviderFor(PlanesControlador)
final planesControladorProvider =
    AutoDisposeAsyncNotifierProvider<PlanesControlador, List<Plan>>.internal(
  PlanesControlador.new,
  name: r'planesControladorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$planesControladorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlanesControlador = AutoDisposeAsyncNotifier<List<Plan>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
