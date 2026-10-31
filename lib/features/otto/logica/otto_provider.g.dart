// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otto_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ottoControladorHash() => r'71831d8380aa0c9c4d20e22f3400ef1830e7099c';

/// Chat "Decile a Otto": interpreta el mensaje (con IA si está activa, si no
/// con el parser local) y registra cada propuesta con el mismo servicio que el
/// formulario.
///
/// Copied from [OttoControlador].
@ProviderFor(OttoControlador)
final ottoControladorProvider =
    AutoDisposeNotifierProvider<OttoControlador, EstadoChatOtto>.internal(
  OttoControlador.new,
  name: r'ottoControladorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ottoControladorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OttoControlador = AutoDisposeNotifier<EstadoChatOtto>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
