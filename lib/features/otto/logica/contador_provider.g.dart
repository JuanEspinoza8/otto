// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contador_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$devolucionContadorHash() =>
    r'cd3188ed96d07ed03d40822e08f37c737284158a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Devolución de Otto contador para un mes, o null si la IA está apagada o
/// no respondió. La respuesta queda guardada por mes (ver ServicioIaContador).
///
/// Copied from [devolucionContador].
@ProviderFor(devolucionContador)
const devolucionContadorProvider = DevolucionContadorFamily();

/// Devolución de Otto contador para un mes, o null si la IA está apagada o
/// no respondió. La respuesta queda guardada por mes (ver ServicioIaContador).
///
/// Copied from [devolucionContador].
class DevolucionContadorFamily extends Family<AsyncValue<String?>> {
  /// Devolución de Otto contador para un mes, o null si la IA está apagada o
  /// no respondió. La respuesta queda guardada por mes (ver ServicioIaContador).
  ///
  /// Copied from [devolucionContador].
  const DevolucionContadorFamily();

  /// Devolución de Otto contador para un mes, o null si la IA está apagada o
  /// no respondió. La respuesta queda guardada por mes (ver ServicioIaContador).
  ///
  /// Copied from [devolucionContador].
  DevolucionContadorProvider call(
    Periodo mes,
  ) {
    return DevolucionContadorProvider(
      mes,
    );
  }

  @override
  DevolucionContadorProvider getProviderOverride(
    covariant DevolucionContadorProvider provider,
  ) {
    return call(
      provider.mes,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'devolucionContadorProvider';
}

/// Devolución de Otto contador para un mes, o null si la IA está apagada o
/// no respondió. La respuesta queda guardada por mes (ver ServicioIaContador).
///
/// Copied from [devolucionContador].
class DevolucionContadorProvider extends AutoDisposeFutureProvider<String?> {
  /// Devolución de Otto contador para un mes, o null si la IA está apagada o
  /// no respondió. La respuesta queda guardada por mes (ver ServicioIaContador).
  ///
  /// Copied from [devolucionContador].
  DevolucionContadorProvider(
    Periodo mes,
  ) : this._internal(
          (ref) => devolucionContador(
            ref as DevolucionContadorRef,
            mes,
          ),
          from: devolucionContadorProvider,
          name: r'devolucionContadorProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$devolucionContadorHash,
          dependencies: DevolucionContadorFamily._dependencies,
          allTransitiveDependencies:
              DevolucionContadorFamily._allTransitiveDependencies,
          mes: mes,
        );

  DevolucionContadorProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mes,
  }) : super.internal();

  final Periodo mes;

  @override
  Override overrideWith(
    FutureOr<String?> Function(DevolucionContadorRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DevolucionContadorProvider._internal(
        (ref) => create(ref as DevolucionContadorRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mes: mes,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _DevolucionContadorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DevolucionContadorProvider && other.mes == mes;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mes.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DevolucionContadorRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `mes` of this provider.
  Periodo get mes;
}

class _DevolucionContadorProviderElement
    extends AutoDisposeFutureProviderElement<String?>
    with DevolucionContadorRef {
  _DevolucionContadorProviderElement(super.provider);

  @override
  Periodo get mes => (origin as DevolucionContadorProvider).mes;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
