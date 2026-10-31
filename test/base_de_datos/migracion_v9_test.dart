import 'dart:io';

import 'package:otto/core/base_de_datos/esquema.dart';
import 'package:otto/core/base_de_datos/gestor_base_datos.dart';
import 'package:otto/core/base_de_datos/migracion_v9.dart';
import 'package:otto/core/utilidades/fechas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../soporte/base_v8.dart';

final _datos = DatosMigracion(
  salarioMensual: salarioV8,
  valorHoraExtra: valorHoraExtraV8,
  cotizacionUsd: 1000,
  ahora: DateTime(2026, 10, 30, 12),
);

Future<int> _entero(Database db, String sql, [List<Object?>? args]) async {
  final filas = await db.rawQuery(sql, args);
  return ((filas.first.values.first as num?) ?? 0).round();
}

Future<int> _saldo(Database db, int cuentaId) => _entero(
    db, 'SELECT saldo_centavos FROM saldos_cuentas WHERE cuenta_id = ?', [cuentaId]);

Future<int> _cuentaDeMeta(Database db, int metaId) =>
    _entero(db, 'SELECT cuenta_id FROM metas WHERE id = ?', [metaId]);

Future<int> _planId(Database db, String nombre) =>
    _entero(db, 'SELECT id FROM planes WHERE nombre = ?', [nombre]);

Future<Map<String, int?>> _aplicaciones(Database db, String plan) async {
  final filas = await db.rawQuery(
    'SELECT periodo, movimiento_id FROM plan_aplicaciones WHERE plan_id = ? ORDER BY periodo',
    [await _planId(db, plan)],
  );
  return {for (final f in filas) f['periodo'] as String: f['movimiento_id'] as int?};
}

/// Totales por mes de la base v8 (rangos de milisegundos en hora local),
/// calculados igual que la app v8.
Future<Map<String, int>> _totalesV8(Database v8, Periodo mes) async {
  final desde = mes.primerDia.millisecondsSinceEpoch;
  final hasta = mes.siguiente.primerDia.millisecondsSinceEpoch;
  final filas = await v8.rawQuery(
    'SELECT tipo, SUM(monto) AS total FROM movimientos WHERE fecha >= ? AND fecha < ? GROUP BY tipo',
    [desde, hasta],
  );
  return {for (final f in filas) f['tipo'] as String: (f['total'] as num).round()};
}

Future<Map<String, int>> _totalesV9(Database v9, Periodo mes) async {
  final filas = await v9.rawQuery(
    "SELECT tipo, SUM(monto_centavos) AS total FROM movimientos "
    "WHERE fecha >= ? AND fecha < ? AND tipo IN ('ingreso', 'gasto') GROUP BY tipo",
    [mes.desde, mes.hasta],
  );
  return {for (final f in filas) f['tipo'] as String: (f['total'] as num).round()};
}

void main() {
  late Directory directorio;
  late String ruta;

  setUpAll(inicializarSqfliteFfi);

  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('otto_migracion_');
    ruta = p.join(directorio.path, GestorBaseDatos.nombreArchivo);
    final v8 = await abrirBaseV8(ruta: ruta);
    await v8.close();
  });

  tearDown(() async {
    await directorio.delete(recursive: true);
  });

  Future<Database> migrar({
    DatosMigracion? datos,
    Future<void> Function(DatabaseExecutor db)? antesDeVerificar,
  }) =>
      GestorBaseDatos.abrir(
        ruta,
        fabrica: databaseFactoryFfi,
        datos: datos ?? _datos,
        antesDeVerificar: antesDeVerificar,
      );

  group('migración v8 → v9 con la base de prueba', () {
    late Database db;

    setUp(() async => db = await migrar());
    tearDown(() async => db.close());

    test('queda en la versión 9 y sin tablas v8', () async {
      expect(await db.getVersion(), Esquema.version);
      final tablas = await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
      final nombres = tablas.map((t) => t['name']).toSet();
      for (final vieja in ['ahorros_acumulados', 'gastos_fijos', 'cuotas', 'recurrencias_aplicadas', 'submetas', 'logs_errores']) {
        expect(nombres, isNot(contains(vieja)));
      }
      expect(nombres.where((n) => '$n'.endsWith('_v8')), isEmpty);
    });

    test('el disponible en pesos cierra con v8', () async {
      // 150.000 + 2.465.000 − 1.510.500,50 − 220.000 (metas en pesos)
      // − 300.000 (Viaje: 200.000 aportados + US$100 sin aporte a 1.000)
      expect(await _saldo(db, Esquema.cuentaLibreArs), 58449950);
      expect(await _saldo(db, Esquema.cuentaDolares), 50000);
    });

    test('el saldo de cada meta es el de v8', () async {
      expect(await _saldo(db, await _cuentaDeMeta(db, metaVacaciones)), 12000000);
      expect(await _saldo(db, await _cuentaDeMeta(db, metaViaje)), 30000);
      expect(await _saldo(db, await _cuentaDeMeta(db, metaFondo)), 10000000);
      expect(await _saldo(db, await _cuentaDeMeta(db, metaAuto)), 0);
    });

    test('las sumas de cada mes no cambian', () async {
      final v8 = await abrirBaseV8();
      addTearDown(v8.close);
      for (final mes in [const Periodo(2026, 8), const Periodo(2026, 9), const Periodo(2026, 10)]) {
        final antes = await _totalesV8(v8, mes)
          ..remove('ahorro');
        expect(await _totalesV9(db, mes), antes, reason: '$mes');
      }
    });

    test('las fechas pasan a fecha local, incluso cerca de medianoche', () async {
      final filas = await db.query('movimientos', columns: ['id', 'fecha'], where: 'id IN (6, 20)', orderBy: 'id');
      expect(filas.map((f) => f['fecha']), ['2026-08-31', '2026-10-31']);
    });

    test('los aportes pasan a transferencias desde Libre ARS', () async {
      final aporteUsd = (await db.query('movimientos', where: 'id = 5')).first;
      expect(aporteUsd['tipo'], 'transferencia');
      expect(aporteUsd['cuenta_id'], Esquema.cuentaLibreArs);
      expect(aporteUsd['cuenta_destino_id'], await _cuentaDeMeta(db, metaViaje));
      expect(aporteUsd['monto_centavos'], 20000000);
      expect(aporteUsd['monto_destino_centavos'], 20000);
      expect(await _entero(db, "SELECT COUNT(*) FROM movimientos WHERE origen = 'migracion'"), 4);
      expect(await _entero(db, 'SELECT COUNT(*) FROM movimientos'), 24);
    });

    test('cuotas pagadas y períodos de cada plan', () async {
      expect(await _aplicaciones(db, 'Heladera'), {'2026-08': null, '2026-09': 9, '2026-10': 17});
      expect(await _aplicaciones(db, 'Celular'), {'2026-10': 19, '2026-11': 19, '2026-12': 19});
      expect(await _aplicaciones(db, 'Notebook'), isEmpty);
      final primeros = await db.rawQuery('SELECT nombre, primer_periodo FROM planes ORDER BY id');
      expect({for (final f in primeros) f['nombre']: f['primer_periodo']}, {
        'Alquiler': '2026-09',
        'Netflix': '2026-09',
        'Gas': '2026-10',
        'Heladera': '2026-08',
        'Celular': '2026-10',
        'Notebook': '2026-10',
        'Sueldo': '2026-09',
      });
    });

    test('el pendiente duplicado queda una sola vez y un movimiento borrado no se pierde', () async {
      expect(await _aplicaciones(db, 'Alquiler'), {'2026-09': 8, '2026-10': 15});
      expect(await _aplicaciones(db, 'Netflix'), {'2026-09': 12, '2026-10': null});
      // El segundo alquiler sigue siendo un gasto (no se borra plata).
      expect(await _entero(db, 'SELECT COUNT(*) FROM movimientos WHERE id = 16'), 1);
    });

    test('el sueldo, los avisos y el valor de la hora extra', () async {
      final sueldo = (await db.query('planes', where: "tipo = 'sueldo'")).single;
      expect(sueldo['monto_centavos'], 85000000);
      expect(sueldo['activo'], 1);
      expect(sueldo['categoria_id'], idSueldo);
      final avisos = await db.query('avisos_mes', orderBy: 'clave');
      expect(avisos.map((a) => '${a['clave']} ${a['periodo']}'),
          ['horasextras 2026-10', 'resumen 2026-09', 'saldoanterior 2026-10']);
      final ajustes = await db.query('ajustes');
      expect({for (final a in ajustes) a['clave']: a['valor']}, {'valor_hora_extra': '500000'});
    });

    test('las categorías conservan ids y presupuesto', () async {
      final gimnasio = (await db.query('categorias', where: 'id = ?', whereArgs: [idGimnasio])).single;
      expect(gimnasio['presupuesto_limite'], 2000000);
      expect(await _entero(db, 'SELECT COUNT(*) FROM categorias'), 18);
    });
  });

  test('reabrir no repite la migración', () async {
    var db = await migrar();
    final antes = await _entero(db, 'SELECT COUNT(*) FROM movimientos');
    await db.close();
    db = await migrar();
    addTearDown(db.close);
    expect(await _entero(db, 'SELECT COUNT(*) FROM movimientos'), antes);
    expect(await _saldo(db, Esquema.cuentaLibreArs), 58449950);
  });

  test('guarda una copia del archivo v8 antes de migrar', () async {
    final db = await migrar();
    await db.close();
    final respaldo = p.join(directorio.path, GestorBaseDatos.nombreRespaldoV8);
    final copia = await databaseFactoryFfi.openDatabase(respaldo,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
    addTearDown(copia.close);
    expect(await copia.getVersion(), 8);
    expect(await _entero(copia, 'SELECT COUNT(*) FROM movimientos'), 20);
  });

  test('si la verificación falla, se revierte todo y la base queda en v8', () async {
    await expectLater(
      migrar(antesDeVerificar: (db) => db.delete('movimientos', where: 'id = 1')),
      throwsA(isA<ErrorMigracion>()),
    );
    final v8 = await databaseFactoryFfi.openDatabase(ruta, options: OpenDatabaseOptions(singleInstance: false));
    
    expect(await v8.getVersion(), 8);
    expect(await _entero(v8, 'SELECT COUNT(*) FROM movimientos'), 20);
    expect(await _entero(v8, 'SELECT monto_actual FROM metas WHERE id = ?', [metaVacaciones]), 12000000);
    expect(await _entero(v8, "SELECT COUNT(*) FROM sqlite_master WHERE name = 'cuentas'"), 0);

    // El cliente sigue usando v8 y carga un gasto; el próximo intento rehace la copia.
    await v8.insert('movimientos', {
      'id': 21, 'monto': 100000, 'fecha': DateTime(2026, 10, 30).millisecondsSinceEpoch,
      'tipo': 'gasto', 'categoria_id': idAlimentacion,
    });
    await v8.close();
    final db = await migrar();
    addTearDown(db.close);
    final copia = await databaseFactoryFfi.openDatabase(
        p.join(directorio.path, GestorBaseDatos.nombreRespaldoV8),
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
    addTearDown(copia.close);
    expect(await _entero(copia, 'SELECT COUNT(*) FROM movimientos'), 21);
  });

  test('un aporte en dólares menor a un centavo no traba la migración', () async {
    final v8 = await databaseFactoryFfi.openDatabase(ruta, options: OpenDatabaseOptions(singleInstance: false));
    // $5 a un blue de 1.400 son US$0,0036: v8 guardaba monto_meta = 0.
    await v8.insert('movimientos', {
      'id': 30, 'monto': 500, 'fecha': DateTime(2026, 10, 3).millisecondsSinceEpoch,
      'tipo': 'ahorro', 'meta_id': metaViaje, 'monto_meta': 0, 'descripcion': 'Ahorro: Viaje',
    });
    await v8.close();

    final db = await migrar();
    addTearDown(db.close);
    // v8 no restaba esos $5 del disponible ni los sumaba a la meta.
    expect(await _saldo(db, Esquema.cuentaLibreArs), 58449950);
    expect(await _saldo(db, await _cuentaDeMeta(db, metaViaje)), 30000);
    final descartados = (await db.query('ajustes', where: "clave = 'migracion_v9_descartados'")).single;
    expect(descartados['valor'], contains('aporte en dólares sin monto en dólares'));
  });

  test('si un período está repetido, gana el que todavía tiene su movimiento', () async {
    final v8 = await databaseFactoryFfi.openDatabase(ruta, options: OpenDatabaseOptions(singleInstance: false));
    // El usuario borró el primero de los dos alquileres de octubre.
    await v8.delete('movimientos', where: 'id = 15');
    await v8.close();

    final db = await migrar();
    addTearDown(db.close);
    expect(await _aplicaciones(db, 'Alquiler'), {'2026-09': 8, '2026-10': 16});
  });

  test('sin cotización, los dólares sin aporte de una meta entran como saldo inicial', () async {
    final v8 = await databaseFactoryFfi.openDatabase(ruta, options: OpenDatabaseOptions(singleInstance: false));
    await v8.insert('metas', {
      'id': 9,
      'nombre': 'Dólares guardados',
      'icono': 'savings',
      'monto_objetivo': 100000,
      'monto_actual': 5000,
      'moneda': 'USD',
      'fecha_creacion': DateTime(2026, 6, 1).millisecondsSinceEpoch,
    });
    await v8.close();

    final db = await migrar(
      datos: DatosMigracion(salarioMensual: salarioV8, ahora: DateTime(2026, 10, 30)),
    );
    addTearDown(db.close);
    final cuenta = await _cuentaDeMeta(db, 9);
    expect(await _saldo(db, cuenta), 5000);
    final ajuste = (await db.query('movimientos', where: 'cuenta_id = ?', whereArgs: [cuenta])).single;
    expect(ajuste['tipo'], 'saldo_inicial');
    // Viaje se valúa con el promedio de sus aportes (200.000 / US$200 = 1.000).
    expect(await _saldo(db, Esquema.cuentaLibreArs), 58449950);
  });
}
