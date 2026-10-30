import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../modelo/cuota.dart';

/// Repositorio CRUD para la tabla `cuotas`.
class CuotaRepositorio {
  Future<Database> get _bd async => await GestorBaseDatos.instancia.obtenerBaseDatos();

  Future<int> insertar(Cuota cuota) async {
    final db = await _bd;
    return await db.insert('cuotas', cuota.toMap());
  }

  Future<List<Cuota>> obtenerTodas() async {
    final db = await _bd;
    final res = await db.query('cuotas', orderBy: 'id DESC');
    return res.map((m) => Cuota.fromMap(m)).toList();
  }

  Future<int> actualizar(Cuota cuota) async {
    final db = await _bd;
    return await db.update('cuotas', cuota.toMap(),
        where: 'id = ?', whereArgs: [cuota.id]);
  }

  Future<int> eliminar(int id) async {
    final db = await _bd;
    return await db.delete('cuotas', where: 'id = ?', whereArgs: [id]);
  }

  /// Registra el pago de una cuota: incrementa `cuotas_pagadas` y, si se
  /// alcanzó el total, marca la cuota como inactiva (deja de descontar).
  Future<void> registrarPago(Cuota cuota) async {
    final db = await _bd;
    final pagadas = cuota.cuotasPagadas + 1;
    final finalizada = pagadas >= cuota.totalCuotas;
    await db.update(
      'cuotas',
      {
        'cuotas_pagadas': pagadas,
        'activo': finalizada ? 0 : 1,
      },
      where: 'id = ?',
      whereArgs: [cuota.id],
    );
  }
}
