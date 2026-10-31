// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tema_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$temaControladorHash() => r'c5d4c7922605f11e2fe6ca64cf1b87a32633bce6';

/// Modo claro u oscuro, guardado en las preferencias (oscuro por defecto).
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
