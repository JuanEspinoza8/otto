import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'esquema.dart';
import 'migracion_v9.dart';

/// Abre la base SQLite de la app y la migra al esquema actual.
class GestorBaseDatos {
  GestorBaseDatos._();

  static final GestorBaseDatos instancia = GestorBaseDatos._();

  static const String nombreArchivo = 'finanzas.db';

  /// Copia del archivo previa a la migración a v9 (no se borra nunca).
  static const String nombreRespaldoV8 = 'finanzas_respaldo_v8.db';

  static Database? _instancia;

  /// Reemplaza la base por una abierta desde afuera (solo para tests).
  @visibleForTesting
  static void usarBaseDePrueba(Database? db) => _instancia = db;

  Future<Database> obtenerBaseDatos() async {
    return _instancia ??= await _abrirEnDocumentos();
  }

  Future<String> rutaArchivo() async {
    final directorio = await getApplicationDocumentsDirectory();
    return join(directorio.path, nombreArchivo);
  }

  Future<Database> _abrirEnDocumentos() async {
    final prefs = await SharedPreferences.getInstance();
    return abrir(await rutaArchivo(), datos: datosDesdePreferencias(prefs));
  }

  /// Valores de v8 que viven en SharedPreferences y necesita la migración.
  static DatosMigracion datosDesdePreferencias(SharedPreferences prefs) => DatosMigracion(
        salarioMensual: prefs.getDouble('salarioMensual') ?? 0,
        valorHoraExtra: prefs.getDouble('valorHoraExtra') ?? 0,
        cotizacionUsd: prefs.getDouble('dolarBlueVenta'),
        ahora: DateTime.now(),
      );

  /// Abre (o crea) la base en [ruta]. Si es de una versión anterior, primero
  /// copia el archivo y después la migra dentro de una transacción.
  static Future<Database> abrir(
    String ruta, {
    DatabaseFactory? fabrica,
    DatosMigracion? datos,
    @visibleForTesting Future<void> Function(DatabaseExecutor db)? antesDeVerificar,
  }) async {
    await _respaldarSiHayQueMigrar(ruta);
    return (fabrica ?? databaseFactory).openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: Esquema.version,
        singleInstance: fabrica == null,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await Esquema.crear(db);
          await Esquema.sembrarCuentas(db);
          await Esquema.sembrarCategorias(db);
        },
        // sqflite corre onUpgrade dentro de una transacción: si la migración
        // lanza, no queda nada a medias.
        onUpgrade: (db, anterior, _) async {
          if (anterior < 8) await _actualizarHastaV8(db, anterior);
          await MigradorV9(
            db,
            datos ?? DatosMigracion(ahora: DateTime.now()),
            antesDeVerificar: antesDeVerificar,
          ).migrar();
        },
      ),
    );
  }

  /// Copia el archivo antes de migrarlo, por si algo sale mal en el teléfono.
  static Future<void> _respaldarSiHayQueMigrar(String ruta) async {
    if (ruta == inMemoryDatabasePath) return;
    final archivo = File(ruta);
    if (!await archivo.exists()) return;
    final version = await _versionDelArchivo(archivo);
    if (version == 0 || version >= Esquema.version) return;
    // Si un intento anterior falló, la base siguió en v8 (y pudo recibir datos
    // nuevos): la copia se rehace en cada intento con el estado actual.
    final respaldo = File(join(dirname(ruta), nombreRespaldoV8));
    await archivo.copy(respaldo.path);
    for (final sufijo in ['-wal', '-journal']) {
      final extra = File('$ruta$sufijo');
      final copiaExtra = File('${respaldo.path}$sufijo');
      if (await extra.exists()) {
        await extra.copy(copiaExtra.path);
      } else if (await copiaExtra.exists()) {
        await copiaExtra.delete();
      }
    }
  }

  /// `user_version` de SQLite: 4 bytes big-endian en el byte 60 del archivo.
  static Future<int> _versionDelArchivo(File archivo) async {
    final acceso = await archivo.open();
    try {
      final cabecera = await acceso.read(64);
      if (cabecera.length < 64) return 0;
      return ByteData.sublistView(Uint8List.fromList(cabecera)).getUint32(60);
    } finally {
      await acceso.close();
    }
  }

  /// Pasos históricos v1 → v8 (bases muy viejas). Después corre la v9.
  static Future<void> _actualizarHastaV8(Database db, int anterior) async {
    if (anterior < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS metas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          icono TEXT NOT NULL DEFAULT 'flag',
          monto_objetivo INTEGER NOT NULL DEFAULT 0,
          monto_actual INTEGER NOT NULL DEFAULT 0,
          moneda TEXT NOT NULL DEFAULT 'ARS',
          fecha_creacion INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS submetas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          icono TEXT NOT NULL DEFAULT 'flag',
          monto_objetivo INTEGER NOT NULL DEFAULT 0,
          monto_actual INTEGER NOT NULL DEFAULT 0,
          meta_id INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ahorros_acumulados (
          id INTEGER PRIMARY KEY CHECK(id = 1),
          ahorro_previo_ars INTEGER NOT NULL DEFAULT 0,
          ahorro_previo_usd INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (anterior < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gastos_fijos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          monto INTEGER NOT NULL DEFAULT 0,
          categoria_id INTEGER,
          dia_debito INTEGER NOT NULL DEFAULT 1,
          activo INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cuotas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          monto_cuota INTEGER NOT NULL DEFAULT 0,
          categoria_id INTEGER,
          total_cuotas INTEGER NOT NULL DEFAULT 1,
          cuotas_pagadas INTEGER NOT NULL DEFAULT 0,
          dia_debito INTEGER NOT NULL DEFAULT 1,
          activo INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurrencias_aplicadas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo TEXT NOT NULL,
          referencia_id INTEGER NOT NULL,
          periodo TEXT NOT NULL,
          movimiento_id INTEGER
        )
      ''');
    }
    final columnasMetas = await _columnas(db, 'metas');
    if (!columnasMetas.contains('moneda')) {
      await db.execute("ALTER TABLE metas ADD COLUMN moneda TEXT NOT NULL DEFAULT 'ARS'");
    }
    if (!(await _columnas(db, 'gastos_fijos')).contains('dia_debito')) {
      await db.execute('ALTER TABLE gastos_fijos ADD COLUMN dia_debito INTEGER NOT NULL DEFAULT 1');
    }
    if (!(await _columnas(db, 'cuotas')).contains('dia_debito')) {
      await db.execute('ALTER TABLE cuotas ADD COLUMN dia_debito INTEGER NOT NULL DEFAULT 1');
    }
    if (!(await _columnas(db, 'movimientos')).contains('meta_id')) {
      // v8 agregó los aportes ('ahorro') a movimientos; la v9 los convierte
      // en transferencias, así que alcanza con sumar las columnas.
      await db.execute('ALTER TABLE movimientos ADD COLUMN meta_id INTEGER');
      await db.execute('ALTER TABLE movimientos ADD COLUMN monto_meta INTEGER');
    }
  }

  static Future<Set<String>> _columnas(DatabaseExecutor db, String tabla) async {
    final info = await db.rawQuery('PRAGMA table_info($tabla)');
    return info.map((c) => c['name'] as String).toSet();
  }
}
