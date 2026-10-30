import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../movimientos/modelo/movimiento.dart';
import '../../movimientos/repositorio/movimiento_repositorio.dart';
import '../modelo/meta.dart';
import '../modelo/submeta.dart';
import '../repositorio/meta_repositorio.dart';
import '../repositorio/submeta_repositorio.dart';
import 'dolar_blue_provider.dart';

part 'metas_provider.g.dart';

/// Provider que gestiona las metas de ahorro con sus submetas.
@riverpod
class MetasControlador extends _$MetasControlador {
  // Campos `final` inicializados en la declaración: si fueran `late final` y se
  // asignaran dentro de build(), ref.invalidateSelf() re-ejecutaría build()
  // sobre la misma instancia y lanzaría LateInitializationError.
  final MetaRepositorio _metaRepo = MetaRepositorio();
  final SubmetaRepositorio _submetaRepo = SubmetaRepositorio();
  final MovimientoRepositorio _movRepo = MovimientoRepositorio();

  @override
  FutureOr<Map<Meta, List<Submeta>>> build() async {
    return await _metaRepo.obtenerConSubmetas();
  }

  /// Agrega una nueva meta de ahorro.
  Future<int> agregarMeta(Meta meta) async {
    final id = await _metaRepo.insertar(meta);
    ref.invalidateSelf();
    return id;
  }

  /// Actualiza una meta existente.
  Future<void> actualizarMeta(Meta meta) async {
    await _metaRepo.actualizar(meta);
    ref.invalidateSelf();
  }

  /// Elimina una meta y sus aportes (movimientos de ahorro). Al borrarlos, esa
  /// plata vuelve a contar como disponible.
  Future<void> eliminarMeta(int id) async {
    await _movRepo.eliminarPorMeta(id);
    await _metaRepo.eliminar(id);
    ref.invalidateSelf();
    ref.invalidate(movimientosControladorProvider);
  }

  /// Aporta [montoPesos] (siempre en PESOS, que es lo que el usuario tiene) a
  /// una meta. Si la meta es en USD, convierte con el [blue]. Además del avance
  /// de la meta, deja registrado un movimiento de tipo 'ahorro' para que la
  /// plata salga del disponible y quede en el historial.
  Future<void> aportar(Meta meta, double montoPesos, {double blue = 0}) async {
    if (montoPesos <= 0) return;

    // Monto en la moneda de la meta (para su progreso).
    double montoMeta = montoPesos;
    double pesosAplicados = montoPesos;
    if (meta.esUsd) {
      if (blue <= 0) return; // sin cotización no se puede convertir
      montoMeta = montoPesos / blue;
    }

    // No se puede sobrepasar el objetivo: se aporta como máximo lo que falta.
    final falta = (meta.montoObjetivo - meta.montoActual).clamp(0.0, double.infinity);
    if (montoMeta > falta) {
      montoMeta = falta;
      pesosAplicados = meta.esUsd ? montoMeta * blue : montoMeta;
    }
    if (montoMeta <= 0) return; // la meta ya está completa

    final nuevoMonto = (meta.montoActual + montoMeta).clamp(0.0, meta.montoObjetivo);
    await _metaRepo.actualizar(meta.copiaCon(montoActual: nuevoMonto));

    await _movRepo.insertar(Movimiento(
      monto: pesosAplicados,
      fecha: DateTime.now(),
      descripcion: 'Ahorro: ${meta.nombre}',
      tipo: 'ahorro',
      metaId: meta.id,
      montoMeta: montoMeta,
    ));

    ref.invalidateSelf();
    ref.invalidate(movimientosControladorProvider);
  }

  /// Deshace un aporte concreto: borra el movimiento de ahorro y le resta a la
  /// meta el monto (en su moneda) que ese aporte había sumado. La plata vuelve
  /// al disponible.
  Future<void> revertirAporte(Movimiento aporte) async {
    if (aporte.id == null || !aporte.esAhorro) return;

    if (aporte.metaId != null) {
      final datos = state.valueOrNull ?? await future;
      final metas = datos.keys.where((m) => m.id == aporte.metaId);
      if (metas.isNotEmpty) {
        final meta = metas.first;
        final delta = aporte.montoMeta ?? aporte.monto;
        final nuevoMonto = (meta.montoActual - delta).clamp(0.0, double.infinity);
        await _metaRepo.actualizar(meta.copiaCon(montoActual: nuevoMonto));
      }
    }

    await _movRepo.eliminar(aporte.id!);
    ref.invalidateSelf();
    ref.invalidate(movimientosControladorProvider);
  }

  /// Saca [montoMeta] (en la moneda de la meta) de una meta y lo devuelve al
  /// disponible. Ajusta los aportes (del más nuevo al más viejo) para que el
  /// historial siga reflejando lo realmente guardado.
  Future<void> retirar(Meta meta, double montoMeta) async {
    if (meta.id == null || montoMeta <= 0) return;
    final retiro = montoMeta.clamp(0.0, meta.montoActual);
    if (retiro <= 0) return;

    await _metaRepo.actualizar(meta.copiaCon(montoActual: meta.montoActual - retiro));
    await _ajustarAportesPorRetiro(meta.id!, retiro);

    ref.invalidateSelf();
    ref.invalidate(movimientosControladorProvider);
  }

  /// Mueve [montoPesos] de una meta a otra (pasando por el disponible). El
  /// destino nunca se sobrepasa; si no entra todo, el resto queda disponible.
  Future<void> moverEntreMetas(Meta origen, Meta destino, double montoPesos, {double blue = 0}) async {
    if (origen.id == null || destino.id == null || origen.id == destino.id || montoPesos <= 0) return;
    final montoMetaOrigen = origen.esUsd ? (blue > 0 ? montoPesos / blue : 0.0) : montoPesos;
    if (montoMetaOrigen <= 0) return;
    await retirar(origen, montoMetaOrigen);
    await aportar(destino, montoPesos, blue: blue);
  }

  /// Reduce (del aporte más nuevo al más viejo) los movimientos de ahorro de la
  /// meta en [montoMetaARetirar] (moneda de la meta): borra los que se consumen
  /// enteros y ajusta el último parcialmente.
  Future<void> _ajustarAportesPorRetiro(int metaId, double montoMetaARetirar) async {
    var restante = montoMetaARetirar;
    final aportes = await _movRepo.obtenerAhorrosDeMeta(metaId);
    for (final ap in aportes) {
      if (restante <= 0.009) break;
      final metaDelAporte = ap.montoMeta ?? ap.monto;
      if (metaDelAporte <= restante + 0.009) {
        await _movRepo.eliminar(ap.id!);
        restante -= metaDelAporte;
      } else {
        final nuevoMeta = metaDelAporte - restante;
        final ratio = nuevoMeta / metaDelAporte;
        await _movRepo.actualizar(Movimiento(
          id: ap.id,
          monto: ap.monto * ratio,
          fecha: ap.fecha,
          descripcion: ap.descripcion,
          tipo: 'ahorro',
          metaId: ap.metaId,
          montoMeta: nuevoMeta,
        ));
        restante = 0;
      }
    }
  }

  /// Agrega una submeta a una meta existente.
  Future<void> agregarSubmeta(Submeta submeta) async {
    await _submetaRepo.insertar(submeta);
    ref.invalidateSelf();
  }

  /// Actualiza una submeta existente.
  Future<void> actualizarSubmeta(Submeta submeta) async {
    await _submetaRepo.actualizar(submeta);
    ref.invalidateSelf();
  }

  /// Elimina una submeta.
  Future<void> eliminarSubmeta(int id) async {
    await _submetaRepo.eliminar(id);
    ref.invalidateSelf();
  }
}

/// Provider derivado que calcula el progreso total de todas las metas.
@riverpod
Map<String, double> progresoMetaTotal(ProgresoMetaTotalRef ref) {
  final metasAsync = ref.watch(metasControladorProvider);
  final datos = metasAsync.valueOrNull ?? {};
  // Cotización para convertir metas en USD a ARS (para sumar todo en pesos).
  final blue = ref.watch(dolarBlueProvider).valueOrNull?['venta'] ?? 0.0;

  double montoObjetivoTotal = 0;
  double montoActualTotal = 0;
  double montoActualProgreso = 0; // cada meta cuenta como máximo su objetivo

  for (final entry in datos.entries) {
    final meta = entry.key;
    final submetas = entry.value;
    final tasa = meta.esUsd ? blue : 1.0; // a ARS

    if (submetas.isEmpty) {
      // Si no tiene submetas, usamos la meta directamente
      montoObjetivoTotal += meta.montoObjetivo * tasa;
      montoActualTotal += meta.montoActual * tasa;
      montoActualProgreso += meta.montoActual.clamp(0.0, meta.montoObjetivo) * tasa;
    } else {
      // Si tiene submetas, sumamos las submetas (en la moneda de la meta)
      for (final sub in submetas) {
        montoObjetivoTotal += sub.montoObjetivo * tasa;
        montoActualTotal += sub.montoActual * tasa;
        montoActualProgreso += sub.montoActual.clamp(0.0, sub.montoObjetivo) * tasa;
      }
    }
  }

  double porcentaje = 0;
  if (montoObjetivoTotal > 0) {
    // El progreso total topa cada meta a su objetivo, así una meta sobrepasada
    // no tapa a otra incompleta (antes una al 121% hacía figurar el total 100%).
    porcentaje = (montoActualProgreso / montoObjetivoTotal * 100).clamp(0, 100);
  }

  return {
    'montoObjetivo': montoObjetivoTotal,
    'montoActual': montoActualTotal,
    'porcentaje': porcentaje,
    'cantidadMetas': datos.length.toDouble(),
  };
}
