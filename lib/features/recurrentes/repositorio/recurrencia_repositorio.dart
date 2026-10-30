import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';

/// Repositorio de control de recurrencias aplicadas por período (YYYY-MM),
/// para evitar descontar/cargar dos veces el mismo concepto en el mismo mes.
class RecurrenciaRepositorio {
  Future<Database> get _bd async => await GestorBaseDatos.instancia.obtenerBaseDatos();

  /// Devuelve el conjunto de claves "tipo:referenciaId" ya aplicadas en [periodo].
  Future<Set<String>> obtenerAplicadas(String periodo) async {
    final db = await _bd;
    final res = await db.query(
      'recurrencias_aplicadas',
      where: 'periodo = ?',
      whereArgs: [periodo],
    );
    return res
        .map((m) => '${m['tipo']}:${m['referencia_id']}')
        .toSet();
  }

  /// Devuelve el `movimiento_id` de un concepto aplicado en un período, o null.
  Future<int?> obtenerMovimientoId({
    required String tipo,
    required int referenciaId,
    required String periodo,
  }) async {
    final db = await _bd;
    final res = await db.query(
      'recurrencias_aplicadas',
      where: 'tipo = ? AND referencia_id = ? AND periodo = ?',
      whereArgs: [tipo, referenciaId, periodo],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['movimiento_id'] as int?;
  }

  /// Registra que un concepto recurrente fue aplicado en un período.
  Future<void> registrar({
    required String tipo,
    required int referenciaId,
    required String periodo,
    int? movimientoId,
  }) async {
    final db = await _bd;
    await db.insert('recurrencias_aplicadas', {
      'tipo': tipo,
      'referencia_id': referenciaId,
      'periodo': periodo,
      'movimiento_id': movimientoId,
    });
  }
}
