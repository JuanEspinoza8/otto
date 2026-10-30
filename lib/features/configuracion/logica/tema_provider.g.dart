// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tema_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$temaControladorHash() => r'5545574a8392f065d597ce42fa1c909803f82ea2';

/// Controlador del modo de tema (claro/oscuro) persistido en disco.
///
/// Por defecto la app arranca en modo oscuro (diseño de referencia).
///
/// Copied from [TemaControlador].
@ProviderFor(TemaControlador)
final temaControladorProvider =
    NotifierProvider<TemaControlador, ThemeMode>.internal(
  TemaControlador.new,
  name: r'temaControladorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$temaControladorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TemaControlador = Notifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
