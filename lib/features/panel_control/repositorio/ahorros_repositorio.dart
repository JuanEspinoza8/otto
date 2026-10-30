import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../modelo/ahorros_acumulados.dart';

/// Repositorio para la fila única de ahorros acumulados.
class AhorrosRepositorio {
  Future<Database> get _bd async => await GestorBaseDatos.instancia.obtenerBaseDatos();

  /// Obtiene la fila única de ahorros acumulados.
  Future<AhorrosAcumulados> obtener() async {
    try {
      final baseDatos = await _bd;
      final resultado = await baseDatos.query('ahorros_acumulados', where: 'id = 1');
      if (resultado.isEmpty) {
        return AhorrosAcumulados();
      }
      return AhorrosAcumulados.fromMap(resultado.first);
    } catch (error) {
      rethrow;
    }
  }

  /// Actualiza el ahorro previo en ARS.
  Future<void> actualizarArs(double valor) async {
    try {
      final baseDatos = await _bd;
      // Upsert: aseguramos que la fila única exista antes de actualizar, para
      // no perder el valor en silencio si no estaba (p. ej. tras un import).
      await baseDatos.insert(
        'ahorros_acumulados',
        {'id': 1, 'ahorro_previo_ars': 0, 'ahorro_previo_usd': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await baseDatos.update(
        'ahorros_acumulados',
        {'ahorro_previo_ars': (valor * 100).round()},
        where: 'id = 1',
      );
    } catch (error) {
      rethrow;
    }
  }

  /// Actualiza el ahorro previo en USD.
  Future<void> actualizarUsd(double valor) async {
    try {
      final baseDatos = await _bd;
      await baseDatos.insert(
        'ahorros_acumulados',
        {'id': 1, 'ahorro_previo_ars': 0, 'ahorro_previo_usd': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await baseDatos.update(
        'ahorros_acumulados',
        {'ahorro_previo_usd': (valor * 100).round()},
        where: 'id = 1',
      );
    } catch (error) {
      rethrow;
    }
  }
}
