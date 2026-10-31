import 'package:finanzas/core/base_de_datos/gestor_base_datos.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'base_v8.dart';

/// Base vacía con el esquema actual, en memoria.
Future<Database> abrirBaseNueva() async {
  inicializarSqfliteFfi();
  return GestorBaseDatos.abrir(inMemoryDatabasePath, fabrica: databaseFactoryFfi);
}

/// Id de una categoría sembrada por nombre.
Future<int> idCategoria(Database db, String nombre) async {
  final filas = await db.query('categorias', where: 'nombre = ?', whereArgs: [nombre]);
  return filas.first['id'] as int;
}
