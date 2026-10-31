import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/base_de_datos/esquema.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/meta.dart';
import 'dolar_blue_provider.dart';

part 'metas_provider.g.dart';

/// Metas de ahorro con su saldo. Cada operación es una transferencia del
/// libro, validada contra el saldo de origen dentro de una transacción.
@riverpod
class MetasControlador extends _$MetasControlador {
  @override
  Future<List<Meta>> build() async => (await consultasLibro(ref)).metas();

  double? get _cotizacion => ref.read(dolarBlueProvider).valueOrNull?.venta;

  Future<void> crear({required String nombre, required String icono, required Dinero objetivo}) =>
      escribirEnLibro(ref, (l) => l.crearMeta(nombre: nombre, icono: icono, objetivo: objetivo, fecha: DateTime.now()));

  Future<void> editar(Meta meta, {required String nombre, required String icono, required Dinero objetivo}) =>
      escribirEnLibro(ref, (l) => l.editarMeta(meta.id, nombre: nombre, icono: icono, objetivo: objetivo));

  /// Aporta pesos del disponible (si la meta es en dólares, se convierten).
  Future<void> aportar(Meta meta, Dinero pesos, {DateTime? fecha}) => escribirEnLibro(
      ref, (l) => l.aportarAMeta(meta.id, pesos, cotizacion: _cotizacion, fecha: fecha ?? DateTime.now()));

  /// Retira [monto] en la moneda de la meta y lo devuelve al disponible.
  Future<void> retirar(Meta meta, Dinero monto) => escribirEnLibro(
      ref, (l) => l.retirarDeMeta(meta.id, monto, cotizacion: _cotizacion, fecha: DateTime.now()));

  Future<void> mover(Meta origen, Meta destino, Dinero monto) => escribirEnLibro(
      ref, (l) => l.moverEntreMetas(origen.id, destino.id, monto, cotizacion: _cotizacion, fecha: DateTime.now()));

  Future<void> eliminar(Meta meta) =>
      escribirEnLibro(ref, (l) => l.eliminarMeta(meta.id, cotizacion: _cotizacion, fecha: DateTime.now()));
}

/// Avance de todas las metas juntas.
class ProgresoMetas {
  const ProgresoMetas({
    required this.cantidad,
    required this.porcentaje,
    required this.guardadoArs,
    required this.guardadoUsd,
  });

  final int cantidad;

  /// 0 a 100. Cada meta cuenta como máximo su objetivo, así una meta
  /// sobrepasada no tapa a otra incompleta.
  final int porcentaje;
  final Dinero guardadoArs;
  final Dinero guardadoUsd;
}

@riverpod
ProgresoMetas progresoMetas(Ref ref) {
  final metas = ref.watch(metasControladorProvider).valueOrNull ?? const [];
  final blue = ref.watch(dolarBlueProvider).valueOrNull?.venta;

  var ars = const Dinero.cero();
  var usd = const Dinero.cero(Moneda.usd);
  for (final m in metas) {
    if (m.esUsd) {
      usd += m.saldo;
    } else {
      ars += m.saldo;
    }
  }

  var porcentaje = 0;
  final conObjetivo = metas.where((m) => m.objetivo.esPositivo).toList();
  final hayUsd = conObjetivo.any((m) => m.esUsd);
  if (conObjetivo.isNotEmpty && (!hayUsd || (blue != null && blue > 0))) {
    // Todo en pesos para poder sumar metas de distinta moneda (sin dólares
    // no hace falta la cotización: convertir pesos a pesos no la usa).
    Dinero enPesos(Dinero d) => d.convertir(Moneda.ars, blue ?? 0);
    final objetivo = conObjetivo.fold(const Dinero.cero(), (s, m) => s + enPesos(m.objetivo));
    final avance = conObjetivo.fold(const Dinero.cero(), (s, m) => s + enPesos(m.saldo.min(m.objetivo)));
    porcentaje = avance.porcentajeDe(objetivo).clamp(0, 100);
  } else if (conObjetivo.isNotEmpty) {
    // Sin cotización: promedio simple de las metas.
    porcentaje = conObjetivo.fold(0, (s, m) => s + m.porcentajeProgreso) ~/ conObjetivo.length;
  }

  return ProgresoMetas(cantidad: metas.length, porcentaje: porcentaje, guardadoArs: ars, guardadoUsd: usd);
}

/// Dólares del usuario: los libres (ahorro previo) y los guardados en metas.
class PatrimonioDolares {
  const PatrimonioDolares({required this.libres, required this.enMetas});
  final Dinero libres;
  final Dinero enMetas;

  Dinero get total => libres + enMetas;

  /// Valor estimado en pesos al blue (solo informativo).
  Dinero? enPesos(double? blue) =>
      (blue == null || blue <= 0) ? null : total.convertir(Moneda.ars, blue);
}

@riverpod
Future<PatrimonioDolares> patrimonioDolares(Ref ref) async {
  final saldos = await ref.watch(saldosProvider.future);
  final metas = await ref.watch(metasControladorProvider.future);
  final enMetas = metas.where((m) => m.esUsd).fold(const Dinero.cero(Moneda.usd), (s, m) => s + m.saldo);
  return PatrimonioDolares(
    libres: saldos[Esquema.cuentaDolares] ?? const Dinero.cero(Moneda.usd),
    enMetas: enMetas,
  );
}
