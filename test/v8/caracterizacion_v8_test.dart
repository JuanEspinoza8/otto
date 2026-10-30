// Tests de caracterización: fijan cómo calcula la app v8 los totales del mes
// y el disponible, antes de cambiar el modelo de dinero.
import 'package:finanzas/core/base_de_datos/gestor_base_datos.dart';
import 'package:finanzas/features/movimientos/repositorio/movimiento_repositorio.dart';
import 'package:finanzas/features/panel_control/logica/ahorro_disponible_provider.dart';
import 'package:finanzas/features/panel_control/logica/ahorros_provider.dart';
import 'package:finanzas/features/panel_control/logica/dashboard_provider.dart';
import 'package:finanzas/features/panel_control/logica/dolar_blue_provider.dart';
import 'package:finanzas/features/panel_control/logica/metas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../soporte/base_v8.dart';

class _BlueFijo extends DolarBlue {
  _BlueFijo(this.venta);
  final double venta;

  @override
  Future<Map<String, double>?> build() async => {'compra': venta, 'venta': venta};
}

Future<double> _disponibleConBlue(double blue) async {
  final contenedor = ProviderContainer(overrides: [
    dolarBlueProvider.overrideWith(() => _BlueFijo(blue)),
  ]);
  addTearDown(contenedor.dispose);
  contenedor.listen(ahorroDisponibleProvider, (_, __) {});
  await contenedor.read(ahorrosControladorProvider.future);
  await contenedor.read(totalesGlobalesProvider.future);
  await contenedor.read(metasControladorProvider.future);
  await contenedor.read(dolarBlueProvider.future);
  return contenedor.read(ahorroDisponibleProvider);
}

void main() {
  late Database db;

  setUp(() async {
    db = await abrirBaseV8();
    GestorBaseDatos.usarBaseDePrueba(db);
  });

  tearDown(() async {
    GestorBaseDatos.usarBaseDePrueba(null);
    await db.close();
  });

  group('totales del mes (v8)', () {
    final repo = MovimientoRepositorio();

    test('agosto: incluye el gasto de las 23:30 del día 31', () async {
      final t = await repo.obtenerTotalesMes(DateTime(2026, 8));
      expect(t['ingresos'], 800000);
      expect(t['gastos'], closeTo(45500.50 + 300000 + 12000, 0.001));
      expect(t['ahorros'], 250000);
      expect(t['cantGastos'], 3);
    });

    test('septiembre', () async {
      final t = await repo.obtenerTotalesMes(DateTime(2026, 9));
      expect(t['ingresos'], 800000);
      expect(t['gastos'], 300000 + 50000 + 8000 + 25000);
      expect(t['ahorros'], 140000);
    });

    test('octubre: el alquiler duplicado cuenta dos veces', () async {
      final t = await repo.obtenerTotalesMes(DateTime(2026, 10));
      expect(t['ingresos'], 850000 + 15000);
      expect(t['gastos'], 300000 * 2 + 50000 + 90000 + 30000);
      expect(t['ahorros'], 0);
    });

    test('totales históricos', () async {
      final t = await repo.obtenerTotalesGlobales();
      expect(t['ingresos'], 2465000);
      expect(t['gastos'], closeTo(1510500.50, 0.001));
      expect(t['ahorros'], 390000);
    });
  });

  group('disponible (v8)', () {
    // disponible = ahorro previo ARS + US$ previo × blue + ingresos − gastos
    //              − metas ARS − metas USD × blue
    //            = 884.499,50 + 200 × blue
    test('con el blue a 1.000', () async {
      expect(await _disponibleConBlue(1000), closeTo(1084499.50, 0.001));
    });

    test('se mueve con el blue sin que haya ningún movimiento (bug de v8)', () async {
      expect(await _disponibleConBlue(1250), closeTo(1134499.50, 0.001));
    });
  });
}
