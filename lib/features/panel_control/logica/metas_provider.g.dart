// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metas_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$progresoMetaTotalHash() => r'6c1e40f246f78f571b3842c633fec1eab0235067';

/// Provider derivado que calcula el progreso total de todas las metas.
///
/// Copied from [progresoMetaTotal].
@ProviderFor(progresoMetaTotal)
final progresoMetaTotalProvider =
    AutoDisposeProvider<Map<String, double>>.internal(
  progresoMetaTotal,
  name: r'progresoMetaTotalProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$progresoMetaTotalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProgresoMetaTotalRef = AutoDisposeProviderRef<Map<String, double>>;
String _$metasControladorHash() => r'165714f50fff6a01c8b551d9220d697374f4b9de';

/// Provider que gestiona las metas de ahorro con sus submetas.
///
/// Copied from [MetasControlador].
@ProviderFor(MetasControlador)
final metasControladorProvider = AutoDisposeAsyncNotifierProvider<
    MetasControlador, Map<Meta, List<Submeta>>>.internal(
  MetasControlador.new,
  name: r'metasControladorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$metasControladorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MetasControlador = AutoDisposeAsyncNotifier<Map<Meta, List<Submeta>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
