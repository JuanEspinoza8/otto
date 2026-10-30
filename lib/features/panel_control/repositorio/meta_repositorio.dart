import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../modelo/meta.dart';
import '../modelo/submeta.dart';

/// Repositorio para operaciones CRUD sobre la tabla `metas`.
class MetaRepositorio {
  Future<Database> get _bd async => await GestorBaseDatos.instancia.obtenerBaseDatos();

  /// Inserta una nueva meta y retorna su ID generado.
  Future<int> insertar(Meta meta) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.insert('metas', meta.toMap());
    } catch (error) {
      rethrow;
    }
  }

  /// Obtiene todas las metas ordenadas por fecha de creación.
  Future<List<Meta>> obtenerTodas() async {
    try {
      final baseDatos = await _bd;
      final resultado = await baseDatos.query('metas', orderBy: 'fecha_creacion DESC');
      return resultado.map((mapa) => Meta.fromMap(mapa)).toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Obtiene una meta por su ID.
  Future<Meta?> obtenerPorId(int id) async {
    try {
      final baseDatos = await _bd;
      final resultado = await baseDatos.query('metas', where: 'id = ?', whereArgs: [id]);
      if (resultado.isEmpty) return null;
      return Meta.fromMap(resultado.first);
    } catch (error) {
      rethrow;
    }
  }

  /// Obtiene todas las submetas de una meta específica.
  Future<List<Submeta>> obtenerSubmetasDeMeta(int metaId) async {
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

  /// Obtiene todas las metas con sus submetas como un mapa.
  Future<Map<Meta, List<Submeta>>> obtenerConSubmetas() async {
    try {
      final metas = await obtenerTodas();
      final Map<Meta, List<Submeta>> resultado = {};

      for (final meta in metas) {
        final submetas = await obtenerSubmetasDeMeta(meta.id!);
        resultado[meta] = submetas;
      }

      return resultado;
    } catch (error) {
      rethrow;
    }
  }

  /// Actualiza una meta existente.
  Future<int> actualizar(Meta meta) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.update(
        'metas',
        meta.toMap(),
        where: 'id = ?',
        whereArgs: [meta.id],
      );
    } catch (error) {
      rethrow;
    }
  }

  /// Elimina una meta por su ID (las submetas se eliminan en cascada).
  Future<int> eliminar(int id) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.delete('metas', where: 'id = ?', whereArgs: [id]);
    } catch (error) {
      rethrow;
    }
  }
}
