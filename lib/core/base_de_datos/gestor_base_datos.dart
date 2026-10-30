import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Clase Singleton para gestionar la conexión y el ciclo de vida de SQLite.
class GestorBaseDatos {
  static const String _nombreBD = 'finanzas.db';
  static const int _versionBD = 8;

  static Database? _instancia;

  // Constructor privado
  GestorBaseDatos._();
  
  // Instancia Singleton
  static final GestorBaseDatos instancia = GestorBaseDatos._();

  /// Obtiene la instancia de la base de datos, inicializándola si es necesario.
  Future<Database> obtenerBaseDatos() async {
    if (_instancia != null) return _instancia!;
    _instancia = await _inicializarBaseDatos();
    return _instancia!;
  }

  Future<Database> _inicializarBaseDatos() async {
    try {
      final directorio = await getApplicationDocumentsDirectory();
      final ruta = join(directorio.path, _nombreBD);

      return await openDatabase(
        ruta,
        version: _versionBD,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _alCrear,
        onUpgrade: _alActualizar,
      );
    } catch (error) {
      // En un flujo ideal, esto se guardaría en logs_errores,
      // pero como la DB no pudo abrirse, delegamos el error hacia arriba.
      rethrow;
    }
  }

  /// Método ejecutado al crear la base de datos por primera vez.
  Future<void> _alCrear(Database db, int version) async {
    try {
      // 1. Tabla: categorias
      // presupuesto_limite se guarda como INTEGER (monto * 100) para evitar coma flotante
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

      // 2. Tabla: movimientos
      // monto se guarda como INTEGER (monto * 100)
      // tipo 'ahorro' = plata que se movió del bolsillo libre a una meta.
      //   Esas filas llevan meta_id (a qué meta) y monto_meta (el monto en la
      //   moneda de la meta, para poder revertir con exactitud aportes en USD).
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

      // 3. Tabla: logs_errores
      await db.execute('''
        CREATE TABLE logs_errores (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha INTEGER NOT NULL,
          mensaje TEXT NOT NULL
        )
      ''');

      // 4. Tabla: metas (v2)
      await _crearTablasMetas(db);

      // 5. Tabla: ahorros_acumulados (v2)
      await _crearTablaAhorros(db);

      // 6. Tablas: gastos_fijos, cuotas y recurrencias_aplicadas (v3)
      await _crearTablasRecurrencias(db);

      // Sembrado Inicial de Categorías Defecto
      await _sembrarDatosIniciales(db);
    } catch (error) {
      rethrow;
    }
  }

  /// Crea las tablas de metas y submetas.
  Future<void> _crearTablasMetas(Database db) async {
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
  }

  /// Crea las tablas de gastos fijos, cuotas y el registro de recurrencias
  /// aplicadas (para no descontar dos veces el mismo mes).
  Future<void> _crearTablasRecurrencias(Database db) async {
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

  /// Crea la tabla de ahorros acumulados (fila única).
  Future<void> _crearTablaAhorros(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ahorros_acumulados (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        ahorro_previo_ars INTEGER NOT NULL DEFAULT 0,
        ahorro_previo_usd INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insertar fila única con valores en 0
    await db.insert('ahorros_acumulados', {
      'id': 1,
      'ahorro_previo_ars': 0,
      'ahorro_previo_usd': 0,
    });
  }

  /// Estructura base para futuras migraciones de esquema sin perder datos.
  Future<void> _alActualizar(Database db, int versionAnterior, int versionNueva) async {
    try {
      if (versionAnterior < 2) {
        // Migración v1 → v2: Agregar tablas de metas y ahorros
        await _crearTablasMetas(db);
        await _crearTablaAhorros(db);
      }
      if (versionAnterior < 3) {
        // Migración v2 → v3: Agregar gastos fijos, cuotas y recurrencias
        await _crearTablasRecurrencias(db);
      }
      if (versionAnterior < 4) {
        // Migración v3 → v4: Sembrar categorías adicionales (sin duplicar las
        // que ya existan por nombre).
        await _sembrarCategoriasAdicionales(db);
      }
      if (versionAnterior < 5) {
        // Migración v4 → v5: moneda en metas + categoría "Horas extras".
        try {
          await db.execute("ALTER TABLE metas ADD COLUMN moneda TEXT NOT NULL DEFAULT 'ARS'");
        } catch (_) {/* la columna ya podría existir */}
        await _sembrarCategoriasAdicionales(db);
      }
      if (versionAnterior < 6) {
        // Migración v5 → v6: día de débito en gastos fijos.
        try {
          await db.execute('ALTER TABLE gastos_fijos ADD COLUMN dia_debito INTEGER NOT NULL DEFAULT 1');
        } catch (_) {/* la columna ya podría existir */}
      }
      if (versionAnterior < 7) {
        // Migración v6 → v7: día de débito en cuotas.
        try {
          await db.execute('ALTER TABLE cuotas ADD COLUMN dia_debito INTEGER NOT NULL DEFAULT 1');
        } catch (_) {/* la columna ya podría existir */}
      }
      if (versionAnterior < 8) {
        // Migración v7 → v8: los aportes a metas ahora se registran como
        // movimientos de tipo 'ahorro'. SQLite no permite modificar un CHECK
        // con ALTER, así que recreamos la tabla movimientos preservando todas
        // las filas existentes (los ingresos/gastos ya cargados no se pierden).
        await _migrarMovimientosV8(db);
      }
    } catch (error) {
      rethrow;
    }
  }

  /// Recrea la tabla `movimientos` con el nuevo esquema (tipo 'ahorro' +
  /// meta_id + monto_meta) copiando fila por fila lo que ya había.
  Future<void> _migrarMovimientosV8(Database db) async {
    // Si ya tiene la columna meta_id (por reinstalación parcial), no hacemos nada.
    final info = await db.rawQuery('PRAGMA table_info(movimientos)');
    final tieneMetaId = info.any((c) => c['name'] == 'meta_id');
    if (tieneMetaId) return;

    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE movimientos_nuevo (
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
      await txn.execute('''
        INSERT INTO movimientos_nuevo (id, monto, fecha, descripcion, tipo, categoria_id)
        SELECT id, monto, fecha, descripcion, tipo, categoria_id FROM movimientos
      ''');
      await txn.execute('DROP TABLE movimientos');
      await txn.execute('ALTER TABLE movimientos_nuevo RENAME TO movimientos');
    });
  }

  /// Inyecta automáticamente rubros indispensables la primera vez que se abre la app.
  Future<void> _sembrarDatosIniciales(Database db) async {
    final categoriasDefecto = [
      {
        'nombre': 'Sueldo',
        'tipo': 'ingreso',
        'color_hex': '0xFF4CAF50', // Verde
        'icono': 'attach_money',
        'es_sistema': 1,
      },
      {
        'nombre': 'Alimentación',
        'tipo': 'gasto',
        'color_hex': '0xFFFF9800', // Naranja
        'icono': 'restaurant',
        'es_sistema': 1,
      },
      {
        'nombre': 'Transporte',
        'tipo': 'gasto',
        'color_hex': '0xFF2196F3', // Azul
        'icono': 'directions_car',
        'es_sistema': 1,
      },
      {
        'nombre': 'Otros Gastos',
        'tipo': 'gasto',
        'color_hex': '0xFF9E9E9E', // Gris
        'icono': 'more_horiz',
        'es_sistema': 1,
      },
    ];

    for (final categoria in categoriasDefecto) {
      await db.insert('categorias', categoria);
    }

    // Además del set base, sembramos un set más amplio de rubros.
    await _sembrarCategoriasAdicionales(db);
  }

  /// Categorías adicionales (rubros comunes). `es_sistema = 0` para que el
  /// usuario pueda editarlas o borrarlas. Se insertan evitando duplicar por
  /// nombre, así la migración es segura para usuarios existentes.
  Future<void> _sembrarCategoriasAdicionales(Database db) async {
    final adicionales = [
      // Gastos
      {'nombre': 'Servicios', 'tipo': 'gasto', 'color_hex': '0xFFFFC107', 'icono': 'electric_bolt'},
      {'nombre': 'Vivienda', 'tipo': 'gasto', 'color_hex': '0xFF795548', 'icono': 'home'},
      {'nombre': 'Salud', 'tipo': 'gasto', 'color_hex': '0xFFE91E63', 'icono': 'local_hospital'},
      {'nombre': 'Entretenimiento', 'tipo': 'gasto', 'color_hex': '0xFF9C27B0', 'icono': 'videogame_asset'},
      {'nombre': 'Deudas', 'tipo': 'gasto', 'color_hex': '0xFFF44336', 'icono': 'category'},
      {'nombre': 'Educación', 'tipo': 'gasto', 'color_hex': '0xFF3F51B5', 'icono': 'school'},
      {'nombre': 'Ropa', 'tipo': 'gasto', 'color_hex': '0xFF00BCD4', 'icono': 'shopping_cart'},
      {'nombre': 'Salidas', 'tipo': 'gasto', 'color_hex': '0xFF8D6E63', 'icono': 'local_cafe'},
      {'nombre': 'Mascotas', 'tipo': 'gasto', 'color_hex': '0xFF689F38', 'icono': 'pets'},
      // Ingresos
      {'nombre': 'Horas extras', 'tipo': 'ingreso', 'color_hex': '0xFFFFB300', 'icono': 'more_time'},
      {'nombre': 'Freelance', 'tipo': 'ingreso', 'color_hex': '0xFF26A69A', 'icono': 'attach_money'},
      {'nombre': 'Ventas', 'tipo': 'ingreso', 'color_hex': '0xFF66BB6A', 'icono': 'shopping_cart'},
      {'nombre': 'Otros Ingresos', 'tipo': 'ingreso', 'color_hex': '0xFF607D8B', 'icono': 'more_horiz'},
    ];

    for (final categoria in adicionales) {
      final existe = await db.query('categorias',
          where: 'nombre = ?', whereArgs: [categoria['nombre']], limit: 1);
      if (existe.isEmpty) {
        await db.insert('categorias', {...categoria, 'es_sistema': 0});
      }
    }
  }
}
