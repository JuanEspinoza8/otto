// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ahorro_disponible_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ahorroDisponibleHash() => r'ec147a5041be79f29319c40d7d9fedb3a04f3911';

/// Plata realmente libre para gastar o asignar a metas: un único número,
/// consistente en todo lado (dashboard, formulario y diálogos).
///
/// disponible = ahorro previo (ARS + USD→ARS)
///            + (todos los ingresos históricos − todos los gastos históricos)
///            − lo que hoy está guardado en metas
///
/// Es un **saldo corrido** (histórico), no del mes: así no se rompe al cambiar
/// de mes ni deja "plata fantasma" cuando se asigna a una meta. Cuando aportás
/// a una meta sube "lo guardado en metas" y este número baja en el acto.
///
/// Copied from [ahorroDisponible].
@ProviderFor(ahorroDisponible)
final ahorroDisponibleProvider = AutoDisposeProvider<double>.internal(
  ahorroDisponible,
  name: r'ahorroDisponibleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ahorroDisponibleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AhorroDisponibleRef = AutoDisposeProviderRef<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
