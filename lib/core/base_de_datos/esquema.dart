import 'package:sqflite/sqflite.dart';

/// Esquema actual de la base (v9): un libro único de movimientos entre cuentas.
///
/// - `cuentas`: "Libre ARS" (la plata disponible), "Dólares" y una por meta.
/// - `movimientos`: ingresos y gastos (con categoría), transferencias entre
///   cuentas (aportes, retiros y movimientos entre metas) y saldos iniciales.
///   El saldo de una cuenta sale siempre de sumar sus movimientos.
/// - `planes` y `plan_aplicaciones`: sueldo, gastos fijos y cuotas. Cada
///   período confirmado es una fila; si se borra su movimiento, se libera.
/// - `avisos_mes`: avisos de la UI ya resueltos en un mes (resumen, horas
///   extra, sobrante del mes anterior).
/// - `ajustes`: valores del usuario que tienen que viajar en el respaldo.
abstract final class Esquema {
  static const int version = 9;

  /// Ids fijos de las cuentas que existen siempre.
  static const int cuentaLibreArs = 1;
  static const int cuentaDolares = 2;

  static const List<String> tablas = [
    '''
    CREATE TABLE categorias (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      tipo TEXT NOT NULL CHECK (tipo IN ('ingreso', 'gasto')),
      color_hex TEXT NOT NULL,
      icono TEXT NOT NULL,
      presupuesto_limite INTEGER NOT NULL DEFAULT 0 CHECK (presupuesto_limite >= 0),
      es_sistema INTEGER NOT NULL DEFAULT 0 CHECK (es_sistema IN (0, 1))
    )
    ''',
    '''
    CREATE TABLE cuentas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      moneda TEXT NOT NULL CHECK (moneda IN ('ARS', 'USD')),
      tipo TEXT NOT NULL CHECK (tipo IN ('libre', 'meta')),
      archivada INTEGER NOT NULL DEFAULT 0 CHECK (archivada IN (0, 1))
    )
    ''',
    '''
    CREATE TABLE metas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cuenta_id INTEGER NOT NULL UNIQUE REFERENCES cuentas (id) ON DELETE RESTRICT,
      icono TEXT NOT NULL DEFAULT 'flag',
      monto_objetivo INTEGER NOT NULL CHECK (monto_objetivo >= 0),
      fecha_creacion INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE movimientos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL CHECK (fecha GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'),
      creado_en INTEGER NOT NULL,
      tipo TEXT NOT NULL CHECK (tipo IN ('ingreso', 'gasto', 'transferencia', 'saldo_inicial')),
      monto_centavos INTEGER NOT NULL CHECK (monto_centavos > 0),
      cuenta_id INTEGER NOT NULL REFERENCES cuentas (id) ON DELETE RESTRICT,
      cuenta_destino_id INTEGER REFERENCES cuentas (id) ON DELETE RESTRICT,
      monto_destino_centavos INTEGER CHECK (monto_destino_centavos IS NULL OR monto_destino_centavos > 0),
      categoria_id INTEGER REFERENCES categorias (id) ON DELETE RESTRICT,
      descripcion TEXT,
      origen TEXT NOT NULL DEFAULT 'manual'
        CHECK (origen IN ('manual', 'plan', 'ia', 'import', 'migracion')),
      CHECK (
        (tipo IN ('ingreso', 'gasto')
          AND categoria_id IS NOT NULL
          AND cuenta_destino_id IS NULL
          AND monto_destino_centavos IS NULL)
        OR (tipo = 'transferencia'
          AND categoria_id IS NULL
          AND cuenta_destino_id IS NOT NULL
          AND cuenta_destino_id <> cuenta_id)
        OR (tipo = 'saldo_inicial'
          AND categoria_id IS NULL
          AND cuenta_destino_id IS NULL
          AND monto_destino_centavos IS NULL)
      )
    )
    ''',
    '''
    CREATE TABLE planes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo TEXT NOT NULL CHECK (tipo IN ('fijo', 'cuotas', 'sueldo')),
      nombre TEXT NOT NULL,
      categoria_id INTEGER REFERENCES categorias (id) ON DELETE SET NULL,
      cuenta_id INTEGER NOT NULL DEFAULT 1 REFERENCES cuentas (id) ON DELETE RESTRICT,
      monto_centavos INTEGER NOT NULL CHECK (monto_centavos > 0),
      total_centavos INTEGER CHECK (total_centavos IS NULL OR total_centavos > 0),
      total_cuotas INTEGER CHECK (total_cuotas IS NULL OR total_cuotas > 0),
      primer_periodo TEXT NOT NULL CHECK (primer_periodo GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]'),
      dia_debito INTEGER NOT NULL DEFAULT 1 CHECK (dia_debito BETWEEN 1 AND 28),
      activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
      fin_periodo TEXT CHECK (fin_periodo IS NULL OR fin_periodo GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]'),
      CHECK ((tipo = 'cuotas') = (total_cuotas IS NOT NULL AND total_centavos IS NOT NULL))
    )
    ''',
    '''
    CREATE TABLE plan_aplicaciones (
      plan_id INTEGER NOT NULL REFERENCES planes (id) ON DELETE CASCADE,
      periodo TEXT NOT NULL CHECK (periodo GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]'),
      movimiento_id INTEGER REFERENCES movimientos (id) ON DELETE CASCADE,
      PRIMARY KEY (plan_id, periodo)
    )
    ''',
    '''
    CREATE TABLE avisos_mes (
      clave TEXT NOT NULL,
      periodo TEXT NOT NULL,
      PRIMARY KEY (clave, periodo)
    )
    ''',
    '''
    CREATE TABLE ajustes (
      clave TEXT PRIMARY KEY,
      valor TEXT NOT NULL
    )
    ''',
  ];

  static const List<String> indices = [
    'CREATE INDEX idx_movimientos_fecha ON movimientos (fecha)',
    'CREATE INDEX idx_movimientos_categoria_fecha ON movimientos (categoria_id, fecha)',
    'CREATE INDEX idx_movimientos_cuenta ON movimientos (cuenta_id)',
    'CREATE INDEX idx_movimientos_cuenta_destino ON movimientos (cuenta_destino_id)',
    'CREATE INDEX idx_plan_aplicaciones_movimiento ON plan_aplicaciones (movimiento_id)',
  ];

  /// Saldo de cada cuenta en su moneda: lo que entra menos lo que sale.
  static const String vistaSaldos = '''
    CREATE VIEW saldos_cuentas AS
    SELECT
      c.id AS cuenta_id,
      COALESCE((
        SELECT SUM(CASE WHEN m.tipo IN ('ingreso', 'saldo_inicial') THEN m.monto_centavos
                        ELSE -m.monto_centavos END)
        FROM movimientos m WHERE m.cuenta_id = c.id
      ), 0)
      + COALESCE((
        SELECT SUM(COALESCE(m.monto_destino_centavos, m.monto_centavos))
        FROM movimientos m
        WHERE m.tipo = 'transferencia' AND m.cuenta_destino_id = c.id
      ), 0) AS saldo_centavos
    FROM cuentas c
  ''';

  /// Crea todas las tablas, índices y vistas en una base vacía.
  static Future<void> crear(DatabaseExecutor db) async {
    for (final sql in tablas) {
      await db.execute(sql);
    }
    for (final sql in indices) {
      await db.execute(sql);
    }
    await db.execute(vistaSaldos);
  }

  /// Cuentas que existen desde el primer día.
  static Future<void> sembrarCuentas(DatabaseExecutor db) async {
    await db.insert('cuentas', {
      'id': cuentaLibreArs,
      'nombre': 'Libre ARS',
      'moneda': 'ARS',
      'tipo': 'libre',
    });
    await db.insert('cuentas', {
      'id': cuentaDolares,
      'nombre': 'Dólares',
      'moneda': 'USD',
      'tipo': 'libre',
    });
  }

  /// Categorías por defecto. Las 4 primeras son del sistema (no se borran).
  static const List<Map<String, Object>> categoriasIniciales = [
    {'nombre': 'Sueldo', 'tipo': 'ingreso', 'color_hex': '0xFF4CAF50', 'icono': 'attach_money', 'es_sistema': 1},
    {'nombre': 'Alimentación', 'tipo': 'gasto', 'color_hex': '0xFFFF9800', 'icono': 'restaurant', 'es_sistema': 1},
    {'nombre': 'Transporte', 'tipo': 'gasto', 'color_hex': '0xFF2196F3', 'icono': 'directions_car', 'es_sistema': 1},
    {'nombre': 'Otros Gastos', 'tipo': 'gasto', 'color_hex': '0xFF9E9E9E', 'icono': 'more_horiz', 'es_sistema': 1},
    {'nombre': 'Servicios', 'tipo': 'gasto', 'color_hex': '0xFFFFC107', 'icono': 'electric_bolt', 'es_sistema': 0},
    {'nombre': 'Vivienda', 'tipo': 'gasto', 'color_hex': '0xFF795548', 'icono': 'home', 'es_sistema': 0},
    {'nombre': 'Salud', 'tipo': 'gasto', 'color_hex': '0xFFE91E63', 'icono': 'local_hospital', 'es_sistema': 0},
    {'nombre': 'Entretenimiento', 'tipo': 'gasto', 'color_hex': '0xFF9C27B0', 'icono': 'videogame_asset', 'es_sistema': 0},
    {'nombre': 'Deudas', 'tipo': 'gasto', 'color_hex': '0xFFF44336', 'icono': 'category', 'es_sistema': 0},
    {'nombre': 'Educación', 'tipo': 'gasto', 'color_hex': '0xFF3F51B5', 'icono': 'school', 'es_sistema': 0},
    {'nombre': 'Ropa', 'tipo': 'gasto', 'color_hex': '0xFF00BCD4', 'icono': 'shopping_cart', 'es_sistema': 0},
    {'nombre': 'Salidas', 'tipo': 'gasto', 'color_hex': '0xFF8D6E63', 'icono': 'local_cafe', 'es_sistema': 0},
    {'nombre': 'Mascotas', 'tipo': 'gasto', 'color_hex': '0xFF689F38', 'icono': 'pets', 'es_sistema': 0},
    {'nombre': 'Horas extras', 'tipo': 'ingreso', 'color_hex': '0xFFFFB300', 'icono': 'more_time', 'es_sistema': 0},
    {'nombre': 'Freelance', 'tipo': 'ingreso', 'color_hex': '0xFF26A69A', 'icono': 'attach_money', 'es_sistema': 0},
    {'nombre': 'Ventas', 'tipo': 'ingreso', 'color_hex': '0xFF66BB6A', 'icono': 'shopping_cart', 'es_sistema': 0},
    {'nombre': 'Otros Ingresos', 'tipo': 'ingreso', 'color_hex': '0xFF607D8B', 'icono': 'more_horiz', 'es_sistema': 0},
  ];

  static Future<void> sembrarCategorias(DatabaseExecutor db) async {
    for (final categoria in categoriasIniciales) {
      await db.insert('categorias', categoria);
    }
  }
}
