import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../panel_control/logica/metas_provider.dart';
import '../../panel_control/logica/ahorros_provider.dart';
import '../../recurrentes/logica/cuotas_provider.dart';
import '../../recurrentes/logica/gastos_fijos_provider.dart';

class ServicioRespaldo {
  /// Tablas incluidas en el respaldo, en orden seguro de inserción (respeta FKs).
  static const List<String> _tablas = [
    'categorias',
    'metas',
    'submetas',
    'cuotas',
    'gastos_fijos',
    'ahorros_acumulados',
    'movimientos',
    'recurrencias_aplicadas',
  ];

  static Future<bool> exportarAJSON() async {
    try {
      final db = await GestorBaseDatos.instancia.obtenerBaseDatos();

      final Map<String, dynamic> backup = {
        'version': 3,
        'fecha_exportacion': DateTime.now().toIso8601String(),
      };
      for (final t in _tablas) {
        backup[t] = await db.query(t);
      }

      final jsonStr = jsonEncode(backup);
      final directorio = await getTemporaryDirectory();
      final rutaArchivo = '${directorio.path}/Otto_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final archivo = File(rutaArchivo);
      await archivo.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(rutaArchivo)], text: 'Respaldo de Otto');
      return true;
    } catch (e) {
      debugPrint('Error al exportar: $e');
      return false;
    }
  }

  static Future<bool> importarDeJSON(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return false;

      final archivo = File(result.files.single.path!);
      final backup = jsonDecode(await archivo.readAsString()) as Map<String, dynamic>;

      // Debe tener al menos categorías y movimientos para ser válido.
      if (!backup.containsKey('categorias') || !backup.containsKey('movimientos')) {
        return false;
      }

      final db = await GestorBaseDatos.instancia.obtenerBaseDatos();
      await db.transaction((txn) async {
        // Vaciar en orden inverso para respetar las claves foráneas.
        for (final t in _tablas.reversed) {
          await txn.delete(t);
        }
        // Insertar en orden, tolerando diferencias de versión: sólo se copian
        // las columnas que existen HOY en cada tabla. Así un respaldo viejo (sin
        // columnas nuevas) o uno más nuevo (con columnas que ya no están) se
        // importa igual, sin romper.
        for (final t in _tablas) {
          final filas = backup[t];
          if (filas is! List) continue;
          final columnas = await _columnasDe(txn, t);
          if (columnas.isEmpty) continue;
          for (final fila in filas) {
            final original = Map<String, dynamic>.from(fila as Map);
            final limpia = <String, dynamic>{
              for (final entry in original.entries)
                if (columnas.contains(entry.key)) entry.key: entry.value,
            };
            if (limpia.isEmpty) continue;
            await txn.insert(t, limpia, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });

      // Refrescar todos los providers afectados.
      ref.invalidate(categoriasControladorProvider);
      ref.invalidate(movimientosControladorProvider);
      ref.invalidate(metasControladorProvider);
      ref.invalidate(ahorrosControladorProvider);
      ref.invalidate(cuotasControladorProvider);
      ref.invalidate(gastosFijosControladorProvider);

      return true;
    } catch (e) {
      debugPrint('Error al importar: $e');
      return false;
    }
  }

  /// Nombres de columnas que la tabla tiene en el esquema actual.
  static Future<Set<String>> _columnasDe(DatabaseExecutor db, String tabla) async {
    final info = await db.rawQuery('PRAGMA table_info($tabla)');
    return info.map((c) => c['name'] as String).toSet();
  }
}
