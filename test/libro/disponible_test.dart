import 'dart:io';

import 'package:finanzas/core/base_de_datos/gestor_base_datos.dart';
import 'package:finanzas/core/base_de_datos/migracion_v9.dart';
import 'package:finanzas/core/dinero/dinero.dart';
import 'package:finanzas/core/libro/libro_providers.dart';
import 'package:finanzas/features/panel_control/logica/dolar_blue_provider.dart';
import 'package:finanzas/features/panel_control/logica/metas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../soporte/base_v8.dart';

class _BlueFijo extends DolarBlue {
  _BlueFijo(this.venta);
  final double venta;

  @override
  Future<Cotizacion?> build() async => Cotizacion(compra: venta, venta: venta);
}

void main() {
  late Directory directorio;
  late Database db;

  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('otto_disponible_');
    final ruta = p.join(directorio.path, GestorBaseDatos.nombreArchivo);
    await (await abrirBaseV8(ruta: ruta)).close();
    db = await GestorBaseDatos.abrir(
      ruta,
      fabrica: databaseFactoryFfi,
      datos: DatosMigracion(salarioMensual: salarioV8, cotizacionUsd: 1000, ahora: DateTime(2026, 10, 30)),
    );
  });

  tearDown(() async {
    await db.close();
    await directorio.delete(recursive: true);
  });

  ProviderContainer contenedor(double blue) {
    final c = ProviderContainer(overrides: [
      baseDatosProvider.overrideWith((ref) async => db),
      dolarBlueProvider.overrideWith(() => _BlueFijo(blue)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('el disponible no cambia cuando cambia el blue', () async {
    for (final blue in [1000.0, 1250.0, 0.0]) {
      final c = contenedor(blue);
      expect(await c.read(disponibleProvider.future), const Dinero(58449950), reason: 'blue $blue');
    }
  });

  test('los dólares se muestran aparte, estimados al blue', () async {
    final c = contenedor(1250);
    c.listen(patrimonioDolaresProvider, (_, __) {});
    await c.read(dolarBlueProvider.future);
    final dolares = await c.read(patrimonioDolaresProvider.future);
    expect(dolares.libres, const Dinero(50000, Moneda.usd));
    expect(dolares.enMetas, const Dinero(30000, Moneda.usd));
    expect(dolares.enPesos(1250), Dinero.desdeUnidades(800 * 1250));
  });
}
