import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../movimientos/logica/mes_seleccionado_provider.dart';
import '../../movimientos/repositorio/movimiento_repositorio.dart';
import '../../categorias/logica/categorias_provider.dart';

part 'dashboard_provider.g.dart';

/// Resumen de ingresos/gastos/ahorro del mes seleccionado.
///
/// IMPORTANTE: calcula sobre TODOS los movimientos del mes consultando la base
/// (no la lista paginada de 30), para evitar totales incorrectos. Observa el
/// controlador de movimientos sólo como disparador de recálculo.
@riverpod
class ResumenMensual extends _$ResumenMensual {
  final MovimientoRepositorio _repo = MovimientoRepositorio();

  @override
  FutureOr<Map<String, double>> build() async {
    // Disparador: cualquier cambio en movimientos recalcula.
    ref.watch(movimientosControladorProvider);
    final mes = ref.watch(mesSeleccionadoProvider);

    final tot = await _repo.obtenerTotalesMes(mes);
    final ingresos = tot['ingresos'] ?? 0;
    final gastos = tot['gastos'] ?? 0;
    final ahorro = ingresos - gastos;
    final porcentajeAhorro = ingresos > 0 ? (ahorro / ingresos) * 100 : 0.0;

    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'ahorro': ahorro > 0 ? ahorro : 0,
      'aportadoMetas': tot['ahorros'] ?? 0,
      'porcentajeAhorro': porcentajeAhorro > 0 ? porcentajeAhorro : 0,
      'cantidadIngresos': tot['cantIngresos'] ?? 0,
      'cantidadGastos': tot['cantGastos'] ?? 0,
    };
  }
}

/// Totales de TODO el histórico (no de un mes): {ingresos, gastos, ahorros}.
/// Es la base para calcular la plata realmente disponible (saldo corrido).
@riverpod
class TotalesGlobales extends _$TotalesGlobales {
  final MovimientoRepositorio _repo = MovimientoRepositorio();

  @override
  FutureOr<Map<String, double>> build() async {
    ref.watch(movimientosControladorProvider); // disparador de recálculo
    return await _repo.obtenerTotalesGlobales();
  }
}

/// Gastos del mes agrupados por categoría (clave "nombre|colorHex" → total).
/// También sobre todos los movimientos del mes (no la lista paginada).
@riverpod
class GastosPorCategoria extends _$GastosPorCategoria {
  final MovimientoRepositorio _repo = MovimientoRepositorio();

  @override
  FutureOr<Map<String, double>> build() async {
    ref.watch(movimientosControladorProvider); // disparador
    final mes = ref.watch(mesSeleccionadoProvider);
    final categorias = ref.watch(categoriasControladorProvider).valueOrNull ?? [];

    final filas = await _repo.obtenerAgrupadoPorCategoria(mes);
    final Map<String, double> agrupado = {};

    for (final f in filas) {
      if (f['tipo'] != 'gasto') continue;
      final total = ((f['total'] as num?)?.toDouble() ?? 0) / 100;
      if (total <= 0) continue;
      final catId = f['categoria_id'] as int?;
      final coincide = categorias.where((c) => c.id == catId);
      final nombre = coincide.isNotEmpty ? coincide.first.nombre : 'Otros';
      final colorHex = coincide.isNotEmpty ? coincide.first.colorHex : '0xFF9E9E9E';
      agrupado['$nombre|$colorHex'] = total;
    }
    return agrupado;
  }
}

/// Gastos del mes por categoria_id (para los presupuestos). Sobre TODOS los
/// movimientos del mes (no la lista paginada de 30).
@riverpod
class GastoPorCategoriaId extends _$GastoPorCategoriaId {
  final MovimientoRepositorio _repo = MovimientoRepositorio();

  @override
  FutureOr<Map<int, double>> build() async {
    ref.watch(movimientosControladorProvider);
    final mes = ref.watch(mesSeleccionadoProvider);
    final filas = await _repo.obtenerAgrupadoPorCategoria(mes);
    final Map<int, double> res = {};
    for (final f in filas) {
      if (f['tipo'] != 'gasto') continue;
      final catId = f['categoria_id'] as int?;
      if (catId == null) continue;
      res[catId] = ((f['total'] as num?)?.toDouble() ?? 0) / 100;
    }
    return res;
  }
}
