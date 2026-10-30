import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../modelo/submeta.dart';

/// Repositorio para operaciones CRUD sobre la tabla `submetas`.
class SubmetaRepositorio {
  Future<Database> get _bd async => await GestorBaseDatos.instancia.obtenerBaseDatos();

  /// Inserta una nueva submeta y retorna su ID generado.
  Future<int> insertar(Submeta submeta) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.insert('submetas', submeta.toMap());
    } catch (error) {
      rethrow;
    }
  }

  /// Obtiene todas las submetas de una meta.
  Future<List<Submeta>> obtenerPorMeta(int metaId) async {
    try {
      final baseDatos = await _bd;
      final resultado = await baseDatos.query(
        'submetas',
        where: 'meta_id = ?',
        whereArgs: [metaId],
        orderBy: 'id ASC',
      );
      return resultado.map((mapa) => Submeta.fromMap(mapa)).toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Actualiza una submeta existente.
  Future<int> actualizar(Submeta submeta) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.update(
        'submetas',
        submeta.toMap(),
        where: 'id = ?',
        whereArgs: [submeta.id],
      );
    } catch (error) {
      rethrow;
    }
  }

  /// Elimina una submeta por su ID.
  Future<int> eliminar(int id) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.delete('submetas', where: 'id = ?', whereArgs: [id]);
    } catch (error) {
      rethrow;
    }
  }
}
