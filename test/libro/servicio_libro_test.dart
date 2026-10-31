import 'package:finanzas/core/base_de_datos/esquema.dart';
import 'package:finanzas/core/dinero/dinero.dart';
import 'package:finanzas/core/libro/consultas_libro.dart';
import 'package:finanzas/core/libro/modelo/movimiento.dart';
import 'package:finanzas/core/libro/servicio_libro.dart';
import 'package:finanzas/core/utilidades/fechas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../soporte/base_v9.dart';

Dinero pesos(num p) => Dinero.desdeUnidades(p);
Dinero dolares(num d) => Dinero.desdeUnidades(d, Moneda.usd);

void main() {
  late Database db;
  late ConsultasLibro consultas;
  final septiembre = DateTime(2026, 9, 10);
  final octubre = DateTime(2026, 10, 10);

  Future<T> libro<T>(Future<T> Function(ServicioLibro l) accion) => ServicioLibro.transaccion(db, accion);

  Future<int> crearMeta(String nombre, Dinero objetivo) => libro(
      (l) => l.crearMeta(nombre: nombre, icono: 'flag', objetivo: objetivo, fecha: septiembre));

  Future<Dinero> saldoMeta(int metaId) async =>
      (await consultas.metas()).firstWhere((m) => m.id == metaId).saldo;

  setUp(() async {
    db = await abrirBaseNueva();
    consultas = ConsultasLibro(db);
    final sueldo = await idCategoria(db, 'Sueldo');
    await libro((l) => l.registrar(
        tipo: TipoMovimiento.ingreso, monto: pesos(500000), categoriaId: sueldo, fecha: septiembre));
  });

  tearDown(() => db.close());

  group('ingresos y gastos', () {
    test('un gasto baja el disponible y puede dejarlo negativo', () async {
      final super_ = await idCategoria(db, 'Alimentación');
      await libro((l) => l.registrar(
          tipo: TipoMovimiento.gasto, monto: pesos(600000), categoriaId: super_, fecha: septiembre));
      expect(await consultas.disponible(), pesos(-100000));
    });

    test('rechaza una categoría del otro tipo', () async {
      final sueldo = await idCategoria(db, 'Sueldo');
      expect(
        libro((l) => l.registrar(tipo: TipoMovimiento.gasto, monto: pesos(1), categoriaId: sueldo, fecha: septiembre)),
        throwsA(isA<ErrorLibro>()),
      );
    });
  });

  group('metas', () {
    test('aportar mueve plata del disponible a la meta', () async {
      final meta = await crearMeta('Vacaciones', pesos(300000));
      await libro((l) => l.aportarAMeta(meta, pesos(100000), fecha: septiembre));
      expect(await consultas.disponible(), pesos(400000));
      expect(await saldoMeta(meta), pesos(100000));
    });

    test('no se puede aportar más de lo disponible ni pasar el objetivo', () async {
      final meta = await crearMeta('Auto', pesos(10000000));
      await expectLater(libro((l) => l.aportarAMeta(meta, pesos(600000), fecha: septiembre)),
          throwsA(isA<ErrorLibro>()));
      final chica = await crearMeta('Regalo', pesos(50000));
      await expectLater(libro((l) => l.aportarAMeta(chica, pesos(60000), fecha: septiembre)),
          throwsA(isA<ErrorLibro>().having((e) => e.mensaje, 'mensaje', contains(r'$50.000'))));
      expect(await consultas.disponible(), pesos(500000));
    });

    test('una meta en dólares guarda dólares y el disponible no depende del blue', () async {
      final meta = await crearMeta('Viaje', dolares(2000));
      await libro((l) => l.aportarAMeta(meta, pesos(100000), cotizacion: 1000, fecha: septiembre));
      expect(await saldoMeta(meta), dolares(100));
      expect(await consultas.disponible(), pesos(400000));
      // El disponible es un saldo del libro: ninguna cotización entra en la cuenta.
      expect(await consultas.disponible(), pesos(400000));
    });

    test('retirar registra un retiro y no reescribe el historial', () async {
      final meta = await crearMeta('Vacaciones', pesos(300000));
      await libro((l) => l.aportarAMeta(meta, pesos(100000), fecha: septiembre));
      final septiembreAntes = await consultas.totalesMes(const Periodo(2026, 9));

      await libro((l) => l.retirarDeMeta(meta, pesos(70000), fecha: octubre));

      expect(await saldoMeta(meta), pesos(30000));
      expect(await consultas.disponible(), pesos(470000));
      final septiembreDespues = await consultas.totalesMes(const Periodo(2026, 9));
      expect(septiembreDespues.aportadoAMetas, septiembreAntes.aportadoAMetas);
      expect((await consultas.totalesMes(const Periodo(2026, 10))).aportadoAMetas, pesos(-70000));
      final transferencias = await consultas.movimientos(filtro: FiltroMovimientos.metas);
      expect(transferencias.map((m) => m.monto), [pesos(70000), pesos(100000)]);
    });

    test('mover entre metas valida el saldo del origen y no deja nada a medias', () async {
      final origen = await crearMeta('A', pesos(300000));
      final destino = await crearMeta('B', pesos(300000));
      await libro((l) => l.aportarAMeta(origen, pesos(50000), fecha: septiembre));

      await expectLater(libro((l) => l.moverEntreMetas(origen, destino, pesos(80000), fecha: octubre)),
          throwsA(isA<ErrorLibro>()));
      expect(await saldoMeta(origen), pesos(50000));
      expect(await saldoMeta(destino), pesos(0));

      await libro((l) => l.moverEntreMetas(origen, destino, pesos(50000), fecha: octubre));
      expect(await saldoMeta(origen), pesos(0));
      expect(await saldoMeta(destino), pesos(50000));
      expect(await consultas.disponible(), pesos(450000));
    });

    test('mover de una meta en pesos a una en dólares convierte', () async {
      final origen = await crearMeta('Pesos', pesos(300000));
      final destino = await crearMeta('Dólares', dolares(1000));
      await libro((l) => l.aportarAMeta(origen, pesos(125000), fecha: septiembre));
      await libro((l) => l.moverEntreMetas(origen, destino, pesos(125000), cotizacion: 1250, fecha: octubre));
      expect(await saldoMeta(destino), dolares(100));
    });

    test('eliminar una meta devuelve su plata y archiva la cuenta', () async {
      final meta = await crearMeta('Vacaciones', pesos(300000));
      await libro((l) => l.aportarAMeta(meta, pesos(100000), fecha: septiembre));
      await libro((l) => l.eliminarMeta(meta, fecha: octubre));
      expect(await consultas.metas(), isEmpty);
      expect(await consultas.disponible(), pesos(500000));
      final cuentas = await consultas.cuentas();
      expect(cuentas.where((c) => c.esMeta).single.archivada, isTrue);
      expect(await consultas.movimientos(filtro: FiltroMovimientos.metas), hasLength(2));
    });

    test('no se puede borrar un aporte cuya plata ya salió de la meta', () async {
      final a = await crearMeta('A', pesos(300000));
      final b = await crearMeta('B', pesos(300000));
      final aporte = await libro((l) => l.aportarAMeta(a, pesos(50000), fecha: septiembre));
      await libro((l) => l.moverEntreMetas(a, b, pesos(50000), fecha: octubre));
      await expectLater(libro((l) => l.eliminar(aporte)), throwsA(isA<ErrorLibro>()));
      expect(await consultas.movimientos(filtro: FiltroMovimientos.metas), hasLength(2));
    });
  });

  group('transferencias', () {
    test('rechaza misma cuenta y conversiones faltantes', () async {
      await expectLater(
        libro((l) => l.transferir(origenId: 1, destinoId: 1, monto: pesos(1), fecha: octubre)),
        throwsA(isA<ErrorLibro>()),
      );
      await expectLater(
        libro((l) => l.transferir(
            origenId: Esquema.cuentaLibreArs, destinoId: Esquema.cuentaDolares, monto: pesos(1000), fecha: octubre)),
        throwsA(isA<ErrorLibro>()),
      );
    });
  });

  test('el ahorro previo es un saldo inicial que se puede corregir', () async {
    await libro((l) => l.fijarSaldoInicial(Esquema.cuentaLibreArs, pesos(150000), fecha: septiembre));
    await libro((l) => l.fijarSaldoInicial(Esquema.cuentaLibreArs, pesos(120000), fecha: septiembre));
    expect(await consultas.disponible(), pesos(620000));
    await libro((l) => l.fijarSaldoInicial(Esquema.cuentaDolares, dolares(500), fecha: septiembre));
    expect((await consultas.saldos())[Esquema.cuentaDolares], dolares(500));
    // El ahorro previo no cuenta como ingreso del mes.
    expect((await consultas.totalesMes(const Periodo(2026, 9))).ingresos, pesos(500000));
  });
}
