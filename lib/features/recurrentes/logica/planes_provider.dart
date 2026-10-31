import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/libro/libro_providers.dart';
import '../../../core/utilidades/fechas.dart';
import '../../configuracion/logica/servicio_notificaciones.dart';
import '../../movimientos/logica/mes_seleccionado_provider.dart';
import '../modelo/plan.dart';
import 'servicio_planes.dart';

part 'planes_provider.g.dart';

/// Corre [accion] en una transacción de planes y avisa que cambiaron los datos.
Future<T> escribirPlanes<T>(Ref ref, Future<T> Function(ServicioPlanes planes) accion) =>
    escribirEnTransaccion(ref, (txn) => accion(ServicioPlanes(txn)));

/// Sueldo, gastos fijos y cuotas.
@riverpod
class PlanesControlador extends _$PlanesControlador {
  @override
  Future<List<Plan>> build() async {
    ref.watch(versionDatosProvider);
    final db = await ref.watch(baseDatosProvider.future);
    return ServicioPlanes(db).planes();
  }

  Future<void> crear(Plan plan) async {
    await escribirPlanes(ref, (p) => p.crear(plan));
    await _reprogramarAvisos();
  }

  Future<void> crearCuotas(Plan plan, {int yaPagadas = 0}) =>
      escribirPlanes(ref, (p) => p.crearCuotas(plan, yaPagadas: yaPagadas));

  Future<void> actualizar(Plan plan) async {
    await escribirPlanes(ref, (p) => p.actualizar(plan));
    await _reprogramarAvisos();
  }

  Future<void> eliminar(Plan plan) async {
    await escribirPlanes(ref, (p) => p.eliminar(plan.id!));
    await _reprogramarAvisos();
  }

  Future<void> alternarActivo(Plan plan) => actualizar(plan.copiaCon(activo: !plan.activo));

  /// Paga [cantidad] cuotas juntas (un solo gasto).
  Future<void> adelantarCuotas(Plan plan, int cantidad) =>
      escribirPlanes(ref, (p) => p.adelantarCuotas(plan.id!, cantidad, fecha: DateTime.now()));

  /// Confirma un pendiente. Devuelve false si ya estaba confirmado.
  Future<bool> confirmar(Pendiente pendiente) =>
      escribirPlanes(ref, (p) => p.confirmar(pendiente.plan.id!, pendiente.periodo));

  /// "Ya lo cargué": resuelve el pendiente sin crear otro movimiento.
  Future<void> marcarSinMovimiento(Pendiente pendiente) =>
      escribirPlanes(ref, (p) => p.marcarSinMovimiento(pendiente.plan.id!, pendiente.periodo));

  /// Avisos push dos días antes del débito de cada gasto fijo activo.
  Future<void> _reprogramarAvisos() async {
    try {
      final db = await ref.read(baseDatosProvider.future);
      await ServicioNotificaciones.reprogramarFijos(await ServicioPlanes(db).planes(tipo: TipoPlan.fijo));
    } catch (_) {/* un fallo de notificaciones no frena la operación */}
  }
}

@riverpod
List<Plan> fijos(Ref ref) => (ref.watch(planesControladorProvider).valueOrNull ?? const [])
    .where((p) => p.tipo == TipoPlan.fijo)
    .toList();

@riverpod
List<Plan> cuotas(Ref ref) => (ref.watch(planesControladorProvider).valueOrNull ?? const [])
    .where((p) => p.tipo == TipoPlan.cuotas)
    .toList();

/// Pendientes del mes seleccionado.
@riverpod
Future<List<Pendiente>> pendientesMes(Ref ref) async {
  final planes = await ref.watch(planesControladorProvider.future);
  final mes = Periodo.de(ref.watch(mesSeleccionadoProvider));
  return calcularPendientes(planes, mes, DateTime.now());
}
