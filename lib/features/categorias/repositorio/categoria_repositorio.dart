import 'package:sqflite/sqflite.dart';

import '../../../core/libro/servicio_libro.dart';
import '../modelo/categoria.dart';

class CategoriaRepositorio {
  CategoriaRepositorio(this._db);

  final DatabaseExecutor _db;

  Future<List<Categoria>> todas() async {
    final filas = await _db.query('categorias', orderBy: 'nombre COLLATE NOCASE ASC');
    return filas.map(Categoria.desdeFila).toList();
  }

  Future<int> insertar(Categoria categoria) async {
    _validar(categoria);
    return _db.insert('categorias', categoria.aFila()..remove('id'));
  }

  /// No deja cambiar el tipo de una categoría que ya tiene movimientos o
  /// planes: esos ingresos pasarían a contarse como gastos (o al revés).
  Future<void> actualizar(Categoria categoria) async {
    _validar(categoria);
    final actual = await _db.query('categorias', columns: ['tipo'], where: 'id = ?', whereArgs: [categoria.id]);
    if (actual.isEmpty) throw const ErrorLibro('La categoría ya no existe');
    if (actual.first['tipo'] != categoria.tipo && (await usos(categoria.id!)) > 0) {
      throw const ErrorLibro('No se puede cambiar el tipo de una categoría con movimientos');
    }
    await _db.update('categorias', categoria.aFila(), where: 'id = ?', whereArgs: [categoria.id]);
  }

  /// Movimientos y planes que usan la categoría.
  Future<int> usos(int id) async {
    final filas = await _db.rawQuery('''
      SELECT (SELECT COUNT(*) FROM movimientos WHERE categoria_id = ?)
           + (SELECT COUNT(*) FROM planes WHERE categoria_id = ?) AS n
    ''', [id, id]);
    return filas.first['n'] as int;
  }

  /// Borra una categoría. Si tiene movimientos o planes, pasan a
  /// [reasignarA] (que tiene que ser otra categoría del mismo tipo).
  Future<void> eliminar(int id, {int? reasignarA}) async {
    final origen = await _db.query('categorias', where: 'id = ?', whereArgs: [id]);
    if (origen.isEmpty) return;
    if (origen.first['es_sistema'] == 1) throw const ErrorLibro('Las categorías del sistema no se borran');

    if (await usos(id) > 0) {
      if (reasignarA == null || reasignarA == id) throw const ErrorLibro('Elegí a qué categoría pasar los movimientos');
      final destino = await _db.query('categorias', columns: ['tipo'], where: 'id = ?', whereArgs: [reasignarA]);
      if (destino.isEmpty || destino.first['tipo'] != origen.first['tipo']) {
        throw const ErrorLibro('La categoría destino tiene que ser del mismo tipo');
      }
      await _db.update('movimientos', {'categoria_id': reasignarA}, where: 'categoria_id = ?', whereArgs: [id]);
      await _db.update('planes', {'categoria_id': reasignarA}, where: 'categoria_id = ?', whereArgs: [id]);
    }
    await _db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  void _validar(Categoria c) {
    if (c.nombre.trim().isEmpty) throw const ErrorLibro('Ingresá un nombre');
    if (c.tipo != 'ingreso' && c.tipo != 'gasto') throw const ErrorLibro('Tipo de categoría inválido');
    if (c.presupuestoLimite.esNegativo) throw const ErrorLibro('El presupuesto no puede ser negativo');
  }
}
