import 'package:finanzas/core/base_de_datos/esquema_v8.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Base de prueba con el esquema v8 (el que tiene hoy el cliente) y datos
/// sintéticos. El esquema v8 está congelado en `EsquemaV8`.
///
/// Resumen de los datos (montos en pesos):
/// - Ahorro previo: $150.000 y US$500.
/// - Agosto 2026: sueldo 800.000; gastos 45.500,50 + 300.000 + 12.000;
///   aportes 50.000 (Vacaciones) y 200.000 → US$200 (Viaje).
/// - Septiembre: sueldo 800.000; gastos 300.000 + 50.000 + 8.000 + 25.000;
///   aportes 40.000 (Vacaciones) y 100.000 (Fondo).
/// - Octubre: sueldo 850.000 + horas extra 15.000; gastos 300.000 (alquiler,
///   duplicado por doble toque) + 50.000 + 90.000 + 30.000.
/// - Metas: Vacaciones $120.000 (solo 90.000 tienen aporte registrado),
///   Viaje US$300 (US$200 con aporte), Fondo $100.000, Auto $0.
/// - Fijos: Alquiler, Netflix e inactivo Gas (sin categoría).
/// - Cuotas: Heladera 3/6 (solo 2 con aplicación), Celular 3/3 adelantadas
///   en un solo pago, Notebook 0/12 sin categoría.
const int idSueldo = 1;
const int idAlimentacion = 2;
const int idTransporte = 3;
const int idOtrosGastos = 4;
const int idServicios = 5;
const int idVivienda = 6;
const int idDeudas = 9;
const int idHorasExtras = 14;
const int idGimnasio = 18;

const int metaVacaciones = 1;
const int metaViaje = 2;
const int metaFondo = 3;
const int metaAuto = 4;

/// Ajustes que en v8 viven en SharedPreferences.
const double salarioV8 = 850000;
const double valorHoraExtraV8 = 5000;

int _ms(int anio, int mes, int dia, [int hora = 12, int minuto = 0]) =>
    DateTime(anio, mes, dia, hora, minuto).millisecondsSinceEpoch;

/// Crea el esquema v8 (el mismo que usa la app para importar respaldos viejos).
Future<void> crearEsquemaV8(Database db) => EsquemaV8.crear(db);

Future<void> _sembrarCategorias(Database db) async {
  const categorias = [
    ['Sueldo', 'ingreso', '0xFF4CAF50', 'attach_money', 1],
    ['Alimentación', 'gasto', '0xFFFF9800', 'restaurant', 1],
    ['Transporte', 'gasto', '0xFF2196F3', 'directions_car', 1],
    ['Otros Gastos', 'gasto', '0xFF9E9E9E', 'more_horiz', 1],
    ['Servicios', 'gasto', '0xFFFFC107', 'electric_bolt', 0],
    ['Vivienda', 'gasto', '0xFF795548', 'home', 0],
    ['Salud', 'gasto', '0xFFE91E63', 'local_hospital', 0],
    ['Entretenimiento', 'gasto', '0xFF9C27B0', 'videogame_asset', 0],
    ['Deudas', 'gasto', '0xFFF44336', 'category', 0],
    ['Educación', 'gasto', '0xFF3F51B5', 'school', 0],
    ['Ropa', 'gasto', '0xFF00BCD4', 'shopping_cart', 0],
    ['Salidas', 'gasto', '0xFF8D6E63', 'local_cafe', 0],
    ['Mascotas', 'gasto', '0xFF689F38', 'pets', 0],
    ['Horas extras', 'ingreso', '0xFFFFB300', 'more_time', 0],
    ['Freelance', 'ingreso', '0xFF26A69A', 'attach_money', 0],
    ['Ventas', 'ingreso', '0xFF66BB6A', 'shopping_cart', 0],
    ['Otros Ingresos', 'ingreso', '0xFF607D8B', 'more_horiz', 0],
  ];
  for (final c in categorias) {
    await db.insert('categorias', {
      'nombre': c[0],
      'tipo': c[1],
      'color_hex': c[2],
      'icono': c[3],
      'es_sistema': c[4],
    });
  }
  // Categoría creada por el usuario, con presupuesto de $20.000.
  await db.insert('categorias', {
    'id': idGimnasio,
    'nombre': 'Gimnasio',
    'tipo': 'gasto',
    'color_hex': '0xFF009688',
    'icono': 'fitness_center',
    'presupuesto_limite': 2000000,
    'es_sistema': 0,
  });
}

Future<void> _mov(
  Database db,
  int id,
  int centavos,
  int fecha,
  String tipo, {
  int? cat,
  String? desc,
  int? meta,
  int? montoMeta,
}) =>
    db.insert('movimientos', {
      'id': id,
      'monto': centavos,
      'fecha': fecha,
      'descripcion': desc,
      'tipo': tipo,
      'categoria_id': cat,
      'meta_id': meta,
      'monto_meta': montoMeta,
    });

Future<void> _rec(Database db, String tipo, int ref, String periodo, int? mov) =>
    db.insert('recurrencias_aplicadas', {
      'tipo': tipo,
      'referencia_id': ref,
      'periodo': periodo,
      'movimiento_id': mov,
    });

/// Carga los datos sintéticos descritos arriba.
Future<void> sembrarDatosV8(Database db) async {
  await _sembrarCategorias(db);

  await db.insert('ahorros_acumulados', {
    'id': 1,
    'ahorro_previo_ars': 15000000,
    'ahorro_previo_usd': 50000,
  });

  await db.insert('metas', {
    'id': metaVacaciones,
    'nombre': 'Vacaciones',
    'icono': 'flight',
    'monto_objetivo': 50000000,
    'monto_actual': 12000000,
    'moneda': 'ARS',
    'fecha_creacion': _ms(2026, 7, 1),
  });
  await db.insert('metas', {
    'id': metaViaje,
    'nombre': 'Viaje',
    'icono': 'flight',
    'monto_objetivo': 200000,
    'monto_actual': 30000,
    'moneda': 'USD',
    'fecha_creacion': _ms(2026, 7, 15),
  });
  await db.insert('metas', {
    'id': metaFondo,
    'nombre': 'Fondo de emergencia',
    'icono': 'savings',
    'monto_objetivo': 10000000,
    'monto_actual': 10000000,
    'moneda': 'ARS',
    'fecha_creacion': _ms(2026, 8, 1),
  });
  await db.insert('metas', {
    'id': metaAuto,
    'nombre': 'Auto',
    'icono': 'directions_car',
    'monto_objetivo': 1000000000,
    'monto_actual': 0,
    'moneda': 'ARS',
    'fecha_creacion': _ms(2026, 9, 1),
  });

  // Agosto 2026
  await _mov(db, 1, 80000000, _ms(2026, 8, 1), 'ingreso', cat: idSueldo, desc: 'Sueldo');
  await _mov(db, 2, 4550050, _ms(2026, 8, 3), 'gasto', cat: idAlimentacion, desc: 'Super');
  await _mov(db, 3, 30000000, _ms(2026, 8, 5), 'gasto', cat: idVivienda, desc: 'Alquiler');
  await _mov(db, 4, 5000000, _ms(2026, 8, 10), 'ahorro',
      desc: 'Ahorro: Vacaciones', meta: metaVacaciones, montoMeta: 5000000);
  await _mov(db, 5, 20000000, _ms(2026, 8, 12), 'ahorro',
      desc: 'Ahorro: Viaje', meta: metaViaje, montoMeta: 20000);
  // Gasto a las 23:30 del último día del mes (borde de fecha local).
  await _mov(db, 6, 1200000, _ms(2026, 8, 31, 23, 30), 'gasto', cat: idTransporte, desc: 'Uber');

  // Septiembre 2026
  await _mov(db, 7, 80000000, _ms(2026, 9, 1), 'ingreso', cat: idSueldo, desc: 'Sueldo');
  await _mov(db, 8, 30000000, _ms(2026, 9, 5), 'gasto', cat: idVivienda, desc: 'Alquiler');
  await _mov(db, 9, 5000000, _ms(2026, 9, 10), 'gasto', cat: idDeudas, desc: 'Heladera (cuota 2/6)');
  await _mov(db, 10, 4000000, _ms(2026, 9, 15), 'ahorro',
      desc: 'Ahorro: Vacaciones', meta: metaVacaciones, montoMeta: 4000000);
  await _mov(db, 11, 10000000, _ms(2026, 9, 20), 'ahorro',
      desc: 'Ahorro: Fondo de emergencia', meta: metaFondo, montoMeta: 10000000);
  await _mov(db, 12, 800000, _ms(2026, 9, 15), 'gasto', cat: idServicios, desc: 'Netflix');
  await _mov(db, 13, 2500000, _ms(2026, 9, 25), 'gasto', cat: idGimnasio, desc: 'Cuota gimnasio');

  // Octubre 2026
  await _mov(db, 14, 85000000, _ms(2026, 10, 1), 'ingreso', cat: idSueldo, desc: 'Sueldo');
  await _mov(db, 15, 30000000, _ms(2026, 10, 5), 'gasto', cat: idVivienda, desc: 'Alquiler');
  // Doble toque en "Confirmar": el mismo alquiler dos veces.
  await _mov(db, 16, 30000000, _ms(2026, 10, 5), 'gasto', cat: idVivienda, desc: 'Alquiler');
  await _mov(db, 17, 5000000, _ms(2026, 10, 10), 'gasto', cat: idDeudas, desc: 'Heladera (cuota 3/6)');
  await _mov(db, 18, 1500000, _ms(2026, 10, 20), 'ingreso', cat: idHorasExtras, desc: '3 horas extra');
  await _mov(db, 19, 9000000, _ms(2026, 10, 2), 'gasto', cat: idDeudas, desc: 'Cuotas: Celular (x3)');
  await _mov(db, 20, 3000000, _ms(2026, 10, 31, 23, 59), 'gasto', cat: idAlimentacion, desc: 'Cena');

  await db.insert('gastos_fijos', {
    'id': 1, 'nombre': 'Alquiler', 'monto': 30000000, 'categoria_id': idVivienda,
    'dia_debito': 5, 'activo': 1,
  });
  await db.insert('gastos_fijos', {
    'id': 2, 'nombre': 'Netflix', 'monto': 800000, 'categoria_id': idServicios,
    'dia_debito': 15, 'activo': 1,
  });
  await db.insert('gastos_fijos', {
    'id': 3, 'nombre': 'Gas', 'monto': 1200000, 'categoria_id': null,
    'dia_debito': 20, 'activo': 0,
  });

  await db.insert('cuotas', {
    'id': 1, 'nombre': 'Heladera', 'monto_cuota': 5000000, 'categoria_id': idDeudas,
    'total_cuotas': 6, 'cuotas_pagadas': 3, 'dia_debito': 10, 'activo': 1,
  });
  await db.insert('cuotas', {
    'id': 2, 'nombre': 'Celular', 'monto_cuota': 3000000, 'categoria_id': idDeudas,
    'total_cuotas': 3, 'cuotas_pagadas': 3, 'dia_debito': 2, 'activo': 0,
  });
  await db.insert('cuotas', {
    'id': 3, 'nombre': 'Notebook', 'monto_cuota': 10000000, 'categoria_id': null,
    'total_cuotas': 12, 'cuotas_pagadas': 0, 'dia_debito': 15, 'activo': 1,
  });

  await _rec(db, 'sueldo', 0, '2026-09', 7);
  await _rec(db, 'sueldo', 0, '2026-10', 14);
  await _rec(db, 'fijo', 1, '2026-09', 8);
  await _rec(db, 'fijo', 1, '2026-10', 15);
  await _rec(db, 'fijo', 1, '2026-10', 16); // duplicado del doble toque
  await _rec(db, 'fijo', 2, '2026-09', 12);
  await _rec(db, 'fijo', 2, '2026-10', 999); // su movimiento se borró
  await _rec(db, 'cuota', 1, '2026-09', 9);
  await _rec(db, 'cuota', 1, '2026-10', 17);
  await _rec(db, 'cuota', 2, '2026-10', 19);
  await _rec(db, 'cuota', 2, '2026-11', 19);
  await _rec(db, 'cuota', 2, '2026-12', 19);
  await _rec(db, 'horasextras', 0, '2026-10', 18);
  await _rec(db, 'resumen', 0, '2026-09', null);
  await _rec(db, 'saldoanterior', 0, '2026-10', null);
}

/// Inicializa sqflite con FFI (una vez por proceso de test).
void inicializarSqfliteFfi() {
  sqfliteFfiInit();
}

/// Abre (o crea) una base v8 con los datos sintéticos.
///
/// Con [ruta] null usa una base en memoria.
Future<Database> abrirBaseV8({String? ruta}) async {
  inicializarSqfliteFfi();
  return databaseFactoryFfi.openDatabase(
    ruta ?? inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 8,
      singleInstance: false,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await crearEsquemaV8(db);
        await sembrarDatosV8(db);
      },
    ),
  );
}
