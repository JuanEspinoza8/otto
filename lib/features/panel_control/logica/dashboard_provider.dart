import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/consultas_libro.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/utilidades/fechas.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';
import '../../movimientos/logica/mes_seleccionado_provider.dart';
import 'servicio_resumen_mes.dart';

part 'dashboard_provider.g.dart';

/// Totales del mes seleccionado (sobre todos sus movimientos).
@riverpod
Future<TotalesMes> totalesMes(Ref ref) async {
  final mes = Periodo.de(ref.watch(mesSeleccionadoProvider));
  return (await consultasLibro(ref)).totalesMes(mes);
}

/// Gastos del mes seleccionado por categoría ({categoriaId: total}).
@riverpod
Future<Map<int, Dinero>> gastosPorCategoria(Ref ref) async {
  final mes = Periodo.de(ref.watch(mesSeleccionadoProvider));
  return (await consultasLibro(ref)).totalesPorCategoria(mes, TipoMovimiento.gasto);
}

/// Total de una categoría en el mes.
class TotalCategoria {
  const TotalCategoria({required this.categoria, required this.total});
  final Categoria categoria;
  final Dinero total;
}

/// Gastos del mes por categoría, de mayor a menor, con la categoría resuelta.
@riverpod
Future<List<TotalCategoria>> rankingGastos(Ref ref) async {
  final totales = await ref.watch(gastosPorCategoriaProvider.future);
  final categorias = await ref.watch(categoriasControladorProvider.future);
  final ranking = [
    for (final e in totales.entries)
      TotalCategoria(
        categoria: categorias.where((c) => c.id == e.key).firstOrNull ??
            const Categoria(nombre: 'Otros', tipo: 'gasto', colorHex: '0xFF9E9E9E', icono: 'category'),
        total: e.value,
      ),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return ranking;
}

/// Ingresos y egresos por categoría de un mes.
@riverpod
Future<ResumenMesData> resumenDeMes(Ref ref, Periodo mes) async {
  final categorias = await ref.watch(categoriasControladorProvider.future);
  return ServicioResumenMes.calcular(await consultasLibro(ref), mes, categorias);
}

/// El resumen del mes seleccionado.
@riverpod
Future<ResumenMesData> resumenDelMes(Ref ref) =>
    ref.watch(resumenDeMesProvider(Periodo.de(ref.watch(mesSeleccionadoProvider))).future);
