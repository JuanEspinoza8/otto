import '../../categorias/modelo/categoria.dart';
import '../../movimientos/repositorio/movimiento_repositorio.dart';

/// Una línea del resumen (una categoría con su total).
class LineaResumen {
  final String nombre;
  final double monto;
  final String colorHex;
  final String icono;
  const LineaResumen({required this.nombre, required this.monto, required this.colorHex, required this.icono});
}

/// Datos del resumen de un mes: ingresos y egresos agrupados por categoría.
class ResumenMesData {
  final DateTime mes;
  final List<LineaResumen> ingresos;
  final List<LineaResumen> egresos;
  const ResumenMesData({required this.mes, required this.ingresos, required this.egresos});

  double get totalIngresos => ingresos.fold(0, (s, l) => s + l.monto);
  double get totalEgresos => egresos.fold(0, (s, l) => s + l.monto);
  double get sobrante => totalIngresos - totalEgresos;
  bool get vacio => ingresos.isEmpty && egresos.isEmpty;
}

/// Arma el resumen de un mes a partir de los movimientos agrupados.
class ServicioResumenMes {
  static Future<ResumenMesData> calcular(DateTime mes, List<Categoria> categorias) async {
    final repo = MovimientoRepositorio();
    final filas = await repo.obtenerAgrupadoPorCategoria(mes);

    final ingresos = <LineaResumen>[];
    final egresos = <LineaResumen>[];

    for (final f in filas) {
      final catId = f['categoria_id'] as int?;
      final tipo = f['tipo'] as String?;
      final total = ((f['total'] as num?)?.toDouble() ?? 0) / 100;
      if (total <= 0) continue;

      final coincide = categorias.where((c) => c.id == catId);
      final cat = coincide.isNotEmpty ? coincide.first : null;
      final linea = LineaResumen(
        nombre: cat?.nombre ?? 'Otros',
        monto: total,
        colorHex: cat?.colorHex ?? '0xFF9E9E9E',
        icono: cat?.icono ?? 'category',
      );
      if (tipo == 'ingreso') {
        ingresos.add(linea);
      } else if (tipo == 'gasto') {
        egresos.add(linea);
      }
    }

    ingresos.sort((a, b) => b.monto.compareTo(a.monto));
    egresos.sort((a, b) => b.monto.compareTo(a.monto));

    return ResumenMesData(mes: mes, ingresos: ingresos, egresos: egresos);
  }
}
