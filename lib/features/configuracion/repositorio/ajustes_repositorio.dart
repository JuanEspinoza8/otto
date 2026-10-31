import 'package:sqflite/sqflite.dart';

import '../../../core/dinero/dinero.dart';

/// Ajustes que viven en la base para viajar en el respaldo.
class AjustesRepositorio {
  AjustesRepositorio(this._db);

  final DatabaseExecutor _db;

  static const String _valorHoraExtra = 'valor_hora_extra';

  Future<String?> leer(String clave) async {
    final filas = await _db.query('ajustes', where: 'clave = ?', whereArgs: [clave], limit: 1);
    return filas.isEmpty ? null : filas.first['valor'] as String;
  }

  Future<void> guardar(String clave, String valor) => _db.insert(
        'ajustes',
        {'clave': clave, 'valor': valor},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<Dinero> valorHoraExtra() async => Dinero(int.tryParse(await leer(_valorHoraExtra) ?? '') ?? 0);

  Future<void> fijarValorHoraExtra(Dinero valor) => guardar(_valorHoraExtra, '${valor.centavos}');
}
