import 'package:sqflite/sqflite.dart';

import '../base_de_datos/esquema.dart';
import '../dinero/dinero.dart';
import '../utilidades/fechas.dart';
import 'modelo/cuenta.dart';
import 'modelo/meta.dart';
import 'modelo/movimiento.dart';

/// Totales de un mes, siempre sobre todos sus movimientos (no una página).
class TotalesMes {
  const TotalesMes({
    this.ingresos = const Dinero.cero(),
    this.gastos = const Dinero.cero(),
    this.aportadoAMetas = const Dinero.cero(),
    this.cantidadIngresos = 0,
    this.cantidadGastos = 0,
  });

  final Dinero ingresos;
  final Dinero gastos;

  /// Lo que pasó de "Libre ARS" a metas menos lo que volvió (en pesos).
  final Dinero aportadoAMetas;
  final int cantidadIngresos;
  final int cantidadGastos;

  /// Ingresos menos gastos del mes.
  Dinero get resultado => ingresos - gastos;

  /// Porcentaje de los ingresos que no se gastó, truncado (0 si no hubo
  /// ingresos o se gastó todo).
  int get porcentajeAhorro => resultado.esPositivo ? resultado.porcentajeDe(ingresos) : 0;

  bool get vacio => cantidadIngresos == 0 && cantidadGastos == 0;
}

/// Filtro de la lista de movimientos.
enum FiltroMovimientos { todos, ingresos, gastos, metas }

/// Lecturas del libro. Todas reciben un [DatabaseExecutor] para poder usarse
/// dentro de una transacción.
class ConsultasLibro {
  ConsultasLibro(this._db);

  final DatabaseExecutor _db;

  static const String _selectMovimientos = '''
    SELECT m.*, c.moneda AS moneda, cd.moneda AS moneda_destino
    FROM movimientos m
    JOIN cuentas c ON c.id = m.cuenta_id
    LEFT JOIN cuentas cd ON cd.id = m.cuenta_destino_id
    LEFT JOIN categorias cat ON cat.id = m.categoria_id
  ''';

  Future<List<Cuenta>> cuentas() async {
    final filas = await _db.query('cuentas', orderBy: 'id');
    return filas.map(Cuenta.desdeFila).toList();
  }

  Future<Map<int, Dinero>> saldos() async {
    final filas = await _db.rawQuery('''
      SELECT s.cuenta_id, s.saldo_centavos, c.moneda
      FROM saldos_cuentas s JOIN cuentas c ON c.id = s.cuenta_id
    ''');
    return {
      for (final f in filas)
        f['cuenta_id'] as int: Dinero((f['saldo_centavos'] as num? ?? 0).toInt(), Moneda.desdeCodigo(f['moneda'] as String?)),
    };
  }

  /// La plata libre en pesos: el saldo de "Libre ARS".
  Future<Dinero> disponible() async {
    final filas = await _db.rawQuery(
      'SELECT saldo_centavos FROM saldos_cuentas WHERE cuenta_id = ?',
      [Esquema.cuentaLibreArs],
    );
    return Dinero((filas.first['saldo_centavos'] as num? ?? 0).toInt());
  }

  /// Ahorro previo de una cuenta libre (sus saldos iniciales).
  Future<Dinero> saldoInicial(int cuentaId, Moneda moneda) async {
    final filas = await _db.rawQuery(
      "SELECT COALESCE(SUM(monto_centavos), 0) AS total FROM movimientos WHERE cuenta_id = ? AND tipo = 'saldo_inicial'",
      [cuentaId],
    );
    return Dinero((filas.first['total'] as num).toInt(), moneda);
  }

  /// Metas vigentes con su saldo, de la más nueva a la más vieja.
  Future<List<Meta>> metas() async {
    final filas = await _db.rawQuery('''
      SELECT m.*, c.nombre, c.moneda, s.saldo_centavos
      FROM metas m
      JOIN cuentas c ON c.id = m.cuenta_id
      JOIN saldos_cuentas s ON s.cuenta_id = m.cuenta_id
      WHERE c.archivada = 0
      ORDER BY m.fecha_creacion DESC, m.id DESC
    ''');
    return filas.map(Meta.desdeFila).toList();
  }

  Future<TotalesMes> totalesMes(Periodo mes) async {
    final filas = await _db.rawQuery('''
      SELECT tipo, SUM(monto_centavos) AS total, COUNT(*) AS cantidad
      FROM movimientos
      WHERE fecha >= ? AND fecha < ? AND tipo IN ('ingreso', 'gasto')
      GROUP BY tipo
    ''', [mes.desde, mes.hasta]);
    var ingresos = 0, gastos = 0, cantIngresos = 0, cantGastos = 0;
    for (final f in filas) {
      final total = (f['total'] as num).toInt();
      final cantidad = (f['cantidad'] as num).toInt();
      if (f['tipo'] == 'ingreso') {
        ingresos = total;
        cantIngresos = cantidad;
      } else {
        gastos = total;
        cantGastos = cantidad;
      }
    }

    final metas = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN m.cuenta_id = ? AND cd.tipo = 'meta' THEN m.monto_centavos END), 0)
        - COALESCE(SUM(CASE WHEN m.cuenta_destino_id = ? AND c.tipo = 'meta'
                            THEN COALESCE(m.monto_destino_centavos, m.monto_centavos) END), 0) AS neto
      FROM movimientos m
      JOIN cuentas c ON c.id = m.cuenta_id
      LEFT JOIN cuentas cd ON cd.id = m.cuenta_destino_id
      WHERE m.tipo = 'transferencia' AND m.fecha >= ? AND m.fecha < ?
    ''', [Esquema.cuentaLibreArs, Esquema.cuentaLibreArs, mes.desde, mes.hasta]);

    return TotalesMes(
      ingresos: Dinero(ingresos),
      gastos: Dinero(gastos),
      aportadoAMetas: Dinero((metas.first['neto'] as num? ?? 0).toInt()),
      cantidadIngresos: cantIngresos,
      cantidadGastos: cantGastos,
    );
  }

  /// Total por categoría de un tipo en un mes ({categoriaId: total}).
  Future<Map<int, Dinero>> totalesPorCategoria(Periodo mes, TipoMovimiento tipo) async {
    final filas = await _db.rawQuery('''
      SELECT categoria_id, SUM(monto_centavos) AS total
      FROM movimientos
      WHERE tipo = ? AND fecha >= ? AND fecha < ?
      GROUP BY categoria_id
      ORDER BY total DESC
    ''', [tipo.valor, mes.desde, mes.hasta]);
    return {for (final f in filas) f['categoria_id'] as int: Dinero((f['total'] as num).toInt())};
  }

  /// Lo que quedó libre de un mes: entradas menos salidas de "Libre ARS"
  /// (sin contar el ahorro previo).
  Future<Dinero> sobranteDelMes(Periodo mes) async {
    final filas = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE
          WHEN tipo = 'ingreso' AND cuenta_id = ? THEN monto_centavos
          WHEN tipo = 'gasto' AND cuenta_id = ? THEN -monto_centavos
          WHEN tipo = 'transferencia' AND cuenta_id = ? THEN -monto_centavos
          WHEN tipo = 'transferencia' AND cuenta_destino_id = ? THEN COALESCE(monto_destino_centavos, monto_centavos)
        END), 0) AS neto
      FROM movimientos
      WHERE fecha >= ? AND fecha < ?
    ''', [
      Esquema.cuentaLibreArs,
      Esquema.cuentaLibreArs,
      Esquema.cuentaLibreArs,
      Esquema.cuentaLibreArs,
      mes.desde,
      mes.hasta,
    ]);
    return Dinero((filas.first['neto'] as num? ?? 0).toInt());
  }

  /// Movimientos del más nuevo al más viejo, filtrados y buscados en SQL (no
  /// sobre una página ya cargada).
  Future<List<Movimiento>> movimientos({
    Periodo? mes,
    FiltroMovimientos filtro = FiltroMovimientos.todos,
    String busqueda = '',
    int limite = 30,
    int desplazamiento = 0,
  }) async {
    final condiciones = <String>["m.tipo <> 'saldo_inicial'"];
    final argumentos = <Object?>[];
    if (mes != null) {
      condiciones.add('m.fecha >= ? AND m.fecha < ?');
      argumentos.addAll([mes.desde, mes.hasta]);
    }
    switch (filtro) {
      case FiltroMovimientos.todos:
        break;
      case FiltroMovimientos.ingresos:
        condiciones.add("m.tipo = 'ingreso'");
      case FiltroMovimientos.gastos:
        condiciones.add("m.tipo = 'gasto'");
      case FiltroMovimientos.metas:
        condiciones.add("m.tipo = 'transferencia'");
    }
    final texto = busqueda.trim().toLowerCase();
    if (texto.isNotEmpty) {
      final patron = '%${texto.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
      condiciones.add(r"(LOWER(COALESCE(m.descripcion, '')) LIKE ? ESCAPE '\' OR LOWER(COALESCE(cat.nombre, '')) LIKE ? ESCAPE '\')");
      argumentos.addAll([patron, patron]);
    }
    final filas = await _db.rawQuery(
      '$_selectMovimientos WHERE ${condiciones.join(' AND ')} '
      'ORDER BY m.fecha DESC, m.creado_en DESC, m.id DESC LIMIT ? OFFSET ?',
      [...argumentos, limite, desplazamiento],
    );
    return filas.map(Movimiento.desdeFila).toList();
  }
}
