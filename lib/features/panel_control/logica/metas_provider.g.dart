// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metas_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$progresoMetasHash() => r'f5660286401aad3cd2f779229b141a1b2faf9c26';

/// See also [progresoMetas].
@ProviderFor(progresoMetas)
final progresoMetasProvider = AutoDisposeProvider<ProgresoMetas>.internal(
  progresoMetas,
  name: r'progresoMetasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$progresoMetasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProgresoMetasRef = AutoDisposeProviderRef<ProgresoMetas>;
String _$patrimonioDolaresHash() => r'89849f015170ce4ddc537ba1453ec02748cfcb1d';

/// See also [patrimonioDolares].
@ProviderFor(patrimonioDolares)
final patrimonioDolaresProvider =
    AutoDisposeFutureProvider<PatrimonioDolares>.internal(
  patrimonioDolares,
  name: r'patrimonioDolaresProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$patrimonioDolaresHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PatrimonioDolaresRef = AutoDisposeFutureProviderRef<PatrimonioDolares>;
String _$metasControladorHash() => r'6da10857244b12616ef7045f1f52a37ac355cd60';

/// Metas de ahorro con su saldo. Cada operación es una transferencia del
/// libro, validada contra el saldo de origen dentro de una transacción.
///
/// Copied from [MetasControlador].
@ProviderFor(MetasControlador)
final metasControladorProvider =
    AutoDisposeAsyncNotifierProvider<MetasControlador, List<Meta>>.internal(
  MetasControlador.new,
  name: r'metasControladorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$metasControladorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MetasControlador = AutoDisposeAsyncNotifier<List<Meta>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
