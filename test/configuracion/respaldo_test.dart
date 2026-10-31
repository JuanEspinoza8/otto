import 'dart:convert';
import 'dart:io';

import 'package:finanzas/core/base_de_datos/esquema.dart';
import 'package:finanzas/core/base_de_datos/esquema_v8.dart';
import 'package:finanzas/core/base_de_datos/gestor_base_datos.dart';
import 'package:finanzas/core/base_de_datos/migracion_v9.dart';
import 'package:finanzas/core/libro/consultas_libro.dart';
import 'package:finanzas/features/configuracion/logica/servicio_respaldo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../soporte/base_v8.dart';
import '../soporte/base_v9.dart';

void main() {
  late Directory directorio;
  late Database origen;

  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('otto_respaldo_');
    final ruta = p.join(directorio.path, GestorBaseDatos.nombreArchivo);
    await (await abrirBaseV8(ruta: ruta)).close();
    origen = await GestorBaseDatos.abrir(
      ruta,
      fabrica: databaseFactoryFfi,
      datos: DatosMigracion(salarioMensual: salarioV8, valorHoraExtra: valorHoraExtraV8, cotizacionUsd: 1000, ahora: DateTime(2026, 10, 30)),
    );
  });

  tearDown(() async {
    await origen.close();
    await directorio.delete(recursive: true);
  });

  Future<Map<String, List<Map<String, Object?>>>> convertirV8(Map<String, Object?> v8) => ServicioRespaldo.convertirV8(
        v8,
        rutaTemporal: p.join(directorio.path, 'importacion', 'respaldo_v8.db'),
        datos: DatosMigracion(salarioMensual: salarioV8, valorHoraExtra: valorHoraExtraV8, ahora: DateTime(2026, 10, 30)),
        fabrica: databaseFactoryFfi,
      );

  Future<Map<String, int>> contar(Database db) async => {
        for (final t in ServicioRespaldo.tablas) t: (await db.query(t)).length,
      };

  test('ida y vuelta: exportar e importar deja los mismos datos', () async {
    final texto = jsonEncode(await ServicioRespaldo.armar(origen));
    final destino = await abrirBaseNueva();
    addTearDown(destino.close);

    await ServicioRespaldo.restaurar(destino, await ServicioRespaldo.leer(texto, convertirV8: convertirV8));

    expect(await contar(destino), await contar(origen));
    expect(await ConsultasLibro(destino).saldos(), await ConsultasLibro(origen).saldos());
    final ajustes = await destino.query('ajustes');
    expect(ajustes.single['valor'], '500000', reason: 'el valor de la hora extra viaja en el respaldo');
  });

  test('un respaldo v3 (de la app v8) pasa por la migración', () async {
    final v8 = await abrirBaseV8();
    final viejo = <String, Object?>{'version': 3, 'fecha_exportacion': '2026-10-01T10:00:00'};
    for (final t in EsquemaV8.tablas) {
      viejo[t] = await v8.query(t);
    }
    await v8.close();

    final destino = await abrirBaseNueva();
    addTearDown(destino.close);
    await ServicioRespaldo.restaurar(destino, await ServicioRespaldo.leer(jsonEncode(viejo), convertirV8: convertirV8));

    // Sin cotización guardada, Viaje se valúa con el promedio de sus aportes
    // (1.000), así que el disponible queda igual que en la migración.
    expect(await ConsultasLibro(destino).disponible(), await ConsultasLibro(origen).disponible());
    expect((await destino.query('planes')).length, 7);
    expect(File(p.join(directorio.path, 'importacion', 'respaldo_v8.db')).existsSync(), isFalse);
  });

  group('un respaldo inválido no toca los datos', () {
    Future<void> importar(String texto) async =>
        ServicioRespaldo.restaurar(origen, await ServicioRespaldo.leer(texto, convertirV8: convertirV8));

    for (final caso in {
      'texto que no es JSON': 'esto no es un respaldo',
      'tablas nulas (el bug de v8)': '{"categorias": null, "movimientos": null}',
      'formato 3 incompleto': '{"version": 3, "categorias": null, "movimientos": null}',
      'formato 2 sin tablas': '{"formato": 2, "schema_version": 9}',
      'otra versión del esquema': '{"formato": 2, "schema_version": 99, "tablas": {}}',
    }.entries) {
      test(caso.key, () async {
        final antes = await contar(origen);
        await expectLater(importar(caso.value), throwsA(isA<ErrorRespaldo>()));
        expect(await contar(origen), antes);
      });
    }

    test('una fila que rompe una referencia revierte todo', () async {
      final respaldo = await ServicioRespaldo.armar(origen);
      final tablas = respaldo['tablas']! as Map<String, Object?>;
      final movimientos = (tablas['movimientos']! as List).cast<Map<String, Object?>>();
      tablas['movimientos'] = [
        ...movimientos,
        {...movimientos.first, 'id': 9999, 'cuenta_id': 4242},
      ];
      final antes = await contar(origen);
      final disponible = await ConsultasLibro(origen).disponible();

      await expectLater(importar(jsonEncode(respaldo)), throwsA(anything));

      expect(await contar(origen), antes);
      expect(await ConsultasLibro(origen).disponible(), disponible);
      expect((await origen.query('cuentas', where: 'id = ?', whereArgs: [Esquema.cuentaLibreArs])), isNotEmpty);
    });
  });
}
