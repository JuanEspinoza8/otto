// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$totalesMesHash() => r'34b1eafc6fe97a10e013f38436a0351f2dc284b0';

/// Totales del mes seleccionado (sobre todos sus movimientos).
///
/// Copied from [totalesMes].
@ProviderFor(totalesMes)
final totalesMesProvider = AutoDisposeFutureProvider<TotalesMes>.internal(
  totalesMes,
  name: r'totalesMesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$totalesMesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalesMesRef = AutoDisposeFutureProviderRef<TotalesMes>;
String _$gastosPorCategoriaHash() =>
    r'4fa4df7927d2b5b09a30dcd5a5870dcb591af7b3';

/// Gastos del mes seleccionado por categoría ({categoriaId: total}).
///
/// Copied from [gastosPorCategoria].
@ProviderFor(gastosPorCategoria)
final gastosPorCategoriaProvider =
    AutoDisposeFutureProvider<Map<int, Dinero>>.internal(
  gastosPorCategoria,
  name: r'gastosPorCategoriaProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gastosPorCategoriaHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GastosPorCategoriaRef = AutoDisposeFutureProviderRef<Map<int, Dinero>>;
String _$rankingGastosHash() => r'eefd025fde42f1bd9f947ceffc30a48d9282eb5c';

/// Gastos del mes por categoría, de mayor a menor, con la categoría resuelta.
///
/// Copied from [rankingGastos].
@ProviderFor(rankingGastos)
final rankingGastosProvider =
    AutoDisposeFutureProvider<List<TotalCategoria>>.internal(
  rankingGastos,
  name: r'rankingGastosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rankingGastosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RankingGastosRef = AutoDisposeFutureProviderRef<List<TotalCategoria>>;
String _$resumenDeMesHash() => r'074e1fe0664139d34f2d91a3f1dd79a6a821aca9';

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

/// Ingresos y egresos por categoría de un mes.
///
/// Copied from [resumenDeMes].
@ProviderFor(resumenDeMes)
const resumenDeMesProvider = ResumenDeMesFamily();

/// Ingresos y egresos por categoría de un mes.
///
/// Copied from [resumenDeMes].
class ResumenDeMesFamily extends Family<AsyncValue<ResumenMesData>> {
  /// Ingresos y egresos por categoría de un mes.
  ///
  /// Copied from [resumenDeMes].
  const ResumenDeMesFamily();

  /// Ingresos y egresos por categoría de un mes.
  ///
  /// Copied from [resumenDeMes].
  ResumenDeMesProvider call(
    Periodo mes,
  ) {
    return ResumenDeMesProvider(
      mes,
    );
  }

  @override
  ResumenDeMesProvider getProviderOverride(
    covariant ResumenDeMesProvider provider,
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
  String? get name => r'resumenDeMesProvider';
}

/// Ingresos y egresos por categoría de un mes.
///
/// Copied from [resumenDeMes].
class ResumenDeMesProvider extends AutoDisposeFutureProvider<ResumenMesData> {
  /// Ingresos y egresos por categoría de un mes.
  ///
  /// Copied from [resumenDeMes].
  ResumenDeMesProvider(
    Periodo mes,
  ) : this._internal(
          (ref) => resumenDeMes(
            ref as ResumenDeMesRef,
            mes,
          ),
          from: resumenDeMesProvider,
          name: r'resumenDeMesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$resumenDeMesHash,
          dependencies: ResumenDeMesFamily._dependencies,
          allTransitiveDependencies:
              ResumenDeMesFamily._allTransitiveDependencies,
          mes: mes,
        );

  ResumenDeMesProvider._internal(
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
    FutureOr<ResumenMesData> Function(ResumenDeMesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ResumenDeMesProvider._internal(
        (ref) => create(ref as ResumenDeMesRef),
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
  AutoDisposeFutureProviderElement<ResumenMesData> createElement() {
    return _ResumenDeMesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ResumenDeMesProvider && other.mes == mes;
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
mixin ResumenDeMesRef on AutoDisposeFutureProviderRef<ResumenMesData> {
  /// The parameter `mes` of this provider.
  Periodo get mes;
}

class _ResumenDeMesProviderElement
    extends AutoDisposeFutureProviderElement<ResumenMesData>
    with ResumenDeMesRef {
  _ResumenDeMesProviderElement(super.provider);

  @override
  Periodo get mes => (origin as ResumenDeMesProvider).mes;
}

String _$resumenDelMesHash() => r'5356781538b0bf14ab993b0b80bafc7397ca1d5c';

/// El resumen del mes seleccionado.
///
/// Copied from [resumenDelMes].
@ProviderFor(resumenDelMes)
final resumenDelMesProvider =
    AutoDisposeFutureProvider<ResumenMesData>.internal(
  resumenDelMes,
  name: r'resumenDelMesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$resumenDelMesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ResumenDelMesRef = AutoDisposeFutureProviderRef<ResumenMesData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
