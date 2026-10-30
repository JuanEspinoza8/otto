import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../modelo/gasto_fijo.dart';

/// Repositorio CRUD para la tabla `gastos_fijos`.
class GastoFijoRepositorio {
  Future<Database> get _bd async => await GestorBaseDatos.instancia.obtenerBaseDatos();

  Future<int> insertar(GastoFijo gasto) async {
    final db = await _bd;
    return await db.insert('gastos_fijos', gasto.toMap());
  }

  Future<List<GastoFijo>> obtenerTodos() async {
    final db = await _bd;
    final res = await db.query('gastos_fijos', orderBy: 'id DESC');
    return res.map((m) => GastoFijo.fromMap(m)).toList();
  }

  Future<int> actualizar(GastoFijo gasto) async {
    final db = await _bd;
    return await db.update('gastos_fijos', gasto.toMap(),
        where: 'id = ?', whereArgs: [gasto.id]);
  }

  Future<int> eliminar(int id) async {
    final db = await _bd;
    return await db.delete('gastos_fijos', where: 'id = ?', whereArgs: [id]);
  }
}
