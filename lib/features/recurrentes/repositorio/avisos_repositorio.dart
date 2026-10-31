import 'package:sqflite/sqflite.dart';

import '../../../core/utilidades/fechas.dart';

/// Avisos de la UI que se resuelven una vez por mes (resumen del mes, horas
/// extra, sobrante del mes anterior).
class AvisosRepositorio {
  AvisosRepositorio(this._db);

  final DatabaseExecutor _db;

  static const String resumen = 'resumen';
  static const String horasExtras = 'horasextras';
  static const String saldoAnterior = 'saldoanterior';

  Future<bool> resuelto(String clave, Periodo periodo) async {
    final filas = await _db.query('avisos_mes',
        where: 'clave = ? AND periodo = ?', whereArgs: [clave, periodo.toString()], limit: 1);
    return filas.isNotEmpty;
  }

  Future<void> marcar(String clave, Periodo periodo) => _db.rawInsert(
        'INSERT OR IGNORE INTO avisos_mes (clave, periodo) VALUES (?, ?)',
        [clave, periodo.toString()],
      );
}
