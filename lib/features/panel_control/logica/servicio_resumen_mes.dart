import '../../../core/dinero/dinero.dart';
import '../../../core/libro/consultas_libro.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/utilidades/fechas.dart';
import '../../categorias/modelo/categoria.dart';

/// Una línea del resumen (una categoría con su total).
class LineaResumen {
  const LineaResumen({required this.nombre, required this.monto, required this.colorHex, required this.icono});
  final String nombre;
  final Dinero monto;
  final String colorHex;
  final String icono;
}

/// Ingresos y egresos de un mes agrupados por categoría.
class ResumenMesData {
  const ResumenMesData({required this.mes, required this.ingresos, required this.egresos});
  final Periodo mes;
  final List<LineaResumen> ingresos;
  final List<LineaResumen> egresos;

  Dinero get totalIngresos => ingresos.fold(const Dinero.cero(), (s, l) => s + l.monto);
  Dinero get totalEgresos => egresos.fold(const Dinero.cero(), (s, l) => s + l.monto);
  Dinero get sobrante => totalIngresos - totalEgresos;
  bool get vacio => ingresos.isEmpty && egresos.isEmpty;
}

/// Arma el resumen de un mes con los totales por categoría del libro.
class ServicioResumenMes {
  static Future<ResumenMesData> calcular(ConsultasLibro consultas, Periodo mes, List<Categoria> categorias) async {
    List<LineaResumen> lineas(Map<int, Dinero> totales) {
      final resultado = [
        for (final e in totales.entries)
          if (e.value.esPositivo) _linea(e.key, e.value, categorias),
      ];
      resultado.sort((a, b) => b.monto.compareTo(a.monto));
      return resultado;
    }

    return ResumenMesData(
      mes: mes,
      ingresos: lineas(await consultas.totalesPorCategoria(mes, TipoMovimiento.ingreso)),
      egresos: lineas(await consultas.totalesPorCategoria(mes, TipoMovimiento.gasto)),
    );
  }

  static LineaResumen _linea(int categoriaId, Dinero monto, List<Categoria> categorias) {
    final cat = categorias.where((c) => c.id == categoriaId).firstOrNull;
    return LineaResumen(
      nombre: cat?.nombre ?? 'Otros',
      monto: monto,
      colorHex: cat?.colorHex ?? '0xFF9E9E9E',
      icono: cat?.icono ?? 'category',
    );
  }
}
