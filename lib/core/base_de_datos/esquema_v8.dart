import 'package:sqflite/sqflite.dart';

/// Esquema v8 (el de la app antes del libro único). Se conserva congelado
/// para convertir respaldos viejos: se cargan en una base v8 temporal y pasan
/// por la misma migración que la base del teléfono.
abstract final class EsquemaV8 {
  static const int version = 8;

  /// Tablas que traía un respaldo v8 (formato 3), en orden de inserción.
  static const List<String> tablas = [
    'categorias',
    'metas',
    'submetas',
    'cuotas',
    'gastos_fijos',
    'ahorros_acumulados',
    'movimientos',
    'recurrencias_aplicadas',
  ];

  /// Crea las tablas v8 en una base vacía.
  static Future<void> crear(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT CHECK(tipo IN ('ingreso', 'gasto')),
        color_hex TEXT NOT NULL,
        icono TEXT NOT NULL,
        presupuesto_limite INTEGER DEFAULT 0,
        es_sistema INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE movimientos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monto INTEGER NOT NULL CHECK(monto > 0),
        fecha INTEGER NOT NULL,
        descripcion TEXT,
        tipo TEXT CHECK(tipo IN ('ingreso', 'gasto', 'ahorro')),
        categoria_id INTEGER,
        meta_id INTEGER,
        monto_meta INTEGER,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE RESTRICT,
        FOREIGN KEY (meta_id) REFERENCES metas(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE logs_errores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha INTEGER NOT NULL,
        mensaje TEXT NOT NULL
      )
    ''');
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
        meta_id INTEGER NOT NULL,
        FOREIGN KEY (meta_id) REFERENCES metas(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ahorros_acumulados (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        ahorro_previo_ars INTEGER NOT NULL DEFAULT 0,
        ahorro_previo_usd INTEGER NOT NULL DEFAULT 0
      )
    ''');
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
}
