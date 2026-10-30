import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../modelo/categoria.dart';

class CategoriaRepositorio {
  Future<Database> get _bd async => await GestorBaseDatos.instancia.obtenerBaseDatos();

  Future<int> insertar(Categoria categoria) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.insert('categorias', categoria.toMap());
    } catch (error) {
      rethrow;
    }
  }

  Future<List<Categoria>> obtenerTodas() async {
    try {
      final baseDatos = await _bd;
      final resultado = await baseDatos.query('categorias', orderBy: 'nombre ASC');
      return resultado.map((mapa) => Categoria.fromMap(mapa)).toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<int> actualizar(Categoria categoria) async {
    try {
      final baseDatos = await _bd;
      return await baseDatos.update(
        'categorias',
        categoria.toMap(),
        where: 'id = ?',
        whereArgs: [categoria.id],
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<int> eliminar(int id) async {
    try {
      final baseDatos = await _bd;
      // Seguridad adicional: se evita eliminar categorías del sistema desde SQL
      return await baseDatos.delete(
        'categorias',
        where: 'id = ? AND es_sistema = 0',
        whereArgs: [id],
      );
    } catch (error) {
      rethrow;
    }
  }
}
