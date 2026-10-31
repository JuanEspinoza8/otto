import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../utilidades/fechas.dart';
import 'esquema.dart';

/// Valores que en v8 viven fuera de la base (SharedPreferences) y que la
/// migración necesita.
class DatosMigracion {
  const DatosMigracion({
    this.salarioMensual = 0,
    this.valorHoraExtra = 0,
    this.cotizacionUsd,
    required this.ahora,
  });

  final double salarioMensual;
  final double valorHoraExtra;

  /// Última cotización del blue (pesos por dólar) que tenía la app. Se usa
  /// solo para valuar dólares de metas que no tienen aportes registrados.
  final double? cotizacionUsd;
  final DateTime ahora;
}

/// La migración no cerró: la transacción se revierte y la base queda en v8.
class ErrorMigracion implements Exception {
  ErrorMigracion(this.mensaje);
  final String mensaje;

  @override
  String toString() => 'ErrorMigracion: $mensaje';
}

/// Lo que hizo la migración (para los tests y para diagnosticar).
class ResumenMigracion {
  int movimientos = 0;
  int ajustesDeMetas = 0;
  int planes = 0;
  int aplicaciones = 0;
  final List<Map<String, Object?>> descartados = [];
}

/// Migra una base v8 al libro único v9 dentro de la transacción de apertura.
///
/// 1. Calcula con las tablas v8 los saldos que tienen que quedar.
/// 2. Renombra las tablas v8 a `*_v8` y crea el esquema v9.
/// 3. Pasa ingresos y gastos a "Libre ARS" (con su fecha local), cada aporte
///    a una transferencia hacia la cuenta de su meta, y el ahorro previo a
///    saldos iniciales. Si el saldo de una meta no coincide con sus aportes
///    (por ejemplo, aportes de antes de v8), agrega una transferencia de ajuste.
/// 4. Pasa fijos, cuotas y sueldo a `planes`, y las recurrencias aplicadas a
///    `plan_aplicaciones` y `avisos_mes`.
/// 5. Verifica saldos, totales y cuotas pagadas. Si algo no cierra lanza
///    [ErrorMigracion] y sqflite revierte todo.
class MigradorV9 {
  MigradorV9(this._db, this._datos, {this.antesDeVerificar});

  final DatabaseExecutor _db;
  final DatosMigracion _datos;

  /// Solo para tests: permite romper datos y comprobar que la verificación
  /// aborta la migración.
  final Future<void> Function(DatabaseExecutor db)? antesDeVerificar;
  final ResumenMigracion _resumen = ResumenMigracion();

  late final _EsperadoV8 _esperado;
  final Map<int, int> _cuentaDeMeta = {};
  final Set<int> _movimientosMigrados = {};

  static const _tablasV8 = [
    'categorias',
    'movimientos',
    'metas',
    'submetas',
    'ahorros_acumulados',
    'gastos_fijos',
    'cuotas',
    'recurrencias_aplicadas',
    'logs_errores',
  ];

  Future<ResumenMigracion> migrar() async {
    // Las claves foráneas se validan al final de la transacción: permite
    // recrear tablas padre sin violar las referencias en el medio.
    await _db.execute('PRAGMA defer_foreign_keys = ON');

    _esperado = await _calcularEsperado();

    for (final tabla in _tablasV8) {
      if (await _existeTabla(tabla)) {
        await _db.execute('ALTER TABLE $tabla RENAME TO ${tabla}_v8');
      }
    }
    await Esquema.crear(_db);
    await Esquema.sembrarCuentas(_db);

    await _copiarCategorias();
    await _crearMetas();
    await _copiarMovimientos();
    await _ajustarMetas();
    await _saldosIniciales();
    await _crearPlanes();
    await _copiarAvisos();
    await _copiarAjustes();

    await antesDeVerificar?.call(_db);
    await _verificar();

    for (final tabla in _tablasV8.reversed) {
      await _db.execute('DROP TABLE IF EXISTS ${tabla}_v8');
    }
    final violaciones = await _db.rawQuery('PRAGMA foreign_key_check');
    if (violaciones.isNotEmpty) {
      throw ErrorMigracion('Quedaron referencias rotas: $violaciones');
    }
    return _resumen;
  }

  // ---------------------------------------------------------------------------
  // Lectura de v8

  Future<bool> _existeTabla(String nombre) async {
    final filas = await _db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      [nombre],
    );
    return filas.isNotEmpty;
  }

  Future<_EsperadoV8> _calcularEsperado() async {
    final e = _EsperadoV8();

    final ahorros = await _db.query('ahorros_acumulados', where: 'id = 1');
    if (ahorros.isNotEmpty) {
      e.previoArs = _entero(ahorros.first['ahorro_previo_ars']);
      e.previoUsd = _entero(ahorros.first['ahorro_previo_usd']);
    }
    if (e.previoArs < 0 || e.previoUsd < 0) {
      throw ErrorMigracion('El ahorro previo es negativo');
    }

    final totales = await _db.rawQuery(
      "SELECT tipo, SUM(monto) AS total FROM movimientos WHERE tipo IN ('ingreso', 'gasto') GROUP BY tipo",
    );
    for (final fila in totales) {
      if (fila['tipo'] == 'ingreso') e.ingresos = _entero(fila['total']);
      if (fila['tipo'] == 'gasto') e.gastos = _entero(fila['total']);
    }

    final metas = await _db.query('metas', orderBy: 'id');
    for (final m in metas) {
      final id = m['id'] as int;
      final usd = m['moneda'] == 'USD';
      final submetas = await _db.query('submetas', where: 'meta_id = ?', whereArgs: [id]);
      // Igual que v8: si la meta tiene submetas, su progreso es la suma de ellas.
      final actual = submetas.isEmpty
          ? _entero(m['monto_actual'])
          : submetas.fold<int>(0, (s, sub) => s + _entero(sub['monto_actual']));
      final objetivo = _entero(m['monto_objetivo']) > 0 || submetas.isEmpty
          ? _entero(m['monto_objetivo'])
          : submetas.fold<int>(0, (s, sub) => s + _entero(sub['monto_objetivo']));

      final aportes = await _db.rawQuery(
        "SELECT SUM(monto) AS pesos, SUM(COALESCE(monto_meta, 0)) AS en_meta "
        "FROM movimientos WHERE tipo = 'ahorro' AND meta_id = ?",
        [id],
      );
      final pesos = _entero(aportes.first['pesos']);
      final enMoneda = usd ? _entero(aportes.first['en_meta']) : pesos;

      e.metas[id] = _MetaV8(
        id: id,
        nombre: m['nombre'] as String,
        icono: (m['icono'] as String?) ?? 'flag',
        usd: usd,
        objetivo: objetivo,
        actual: actual,
        fechaCreacion: _entero(m['fecha_creacion']),
        aportesPesos: pesos,
        aportesEnMoneda: enMoneda,
      );
    }
    return e;
  }

  // ---------------------------------------------------------------------------
  // Copia

  Future<void> _copiarCategorias() async {
    final filas = await _db.query('categorias_v8', orderBy: 'id');
    for (final c in filas) {
      var tipo = c['tipo'] as String?;
      if (tipo != 'ingreso' && tipo != 'gasto') {
        // v8 permitía tipo NULL: se deduce de sus movimientos.
        final uso = await _db.rawQuery(
          "SELECT tipo FROM movimientos_v8 WHERE categoria_id = ? AND tipo IN ('ingreso', 'gasto') LIMIT 1",
          [c['id']],
        );
        tipo = uso.isEmpty ? 'gasto' : uso.first['tipo'] as String;
      }
      await _db.insert('categorias', {
        'id': c['id'],
        'nombre': c['nombre'],
        'tipo': tipo,
        'color_hex': c['color_hex'],
        'icono': c['icono'],
        'presupuesto_limite': _entero(c['presupuesto_limite']).clamp(0, 1 << 62),
        'es_sistema': _entero(c['es_sistema']) == 1 ? 1 : 0,
      });
    }
  }

  Future<void> _crearMetas() async {
    for (final m in _esperado.metas.values) {
      final cuentaId = await _db.insert('cuentas', {
        'nombre': m.nombre,
        'moneda': m.usd ? 'USD' : 'ARS',
        'tipo': 'meta',
      });
      _cuentaDeMeta[m.id] = cuentaId;
      await _db.insert('metas', {
        'id': m.id,
        'cuenta_id': cuentaId,
        'icono': m.icono,
        'monto_objetivo': m.objetivo,
        'fecha_creacion': m.fechaCreacion,
      });
    }
  }

  Future<void> _copiarMovimientos() async {
    final planDeMovimiento = await _movimientosDePlanes();
    final filas = await _db.query('movimientos_v8', orderBy: 'id');

    for (final f in filas) {
      final id = f['id'] as int;
      final ms = _entero(f['fecha']);
      final base = <String, Object?>{
        'id': id,
        'fecha': fechaIso(DateTime.fromMillisecondsSinceEpoch(ms)),
        'creado_en': ms,
        'monto_centavos': _entero(f['monto']),
        'descripcion': f['descripcion'],
        'origen': planDeMovimiento.contains(id) ? 'plan' : 'manual',
      };

      switch (f['tipo']) {
        case 'ingreso':
        case 'gasto':
          final tipo = f['tipo'] as String;
          await _db.insert('movimientos', {
            ...base,
            'tipo': tipo,
            'cuenta_id': Esquema.cuentaLibreArs,
            'categoria_id': await _categoriaValida(f['categoria_id'] as int?, tipo),
          });
        case 'ahorro':
          final meta = _esperado.metas[f['meta_id']];
          if (meta == null) {
            // Aporte a una meta que ya no existe: v8 no lo contaba en ningún
            // saldo, así que no se convierte en transferencia.
            _resumen.descartados.add({...f, 'motivo': 'aporte sin meta'});
            continue;
          }
          int? destino;
          if (meta.usd) {
            destino = _entero(f['monto_meta']);
            if (destino <= 0) {
              final tasa = _tasaDe(meta);
              if (tasa == null) {
                throw ErrorMigracion('Aporte $id en dólares sin monto ni cotización');
              }
              destino = (_entero(f['monto']) / tasa).round();
            }
          }
          await _db.insert('movimientos', {
            ...base,
            'tipo': 'transferencia',
            'cuenta_id': Esquema.cuentaLibreArs,
            'cuenta_destino_id': _cuentaDeMeta[meta.id],
            'monto_destino_centavos': destino,
          });
        default:
          // v8 permitía tipo NULL; esas filas no sumaban en ningún total.
          _resumen.descartados.add({...f, 'motivo': 'tipo desconocido'});
          continue;
      }
      _movimientosMigrados.add(id);
      _resumen.movimientos++;
    }
  }

  /// Ids de movimientos generados por sueldo, fijos o cuotas.
  Future<Set<int>> _movimientosDePlanes() async {
    final filas = await _db.rawQuery(
      "SELECT DISTINCT movimiento_id FROM recurrencias_aplicadas_v8 "
      "WHERE tipo IN ('sueldo', 'fijo', 'cuota') AND movimiento_id IS NOT NULL",
    );
    return filas.map((f) => f['movimiento_id'] as int).toSet();
  }

  final Map<String, int> _categoriaOtros = {};

  /// La categoría del movimiento, o "Otros Gastos"/"Otros Ingresos" si no
  /// tiene (v9 exige categoría en ingresos y gastos).
  Future<int> _categoriaValida(int? id, String tipo) async {
    if (id != null) {
      final existe = await _db.query('categorias', where: 'id = ? AND tipo = ?', whereArgs: [id, tipo]);
      if (existe.isNotEmpty) return id;
    }
    final cache = _categoriaOtros[tipo];
    if (cache != null) return cache;
    final nombre = tipo == 'gasto' ? 'Otros Gastos' : 'Otros Ingresos';
    final filas = await _db.query('categorias', where: 'nombre = ? AND tipo = ?', whereArgs: [nombre, tipo]);
    final otros = filas.isNotEmpty
        ? filas.first['id'] as int
        : await _db.insert('categorias', {
            'nombre': nombre,
            'tipo': tipo,
            'color_hex': '0xFF9E9E9E',
            'icono': 'more_horiz',
            'es_sistema': 0,
          });
    return _categoriaOtros[tipo] = otros;
  }

  /// Cotización para valuar dólares de una meta sin aportes registrados: la
  /// última que tenía la app o, si no hay, el promedio de sus aportes.
  double? _tasaDe(_MetaV8 meta) {
    final cotizacion = _datos.cotizacionUsd;
    if (cotizacion != null && cotizacion > 0) return cotizacion;
    if (meta.aportesEnMoneda > 0) return meta.aportesPesos / meta.aportesEnMoneda;
    return null;
  }

  Future<void> _ajustarMetas() async {
    for (final meta in _esperado.metas.values) {
      final diferencia = meta.actual - meta.aportesEnMoneda;
      if (diferencia == 0) continue;
      final cuentaMeta = _cuentaDeMeta[meta.id]!;
      final fecha = fechaIso(DateTime.fromMillisecondsSinceEpoch(meta.fechaCreacion));
      final comun = {
        'fecha': fecha,
        'creado_en': _datos.ahora.millisecondsSinceEpoch,
        'origen': 'migracion',
      };

      if (!meta.usd) {
        await _db.insert('movimientos', {
          ...comun,
          'tipo': 'transferencia',
          'monto_centavos': diferencia.abs(),
          'cuenta_id': diferencia > 0 ? Esquema.cuentaLibreArs : cuentaMeta,
          'cuenta_destino_id': diferencia > 0 ? cuentaMeta : Esquema.cuentaLibreArs,
          'descripcion': 'Ajuste al migrar: ${meta.nombre}',
        });
      } else {
        final tasa = _tasaDe(meta);
        if (tasa == null) {
          if (diferencia < 0) {
            throw ErrorMigracion('No se puede valuar el ajuste de ${meta.nombre}');
          }
          // Sin ninguna cotización: los dólares entran como saldo inicial de la
          // meta y no se descuentan del disponible.
          await _db.insert('movimientos', {
            ...comun,
            'tipo': 'saldo_inicial',
            'monto_centavos': diferencia,
            'cuenta_id': cuentaMeta,
            'descripcion': 'Saldo al migrar: ${meta.nombre}',
          });
        } else {
          final pesos = (diferencia.abs() * tasa).round();
          meta.pesosAjuste = diferencia > 0 ? pesos : -pesos;
          await _db.insert('movimientos', {
            ...comun,
            'tipo': 'transferencia',
            'monto_centavos': diferencia > 0 ? pesos : diferencia.abs(),
            'cuenta_id': diferencia > 0 ? Esquema.cuentaLibreArs : cuentaMeta,
            'cuenta_destino_id': diferencia > 0 ? cuentaMeta : Esquema.cuentaLibreArs,
            'monto_destino_centavos': diferencia > 0 ? diferencia : pesos,
            'descripcion': 'Ajuste al migrar: ${meta.nombre}',
          });
        }
      }
      _resumen.ajustesDeMetas++;
    }
  }

  Future<void> _saldosIniciales() async {
    final primera = await _db.rawQuery('SELECT MIN(fecha) AS f FROM movimientos');
    final fecha = (primera.first['f'] as String?) ?? fechaIso(_datos.ahora);
    final comun = {
      'fecha': fecha,
      'creado_en': _datos.ahora.millisecondsSinceEpoch,
      'tipo': 'saldo_inicial',
      'origen': 'migracion',
      'descripcion': 'Ahorro previo',
    };
    if (_esperado.previoArs > 0) {
      await _db.insert('movimientos', {
        ...comun,
        'monto_centavos': _esperado.previoArs,
        'cuenta_id': Esquema.cuentaLibreArs,
      });
    }
    if (_esperado.previoUsd > 0) {
      await _db.insert('movimientos', {
        ...comun,
        'monto_centavos': _esperado.previoUsd,
        'cuenta_id': Esquema.cuentaDolares,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Planes

  Future<void> _crearPlanes() async {
    final actual = Periodo.de(_datos.ahora);
    final recurrencias = await _db.query('recurrencias_aplicadas_v8', orderBy: 'id');

    // Períodos aplicados por concepto ("fijo:3" → {2026-09: movId}). Si un
    // período está repetido (doble toque), queda el primero.
    final aplicadas = <String, Map<Periodo, int?>>{};
    for (final r in recurrencias) {
      final tipo = r['tipo'] as String;
      if (!const {'sueldo', 'fijo', 'cuota'}.contains(tipo)) continue;
      final periodo = Periodo.parsear(r['periodo'] as String);
      final porPeriodo = aplicadas.putIfAbsent('$tipo:${r['referencia_id']}', () => {});
      if (porPeriodo.containsKey(periodo)) continue;
      final mov = r['movimiento_id'] as int?;
      porPeriodo[periodo] = mov != null && _movimientosMigrados.contains(mov) ? mov : null;
    }

    Periodo primero(Map<Periodo, int?>? periodos) =>
        (periodos == null || periodos.isEmpty) ? actual : (periodos.keys.toList()..sort()).first;

    final fijos = await _db.query('gastos_fijos_v8', orderBy: 'id');
    for (final f in fijos) {
      final monto = _entero(f['monto']);
      if (monto <= 0) {
        _resumen.descartados.add({...f, 'motivo': 'fijo sin monto'});
        continue;
      }
      final periodos = aplicadas['fijo:${f['id']}'];
      _resumen.planes++;
      final planId = await _db.insert('planes', {
        'tipo': 'fijo',
        'nombre': f['nombre'],
        'categoria_id': await _categoriaDePlan(f['categoria_id'] as int?, 'gasto'),
        'monto_centavos': monto,
        'primer_periodo': primero(periodos).toString(),
        'dia_debito': _entero(f['dia_debito']).clamp(1, 28),
        'activo': _entero(f['activo']) == 1 ? 1 : 0,
      });
      await _aplicar(planId, periodos);
    }

    final cuotas = await _db.query('cuotas_v8', orderBy: 'id');
    for (final c in cuotas) {
      final monto = _entero(c['monto_cuota']);
      final total = _entero(c['total_cuotas']);
      if (monto <= 0 || total <= 0) {
        _resumen.descartados.add({...c, 'motivo': 'cuota sin monto o sin total'});
        continue;
      }
      final pagadas = _entero(c['cuotas_pagadas']).clamp(0, total);
      final periodos = await _periodosDeCuota(aplicadas['cuota:${c['id']}'] ?? {}, pagadas, actual);
      _resumen.planes++;
      final planId = await _db.insert('planes', {
        'tipo': 'cuotas',
        'nombre': c['nombre'],
        'categoria_id': await _categoriaDePlan(c['categoria_id'] as int?, 'gasto'),
        'monto_centavos': monto,
        'total_centavos': monto * total,
        'total_cuotas': total,
        'primer_periodo': primero(periodos).toString(),
        'dia_debito': _entero(c['dia_debito']).clamp(1, 28),
        // v8 desactivaba la cuota al terminarla; en v9 "terminada" sale de
        // contar las aplicaciones y "activo" queda para pausarla.
        'activo': (_entero(c['activo']) == 1 || pagadas >= total) ? 1 : 0,
      });
      await _aplicar(planId, periodos);
      _esperado.cuotasPagadas[planId] = pagadas;
    }

    final sueldos = aplicadas['sueldo:0'];
    final salario = (_datos.salarioMensual * 100).round();
    if (salario > 0 || (sueldos != null && sueldos.isNotEmpty)) {
      var monto = salario;
      if (monto <= 0) {
        final ultimo = await _db.rawQuery(
          'SELECT monto_centavos FROM movimientos WHERE id = ?',
          [sueldos!.values.whereType<int>().fold<int>(0, (a, b) => a > b ? a : b)],
        );
        monto = ultimo.isEmpty ? 0 : _entero(ultimo.first['monto_centavos']);
      }
      if (monto > 0) {
        _resumen.planes++;
      final planId = await _db.insert('planes', {
          'tipo': 'sueldo',
          'nombre': 'Sueldo',
          'categoria_id': await _categoriaSueldo(),
          'monto_centavos': monto,
          'primer_periodo': primero(sueldos).toString(),
          'dia_debito': 1,
          'activo': salario > 0 ? 1 : 0,
        });
        await _aplicar(planId, sueldos);
      }
    }
  }

  /// Ajusta los períodos aplicados de una cuota a lo que decía el contador
  /// `cuotas_pagadas` de v8: si hay menos aplicaciones, las cuotas pagadas
  /// antes de usar la app ocupan los meses previos (sin movimiento); si hay
  /// más, se conservan las más recientes.
  Future<Map<Periodo, int?>> _periodosDeCuota(Map<Periodo, int?> aplicadas, int pagadas, Periodo actual) async {
    final ordenados = aplicadas.keys.toList()..sort();
    final resultado = <Periodo, int?>{};
    if (ordenados.length >= pagadas) {
      for (final p in ordenados.sublist(ordenados.length - pagadas)) {
        resultado[p] = aplicadas[p];
      }
      return resultado;
    }
    resultado.addAll(aplicadas);
    var antes = ordenados.isEmpty ? actual : ordenados.first;
    for (var i = 0; i < pagadas - ordenados.length; i++) {
      antes = antes.anterior;
      resultado[antes] = null;
    }
    return resultado;
  }

  Future<void> _aplicar(int planId, Map<Periodo, int?>? periodos) async {
    if (periodos == null) return;
    for (final entrada in periodos.entries) {
      await _db.insert('plan_aplicaciones', {
        'plan_id': planId,
        'periodo': entrada.key.toString(),
        'movimiento_id': entrada.value,
      });
      _resumen.aplicaciones++;
    }
  }

  Future<int?> _categoriaDePlan(int? id, String tipo) async {
    if (id == null) return null;
    final existe = await _db.query('categorias', where: 'id = ? AND tipo = ?', whereArgs: [id, tipo]);
    return existe.isEmpty ? null : id;
  }

  Future<int> _categoriaSueldo() async {
    final filas = await _db.query('categorias',
        where: "tipo = 'ingreso' AND LOWER(nombre) = 'sueldo'", limit: 1);
    if (filas.isNotEmpty) return filas.first['id'] as int;
    return _categoriaValida(null, 'ingreso');
  }

  // ---------------------------------------------------------------------------
  // Avisos y ajustes

  Future<void> _copiarAvisos() async {
    final filas = await _db.query('recurrencias_aplicadas_v8',
        where: "tipo IN ('resumen', 'horasextras', 'saldoanterior')");
    for (final r in filas) {
      await _db.insert(
        'avisos_mes',
        {'clave': r['tipo'], 'periodo': r['periodo']},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    final otras = await _db.query('recurrencias_aplicadas_v8',
        where: "tipo NOT IN ('resumen', 'horasextras', 'saldoanterior', 'sueldo', 'fijo', 'cuota')");
    for (final r in otras) {
      _resumen.descartados.add({...r, 'motivo': 'recurrencia desconocida'});
    }
  }

  Future<void> _copiarAjustes() async {
    final valorHora = (_datos.valorHoraExtra * 100).round();
    if (valorHora > 0) {
      await _db.insert('ajustes', {'clave': 'valor_hora_extra', 'valor': '$valorHora'});
    }
    if (_resumen.descartados.isNotEmpty) {
      // Nada se pierde: lo que no tiene lugar en v9 queda guardado acá.
      await _db.insert('ajustes', {
        'clave': 'migracion_v9_descartados',
        'valor': jsonEncode(_resumen.descartados),
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Verificación

  Future<int> _saldo(int cuentaId) async {
    final filas = await _db.rawQuery(
      'SELECT saldo_centavos FROM saldos_cuentas WHERE cuenta_id = ?',
      [cuentaId],
    );
    return _entero(filas.first['saldo_centavos']);
  }

  Future<void> _verificar() async {
    final e = _esperado;
    final errores = <String>[];

    void comparar(String que, int obtenido, int esperado) {
      if (obtenido != esperado) errores.add('$que: $obtenido ≠ $esperado');
    }

    comparar('Libre ARS', await _saldo(Esquema.cuentaLibreArs), e.disponibleArs);
    comparar('Dólares', await _saldo(Esquema.cuentaDolares), e.previoUsd);
    for (final meta in e.metas.values) {
      comparar('Meta ${meta.nombre}', await _saldo(_cuentaDeMeta[meta.id]!), meta.actual);
    }

    final totales = await _db.rawQuery(
      "SELECT tipo, SUM(monto_centavos) AS total FROM movimientos "
      "WHERE tipo IN ('ingreso', 'gasto') GROUP BY tipo",
    );
    var ingresos = 0, gastos = 0;
    for (final f in totales) {
      if (f['tipo'] == 'ingreso') ingresos = _entero(f['total']);
      if (f['tipo'] == 'gasto') gastos = _entero(f['total']);
    }
    comparar('Ingresos', ingresos, e.ingresos);
    comparar('Gastos', gastos, e.gastos);

    for (final entrada in e.cuotasPagadas.entries) {
      final filas = await _db.rawQuery(
        'SELECT COUNT(*) AS n FROM plan_aplicaciones WHERE plan_id = ?',
        [entrada.key],
      );
      comparar('Cuotas pagadas del plan ${entrada.key}', _entero(filas.first['n']), entrada.value);
    }

    if (errores.isNotEmpty) {
      throw ErrorMigracion('Los saldos no cierran: ${errores.join('; ')}');
    }
  }

  static int _entero(Object? valor) => valor == null ? 0 : (valor as num).round();
}

class _MetaV8 {
  _MetaV8({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.usd,
    required this.objetivo,
    required this.actual,
    required this.fechaCreacion,
    required this.aportesPesos,
    required this.aportesEnMoneda,
  });

  final int id;
  final String nombre;
  final String icono;
  final bool usd;
  final int objetivo;

  /// Saldo de la meta en su moneda (centavos).
  final int actual;
  final int fechaCreacion;

  /// Lo que salió del disponible por aportes registrados (pesos).
  final int aportesPesos;

  /// Lo que esos aportes sumaron a la meta (en su moneda).
  final int aportesEnMoneda;

  /// Pesos de la transferencia de ajuste de una meta en USD (con signo).
  int pesosAjuste = 0;
}

class _EsperadoV8 {
  int previoArs = 0;
  int previoUsd = 0;
  int ingresos = 0;
  int gastos = 0;
  final Map<int, _MetaV8> metas = {};
  final Map<int, int> cuotasPagadas = {};

  /// Pesos libres que tienen que quedar en "Libre ARS": el ahorro previo en
  /// pesos más ingresos menos gastos, menos lo que está en metas en pesos y
  /// lo que costaron (en pesos) las metas en dólares.
  int get disponibleArs {
    var total = previoArs + ingresos - gastos;
    for (final m in metas.values) {
      total -= m.usd ? m.aportesPesos + m.pesosAjuste : m.actual;
    }
    return total;
  }
}
