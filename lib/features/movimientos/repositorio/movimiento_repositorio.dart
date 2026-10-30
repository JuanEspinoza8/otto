import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../modelo/movimiento.dart';

class MovimientoRepositorio {
  Future<Database> get _bd async => await GestorBaseDatos.instancia.obtenerBaseDatos();

  Future<int> insertar(Movimiento movimiento) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.insert('movimientos', movimiento.toMap());
    } catch (error) {
      rethrow;
    }
  }

  /// Recupera un lote de movimientos aplicando la paginación obligatoria (LIMIT y OFFSET) y un filtro opcional de mes
  Future<List<Movimiento>> obtenerPaginados({required int limite, required int desplazamiento, DateTime? mes}) async {
    try {
      final baseDatos = await _bd;
      String? where;
      List<dynamic>? whereArgs;

      if (mes != null) {
        final inicioMes = DateTime(mes.year, mes.month, 1);
        final finMes = DateTime(mes.year, mes.month + 1, 1).subtract(const Duration(milliseconds: 1));
        where = 'fecha >= ? AND fecha <= ?';
        whereArgs = [inicioMes.millisecondsSinceEpoch, finMes.millisecondsSinceEpoch];
      }

      final resultado = await baseDatos.query(
        'movimientos',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'fecha DESC',
        limit: limite,
        offset: desplazamiento,
      );
      return resultado.map((mapa) => Movimiento.fromMap(mapa)).toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Devuelve filas {categoria_id, tipo, total} agrupadas por categoría y tipo
  /// para un mes. `total` viene en centavos (se divide por 100 arriba).
  Future<List<Map<String, dynamic>>> obtenerAgrupadoPorCategoria(DateTime mes) async {
    try {
      final baseDatos = await _bd;
      final inicio = DateTime(mes.year, mes.month, 1).millisecondsSinceEpoch;
      final fin = DateTime(mes.year, mes.month + 1, 1).subtract(const Duration(milliseconds: 1)).millisecondsSinceEpoch;
      return await baseDatos.rawQuery(
        "SELECT categoria_id, tipo, SUM(monto) as total FROM movimientos WHERE fecha >= ? AND fecha <= ? GROUP BY categoria_id, tipo ORDER BY total DESC",
        [inicio, fin],
      );
    } catch (error) {
      rethrow;
    }
  }

  /// Devuelve totales y cantidades de un mes: {ingresos, gastos, ahorros,
  /// cantIngresos, cantGastos, cantAhorros}. Calcula sobre TODOS los
  /// movimientos del mes (no la lista paginada), en pesos reales. `ahorros` es
  /// la plata aportada a metas ese mes (movimientos de tipo 'ahorro').
  Future<Map<String, double>> obtenerTotalesMes(DateTime mes) async {
    try {
      final baseDatos = await _bd;
      final inicio = DateTime(mes.year, mes.month, 1).millisecondsSinceEpoch;
      final fin = DateTime(mes.year, mes.month + 1, 1).subtract(const Duration(milliseconds: 1)).millisecondsSinceEpoch;
      final res = await baseDatos.rawQuery(
        "SELECT tipo, SUM(monto) as total, COUNT(*) as cant FROM movimientos WHERE fecha >= ? AND fecha <= ? GROUP BY tipo",
        [inicio, fin],
      );
      return _mapearTotales(res);
    } catch (error) {
      rethrow;
    }
  }

  /// Igual que [obtenerTotalesMes] pero sobre TODO el histórico (sin filtro de
  /// mes). Sirve para calcular la plata realmente disponible (saldo corrido).
  Future<Map<String, double>> obtenerTotalesGlobales() async {
    try {
      final baseDatos = await _bd;
      final res = await baseDatos.rawQuery(
        "SELECT tipo, SUM(monto) as total, COUNT(*) as cant FROM movimientos GROUP BY tipo",
      );
      return _mapearTotales(res);
    } catch (error) {
      rethrow;
    }
  }

  Map<String, double> _mapearTotales(List<Map<String, dynamic>> res) {
    double ingresos = 0, gastos = 0, ahorros = 0;
    double cantIngresos = 0, cantGastos = 0, cantAhorros = 0;
    for (final fila in res) {
      final total = ((fila['total'] as num?)?.toDouble() ?? 0) / 100;
      final cant = ((fila['cant'] as num?)?.toDouble() ?? 0);
      switch (fila['tipo']) {
        case 'ingreso':
          ingresos = total;
          cantIngresos = cant;
          break;
        case 'gasto':
          gastos = total;
          cantGastos = cant;
          break;
        case 'ahorro':
          ahorros = total;
          cantAhorros = cant;
          break;
      }
    }
    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'ahorros': ahorros,
      'cantIngresos': cantIngresos,
      'cantGastos': cantGastos,
      'cantAhorros': cantAhorros,
    };
  }

  /// Devuelve los aportes de ahorro de una meta, del más reciente al más viejo.
  Future<List<Movimiento>> obtenerAhorrosDeMeta(int metaId) async {
    try {
      final baseDatos = await _bd;
      final res = await baseDatos.query(
        'movimientos',
        where: "meta_id = ? AND tipo = 'ahorro'",
        whereArgs: [metaId],
        orderBy: 'fecha DESC, id DESC',
      );
      return res.map((mapa) => Movimiento.fromMap(mapa)).toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Borra todos los movimientos de ahorro asociados a una meta (se usa al
  /// eliminar la meta, para que su plata vuelva al disponible).
  Future<int> eliminarPorMeta(int metaId) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.delete('movimientos', where: 'meta_id = ?', whereArgs: [metaId]);
    } catch (error) {
      rethrow;
    }
  }

  Future<int> actualizar(Movimiento movimiento) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.update(
        'movimientos',
        movimiento.toMap(),
        where: 'id = ?',
        whereArgs: [movimiento.id],
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<int> eliminar(int id) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.delete(
        'movimientos',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (error) {
      rethrow;
    }
  }
}
