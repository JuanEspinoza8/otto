// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'horas_extras_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$horasExtrasMesHash() => r'542bbd5d2ce4291d6b4459aa983e4cdc66a39166';

/// Gestiona la pregunta mensual "¿hiciste horas extras?".
///
/// Devuelve `true` si hay que mostrar el cartel este mes (hay valor de hora
/// extra configurado y el usuario todavía no respondió en el período actual).
///
/// Copied from [HorasExtrasMes].
@ProviderFor(HorasExtrasMes)
final horasExtrasMesProvider =
    AutoDisposeAsyncNotifierProvider<HorasExtrasMes, bool>.internal(
  HorasExtrasMes.new,
  name: r'horasExtrasMesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$horasExtrasMesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HorasExtrasMes = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
