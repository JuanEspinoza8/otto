import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base_de_datos/gestor_base_datos.dart';
import '../../../core/base_de_datos/migracion_v9.dart';
import '../../../core/libro/libro_providers.dart';
import '../../recurrentes/logica/servicio_planes.dart';
import '../../recurrentes/modelo/plan.dart';
import '../repositorio/ajustes_repositorio.dart';
import 'servicio_notificaciones.dart';
import 'servicio_respaldo.dart';

part 'respaldo_provider.g.dart';

/// Un respaldo leído y validado, listo para restaurar.
class RespaldoElegido {
  const RespaldoElegido({required this.datos, required this.movimientosActuales});

  final Map<String, List<Map<String, Object?>>> datos;
  final int movimientosActuales;

  int get movimientos => datos['movimientos']!.length;
  int get metas => datos['metas']!.length;
  int get planes => datos['planes']!.length;
}

/// Exportar e importar el respaldo desde Configuración. Se mantiene vivo
/// mientras el usuario confirma la importación.
@Riverpod(keepAlive: true)
class RespaldoControlador extends _$RespaldoControlador {
  @override
  void build() {}

  /// Comparte el respaldo y después borra el archivo temporal (los datos no
  /// quedan en claro en la caché).
  Future<void> exportar() async {
    final db = await ref.read(baseDatosProvider.future);
    final contenido = jsonEncode(await ServicioRespaldo.armar(db));
    final directorio = await getTemporaryDirectory();
    final archivo = File(p.join(directorio.path, 'Otto_respaldo_${DateTime.now().millisecondsSinceEpoch}.json'));
    await archivo.writeAsString(contenido);
    try {
      await Share.shareXFiles([XFile(archivo.path)], text: 'Respaldo de Otto');
    } finally {
      if (await archivo.exists()) await archivo.delete();
    }
  }

  /// Elige un archivo, lo valida (y si es de la versión anterior lo
  /// convierte) sin tocar los datos. Null si se canceló.
  Future<RespaldoElegido?> elegir() async {
    final elegido = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    final ruta = elegido?.files.single.path;
    if (ruta == null) return null;

    final db = await ref.read(baseDatosProvider.future);
    final temporal = Directory(p.join((await getTemporaryDirectory()).path, 'importacion'));
    await temporal.create(recursive: true);

    final datos = await ServicioRespaldo.leer(
      await File(ruta).readAsString(),
      convertirV8: (v8) async {
        final sueldo = await ServicioPlanes(db).sueldo();
        final valorHora = await AjustesRepositorio(db).valorHoraExtra();
        return ServicioRespaldo.convertirV8(
          v8,
          rutaTemporal: p.join(temporal.path, 'respaldo_v8.db'),
          datos: DatosMigracion(
            salarioMensual: sueldo?.monto.unidades ?? 0,
            valorHoraExtra: valorHora.unidades,
            cotizacionUsd: null,
            ahora: DateTime.now(),
          ),
        );
      },
    );
    final actuales = await db.rawQuery('SELECT COUNT(*) AS n FROM movimientos');
    return RespaldoElegido(datos: datos, movimientosActuales: actuales.first['n'] as int);
  }

  /// Reemplaza los datos por los del respaldo. Antes guarda una copia con
  /// fecha de la base actual (no pisa copias anteriores).
  Future<void> restaurar(RespaldoElegido respaldo) async {
    final db = await ref.read(baseDatosProvider.future);
    // Si la base usa WAL, el checkpoint pasa todo al archivo principal antes
    // de copiarlo; en modo journal no hace nada.
    await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    final actual = File(await GestorBaseDatos.instancia.rutaArchivo());
    if (await actual.exists()) {
      final marca = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      await actual.copy(p.join(actual.parent.path, 'finanzas_antes_de_importar_$marca.db'));
    }

    await ServicioRespaldo.restaurar(db, respaldo.datos);
    ref.read(versionDatosProvider.notifier).cambiaron();
    try {
      await ServicioNotificaciones.reprogramarFijos(await ServicioPlanes(db).planes(tipo: TipoPlan.fijo));
    } catch (_) {/* un fallo de notificaciones no invalida la importación */}
  }
}
