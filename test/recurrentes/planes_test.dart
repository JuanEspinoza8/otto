import 'package:finanzas/core/dinero/dinero.dart';
import 'package:finanzas/core/libro/consultas_libro.dart';
import 'package:finanzas/core/libro/servicio_libro.dart';
import 'package:finanzas/core/utilidades/fechas.dart';
import 'package:finanzas/features/recurrentes/logica/servicio_planes.dart';
import 'package:finanzas/features/recurrentes/modelo/plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../soporte/base_v9.dart';

Dinero pesos(num p) => Dinero.desdeUnidades(p);

void main() {
  late Database db;

  Future<T> planes<T>(Future<T> Function(ServicioPlanes p) accion) => ServicioPlanes.transaccion(db, accion);

  Future<int> crearFijo({Periodo primer = const Periodo(2026, 10), int dia = 5}) async {
    final vivienda = await idCategoria(db, 'Vivienda');
    return planes((p) => p.crear(Plan(
          tipo: TipoPlan.fijo,
          nombre: 'Alquiler',
          categoriaId: vivienda,
          monto: pesos(300000),
          primerPeriodo: primer,
          diaDebito: dia,
        )));
  }

  Future<int> crearCuotas(Dinero total, int n, {Periodo primer = const Periodo(2026, 10)}) =>
      planes((p) => p.crear(Plan(
            tipo: TipoPlan.cuotas,
            nombre: 'Heladera',
            monto: Plan.cuotaBase(total, n),
            total: total,
            totalCuotas: n,
            primerPeriodo: primer,
            diaDebito: 10,
          )));

  Future<Plan> leer(int id) => ServicioPlanes(db).plan(id);

  Future<int> contarGastos() async =>
      (await ConsultasLibro(db).totalesMes(const Periodo(2026, 10))).cantidadGastos +
      (await ConsultasLibro(db).totalesMes(const Periodo(2026, 11))).cantidadGastos;

  setUp(() async => db = await abrirBaseNueva());
  tearDown(() => db.close());

  test('dos confirmaciones simultáneas dejan una sola aplicación y un solo gasto', () async {
    final id = await crearFijo();
    final resultados = await Future.wait([
      planes((p) => p.confirmar(id, const Periodo(2026, 10))),
      planes((p) => p.confirmar(id, const Periodo(2026, 10))),
    ]);
    expect(resultados.where((r) => r), hasLength(1));
    expect((await leer(id)).periodosAplicados, {const Periodo(2026, 10)});
    expect(await contarGastos(), 1);
  });

  test('borrar el gasto generado libera el período', () async {
    final id = await crearFijo();
    await planes((p) => p.confirmar(id, const Periodo(2026, 10)));
    final gasto = (await ConsultasLibro(db).movimientos()).single;
    await ServicioLibro.transaccion(db, (l) => l.eliminar(gasto.id!));
    expect((await leer(id)).periodosAplicados, isEmpty);
    expect(await planes((p) => p.confirmar(id, const Periodo(2026, 10))), isTrue);
  });

  group('pendientes', () {
    test('una compra de octubre no aparece en septiembre', () async {
      final id = await crearCuotas(pesos(90000), 3);
      final plan = await leer(id);
      final hoy = DateTime(2026, 10, 20);
      expect(calcularPendientes([plan], const Periodo(2026, 9), hoy), isEmpty);
      final octubre = calcularPendientes([plan], const Periodo(2026, 10), hoy).single;
      expect(octubre.descripcion, 'Heladera (cuota 1/3)');
    });

    test('en el mes actual aparece recién desde el día de débito', () async {
      final plan = await leer(await crearFijo(dia: 15));
      expect(calcularPendientes([plan], const Periodo(2026, 10), DateTime(2026, 10, 14)), isEmpty);
      expect(calcularPendientes([plan], const Periodo(2026, 10), DateTime(2026, 10, 15)), hasLength(1));
    });

    test('cruza de diciembre a enero', () async {
      final plan = await leer(await crearFijo(primer: const Periodo(2026, 12)));
      final enero = DateTime(2027, 1, 20);
      expect(const Periodo(2026, 12).siguiente, const Periodo(2027, 1));
      expect(calcularPendientes([plan], const Periodo(2027, 1), enero).single.periodo, const Periodo(2027, 1));
      // Diciembre es "el mes anterior" y sigue a tiempo de confirmarse.
      expect(calcularPendientes([plan], const Periodo(2026, 12), enero), hasLength(1));
      expect(calcularPendientes([plan], const Periodo(2026, 11), enero), isEmpty);
    });

    test('ni meses futuros ni más viejos que el anterior', () async {
      final plan = await leer(await crearFijo(primer: const Periodo(2026, 1)));
      final hoy = DateTime(2026, 10, 20);
      expect(calcularPendientes([plan], const Periodo(2026, 11), hoy), isEmpty);
      expect(calcularPendientes([plan], const Periodo(2026, 8), hoy), isEmpty);
    });
  });

  group('cuotas', () {
    test('la última cuota absorbe el resto del redondeo', () async {
      final plan = await leer(await crearCuotas(pesos(100000), 3));
      expect(plan.montoDeCuota(1), const Dinero(3333333));
      expect(plan.montoDeCuota(2), const Dinero(3333333));
      expect(plan.montoDeCuota(3), const Dinero(3333334));
      expect(plan.montoRestante, pesos(100000));
    });

    test('adelantar varias cuotas es un gasto; borrarlo las devuelve todas', () async {
      final id = await crearCuotas(pesos(100000), 3);
      final movimiento = await planes((p) => p.adelantarCuotas(id, 3, fecha: DateTime(2026, 10, 2)));
      final plan = await leer(id);
      expect(plan.cuotasPagadas, 3);
      expect(plan.terminado, isTrue);
      expect(plan.periodosAplicados, {const Periodo(2026, 10), const Periodo(2026, 11), const Periodo(2026, 12)});
      final gasto = (await ConsultasLibro(db).movimientos()).single;
      expect(gasto.monto, pesos(100000));

      await ServicioLibro.transaccion(db, (l) => l.eliminar(movimiento));
      expect((await leer(id)).cuotasPagadas, 0);
    });

    test('confirmar después de adelantar sigue la numeración', () async {
      final id = await crearCuotas(pesos(90000), 3);
      await planes((p) => p.adelantarCuotas(id, 1, fecha: DateTime(2026, 10, 2)));
      final plan = await leer(id);
      final pendiente = calcularPendientes([plan], const Periodo(2026, 11), DateTime(2026, 11, 15)).single;
      expect(pendiente.descripcion, 'Heladera (cuota 2/3)');
      expect(await planes((p) => p.confirmar(id, const Periodo(2026, 11))), isTrue);
      expect((await leer(id)).cuotasPagadas, 2);
    });

    test('no se puede bajar el total por debajo de lo pagado', () async {
      final id = await crearCuotas(pesos(90000), 3);
      await planes((p) => p.adelantarCuotas(id, 2, fecha: DateTime(2026, 10, 2)));
      final plan = await leer(id);
      expect(
        planes((p) => p.actualizar(plan.copiaCon(totalCuotas: 1, total: pesos(30000), monto: pesos(30000)))),
        throwsA(isA<ErrorLibro>()),
      );
    });
  });

  test('el sueldo es un plan que se crea, actualiza y pausa', () async {
    final hoy = DateTime(2026, 10, 1);
    await planes((p) => p.fijarSueldo(pesos(850000), hoy: hoy));
    var sueldo = (await ServicioPlanes(db).sueldo())!;
    expect(sueldo.monto, pesos(850000));
    expect(sueldo.primerPeriodo, const Periodo(2026, 10));
    await planes((p) => p.fijarSueldo(pesos(900000), hoy: hoy));
    await planes((p) => p.fijarSueldo(const Dinero.cero(), hoy: hoy));
    sueldo = (await ServicioPlanes(db).sueldo())!;
    expect(sueldo.monto, pesos(900000));
    expect(sueldo.activo, isFalse);
  });
}
