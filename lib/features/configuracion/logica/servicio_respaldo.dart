import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../../core/base_de_datos/esquema.dart';
import '../../../core/base_de_datos/esquema_v8.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../../../core/base_de_datos/migracion_v9.dart';

/// El archivo no se puede importar. El mensaje se muestra al usuario.
class ErrorRespaldo implements Exception {
  const ErrorRespaldo(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Respaldo en JSON de todos los datos.
///
/// Formato 2 (`schema_version` 9): `{"app": "otto", "formato": 2,
/// "schema_version": 9, "tablas": {...}}` con todas las tablas del libro,
/// incluidos los planes (sueldo) y los ajustes (valor de la hora extra).
/// Los respaldos viejos (formato 3 de la v8) se convierten pasando por la
/// misma migración que la base del teléfono.
class ServicioRespaldo {
  static const int formato = 2;

  /// Tablas del respaldo, en orden de inserción (respeta las claves foráneas).
  static const List<String> tablas = [
    'categorias',
    'cuentas',
    'metas',
    'movimientos',
    'planes',
    'plan_aplicaciones',
    'avisos_mes',
    'ajustes',
  ];

  /// Columnas que tiene que tener cada fila (las demás son opcionales).
  static const Map<String, List<String>> _obligatorias = {
    'categorias': ['id', 'nombre', 'tipo', 'color_hex', 'icono'],
    'cuentas': ['id', 'nombre', 'moneda', 'tipo'],
    'metas': ['id', 'cuenta_id', 'monto_objetivo', 'fecha_creacion'],
    'movimientos': ['id', 'fecha', 'creado_en', 'tipo', 'monto_centavos', 'cuenta_id'],
    'planes': ['id', 'tipo', 'nombre', 'monto_centavos', 'primer_periodo'],
    'plan_aplicaciones': ['plan_id', 'periodo'],
    'avisos_mes': ['clave', 'periodo'],
    'ajustes': ['clave', 'valor'],
  };

  static Future<Map<String, Object?>> armar(DatabaseExecutor db) async => {
        'app': 'otto',
        'formato': formato,
        'schema_version': Esquema.version,
        'exportado_en': DateTime.now().toIso8601String(),
        'tablas': {for (final t in tablas) t: await db.query(t)},
      };

  /// Interpreta el texto de un archivo. Devuelve las tablas en formato v9
  /// (convirtiendo un respaldo viejo si hace falta) o lanza [ErrorRespaldo].
  static Future<Map<String, List<Map<String, Object?>>>> leer(
    String texto, {
    required Future<Map<String, List<Map<String, Object?>>>> Function(Map<String, Object?> v8) convertirV8,
  }) async {
    final Object? json;
    try {
      json = jsonDecode(texto);
    } on FormatException {
      throw const ErrorRespaldo('El archivo no es un respaldo válido');
    }
    if (json is! Map<String, Object?>) throw const ErrorRespaldo('El archivo no es un respaldo válido');

    if (json['formato'] == formato) {
      if (json['schema_version'] != Esquema.version) {
        throw const ErrorRespaldo('El respaldo es de otra versión de la app');
      }
      return validar(json['tablas']);
    }
    if (json['version'] == 3) {
      for (final t in ['categorias', 'movimientos']) {
        if (json[t] is! List) throw const ErrorRespaldo('El respaldo está incompleto');
      }
      return validar(await convertirV8(json));
    }
    throw const ErrorRespaldo('El archivo no es un respaldo de Otto');
  }

  /// Comprueba que estén todas las tablas, como listas de filas con sus
  /// columnas obligatorias. Los tipos de cada valor los vuelve a controlar
  /// la base al insertar (CHECK y claves foráneas).
  static Map<String, List<Map<String, Object?>>> validar(Object? crudo) {
    if (crudo is! Map) throw const ErrorRespaldo('El respaldo está incompleto');
    final resultado = <String, List<Map<String, Object?>>>{};
    for (final tabla in tablas) {
      final filas = crudo[tabla];
      if (filas is! List) throw ErrorRespaldo('Al respaldo le falta "$tabla"');
      resultado[tabla] = [
        for (final fila in filas)
          if (fila is Map && _obligatorias[tabla]!.every(fila.containsKey))
            {for (final e in fila.entries) '${e.key}': _valor(e.value, tabla)}
          else
            throw ErrorRespaldo('Hay una fila inválida en "$tabla"'),
      ];
    }
    if (resultado['cuentas']!.every((c) => c['id'] != Esquema.cuentaLibreArs)) {
      throw const ErrorRespaldo('Al respaldo le falta la cuenta principal');
    }
    return resultado;
  }

  static Object? _valor(Object? v, String tabla) {
    if (v == null || v is int || v is String) return v;
    if (v is double && v == v.roundToDouble()) return v.toInt();
    throw ErrorRespaldo('Hay un valor inválido en "$tabla"');
  }

  /// Reemplaza todos los datos por los del respaldo, en una sola transacción:
  /// si algo no entra (tipos, CHECK o referencias rotas) no cambia nada.
  static Future<void> restaurar(Database db, Map<String, List<Map<String, Object?>>> datos) async {
    await db.transaction((txn) async {
      await txn.execute('PRAGMA defer_foreign_keys = ON');
      for (final t in tablas.reversed) {
        await txn.delete(t);
      }
      for (final t in tablas) {
        final columnas = await _columnas(txn, t);
        for (final fila in datos[t]!) {
          await txn.insert(t, {
            for (final e in fila.entries)
              if (columnas.contains(e.key)) e.key: e.value,
          });
        }
      }
      final rotas = await txn.rawQuery('PRAGMA foreign_key_check');
      if (rotas.isNotEmpty) throw const ErrorRespaldo('El respaldo tiene referencias rotas');
    });
  }

  /// Convierte un respaldo v8 (formato 3): lo carga en una base v8 temporal
  /// en [rutaTemporal], la migra con [MigradorV9] y devuelve sus tablas.
  static Future<Map<String, List<Map<String, Object?>>>> convertirV8(
    Map<String, Object?> v8, {
    required String rutaTemporal,
    required DatosMigracion datos,
    DatabaseFactory? fabrica,
  }) async {
    final f = fabrica ?? databaseFactory;
    await f.deleteDatabase(rutaTemporal);
    try {
      final base = await f.openDatabase(
        rutaTemporal,
        options: OpenDatabaseOptions(
          version: EsquemaV8.version,
          singleInstance: false,
          onCreate: (db, _) => EsquemaV8.crear(db),
        ),
      );
      await base.transaction((txn) async {
        for (final t in EsquemaV8.tablas) {
          final filas = v8[t];
          if (filas is! List) continue;
          final columnas = await _columnas(txn, t);
          for (final fila in filas) {
            if (fila is! Map) throw ErrorRespaldo('Hay una fila inválida en "$t"');
            await txn.insert(t, {
              for (final e in fila.entries)
                if (columnas.contains(e.key)) '${e.key}': e.value,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });
      await base.close();

      final migrada = await GestorBaseDatos.abrir(rutaTemporal, fabrica: f, datos: datos);
      try {
        return {for (final t in tablas) t: await migrada.query(t)};
      } finally {
        await migrada.close();
      }
    } on DatabaseException {
      throw const ErrorRespaldo('El respaldo viejo tiene datos inválidos');
    } on ErrorMigracion {
      throw const ErrorRespaldo('El respaldo viejo no se pudo convertir sin perder datos');
    } finally {
      await f.deleteDatabase(rutaTemporal);
      final respaldoTemporal = File('${File(rutaTemporal).parent.path}/${GestorBaseDatos.nombreRespaldoV8}');
      if (await respaldoTemporal.exists()) await respaldoTemporal.delete();
    }
  }

  static Future<Set<String>> _columnas(DatabaseExecutor db, String tabla) async {
    final info = await db.rawQuery('PRAGMA table_info($tabla)');
    return info.map((c) => c['name'] as String).toSet();
  }
}
