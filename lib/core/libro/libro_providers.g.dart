// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'libro_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$baseDatosHash() => r'30b35f35c52176ef8da318b7178ef2f77d7e2873';

/// La base abierta. En los tests se reemplaza por una en memoria.
///
/// Copied from [baseDatos].
@ProviderFor(baseDatos)
final baseDatosProvider = FutureProvider<Database>.internal(
  baseDatos,
  name: r'baseDatosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$baseDatosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BaseDatosRef = FutureProviderRef<Database>;
String _$disponibleHash() => r'701ac15645bdcf148a41b32e066372f22183fa5f';

/// La plata libre en pesos (saldo de "Libre ARS"). No depende del dólar.
///
/// Copied from [disponible].
@ProviderFor(disponible)
final disponibleProvider = AutoDisposeFutureProvider<Dinero>.internal(
  disponible,
  name: r'disponibleProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$disponibleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DisponibleRef = AutoDisposeFutureProviderRef<Dinero>;
String _$saldosHash() => r'03e4e919e44b2d6055e8deb78cbe21092f7456a9';

/// See also [saldos].
@ProviderFor(saldos)
final saldosProvider = AutoDisposeFutureProvider<Map<int, Dinero>>.internal(
  saldos,
  name: r'saldosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$saldosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SaldosRef = AutoDisposeFutureProviderRef<Map<int, Dinero>>;
String _$cuentasHash() => r'75c5ef3dd64c1564f0d5cd7bb108e50971f2a9bd';

/// See also [cuentas].
@ProviderFor(cuentas)
final cuentasProvider = AutoDisposeFutureProvider<List<Cuenta>>.internal(
  cuentas,
  name: r'cuentasProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cuentasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CuentasRef = AutoDisposeFutureProviderRef<List<Cuenta>>;
String _$versionDatosHash() => r'1aa8f999f666f37256b79fe2aca16f9eb9fadb9c';

/// Contador que sube con cada escritura en la base. Todas las lecturas lo
/// observan, así se recalculan después de guardar (y no al paginar listas).
///
/// Copied from [VersionDatos].
@ProviderFor(VersionDatos)
final versionDatosProvider = NotifierProvider<VersionDatos, int>.internal(
  VersionDatos.new,
  name: r'versionDatosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$versionDatosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VersionDatos = Notifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
