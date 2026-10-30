import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../../movimientos/logica/mes_seleccionado_provider.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../movimientos/modelo/movimiento.dart';
import '../../movimientos/repositorio/movimiento_repositorio.dart';
import '../modelo/cuota.dart';
import 'cuotas_provider.dart';
import 'gastos_fijos_provider.dart';
import '../repositorio/cuota_repositorio.dart';
import '../repositorio/recurrencia_repositorio.dart';

part 'pendientes_provider.g.dart';

/// Un movimiento recurrente pendiente de confirmar para el mes en curso.
class PendienteRecurrencia {
  final String tipo; // 'sueldo' | 'fijo' | 'cuota'
  final int referenciaId;
  final String nombre;
  final double monto;
  final bool esIngreso;
  final int categoriaId;
  final int diaDebito; // día del mes en que corresponde debitar
  final Cuota? cuota;

  const PendienteRecurrencia({
    required this.tipo,
    required this.referenciaId,
    required this.nombre,
    required this.monto,
    required this.esIngreso,
    required this.categoriaId,
    this.diaDebito = 1,
    this.cuota,
  });

  String get clave => '$tipo:$referenciaId';
}

/// Calcula y aplica (con confirmación manual) los movimientos recurrentes del
/// mes seleccionado: sueldo como ingreso, gastos fijos y cuotas como gastos.
@riverpod
class PendientesMes extends _$PendientesMes {
  final RecurrenciaRepositorio _recurRepo = RecurrenciaRepositorio();
  final CuotaRepositorio _cuotaRepo = CuotaRepositorio();
  final MovimientoRepositorio _movRepo = MovimientoRepositorio();

  @override
  FutureOr<List<PendienteRecurrencia>> build() async {
    // IMPORTANTE: todos los ref.watch van ANTES del primer await. Si no,
    // Riverpod no registra la dependencia y la tarjeta de pendientes no se
    // actualiza al crear/editar un gasto fijo o una cuota.
    final mes = ref.watch(mesSeleccionadoProvider);
    final categorias = ref.watch(categoriasControladorProvider).valueOrNull ?? [];
    final salario = (ref.watch(ajustesControladorProvider).valueOrNull?['salarioMensual'] as double?) ?? 0.0;
    final fijos = ref.watch(gastosFijosControladorProvider).valueOrNull ?? [];
    final cuotas = ref.watch(cuotasControladorProvider).valueOrNull ?? [];

    final periodo = _periodo(mes);
    final aplicadas = await _recurRepo.obtenerAplicadas(periodo);

    // No mostramos pendientes de meses futuros.
    final ahora = DateTime.now();
    if (DateTime(mes.year, mes.month).isAfter(DateTime(ahora.year, ahora.month))) {
      return [];
    }
    // Tampoco generamos pendientes retroactivos de meses muy anteriores: sólo
    // el mes actual y el anterior (ventana para "ponerse al día"). Así no se
    // insertan sueldos/fijos/cuotas de hace meses con la configuración de hoy.
    if (DateTime(mes.year, mes.month).isBefore(DateTime(ahora.year, ahora.month - 1))) {
      return [];
    }
    final mesActual = mes.year == ahora.year && mes.month == ahora.month;
    // En el mes actual, un débito recién aparece a partir de su día. En meses
    // pasados se muestra siempre (quedó atrasado).
    bool debitoDisponible(int dia) => !mesActual || ahora.day >= dia;

    final pendientes = <PendienteRecurrencia>[];

    // Sueldo (ingreso) — referencia única id 0. Se debita el día 1.
    final catSueldo = _categoriaSueldo(categorias);
    if (salario > 0 && catSueldo != null && !aplicadas.contains('sueldo:0')) {
      pendientes.add(PendienteRecurrencia(
        tipo: 'sueldo',
        referenciaId: 0,
        nombre: 'Sueldo',
        monto: salario,
        esIngreso: true,
        categoriaId: catSueldo,
      ));
    }

    final catOtros = _categoriaOtrosGastos(categorias);

    // Gastos fijos activos (sólo si ya llegó su día de débito).
    for (final f in fijos) {
      if (!f.activo || f.id == null) continue;
      if (aplicadas.contains('fijo:${f.id}')) continue;
      if (!debitoDisponible(f.diaDebito)) continue;
      pendientes.add(PendienteRecurrencia(
        tipo: 'fijo',
        referenciaId: f.id!,
        nombre: f.nombre,
        monto: f.monto,
        esIngreso: false,
        categoriaId: _categoriaValida(f.categoriaId, categorias) ?? catOtros,
        diaDebito: f.diaDebito,
      ));
    }

    // Cuotas activas y no finalizadas (sólo si ya llegó su día de débito).
    for (final c in cuotas) {
      if (!c.activo || c.finalizada || c.id == null) continue;
      if (aplicadas.contains('cuota:${c.id}')) continue;
      if (!debitoDisponible(c.diaDebito)) continue;
      pendientes.add(PendienteRecurrencia(
        tipo: 'cuota',
        referenciaId: c.id!,
        nombre: '${c.nombre} (cuota ${c.cuotasPagadas + 1}/${c.totalCuotas})',
        monto: c.montoCuota,
        esIngreso: false,
        categoriaId: _categoriaValida(c.categoriaId, categorias) ?? catOtros,
        diaDebito: c.diaDebito,
        cuota: c,
      ));
    }

    return pendientes;
  }

  /// Confirma un pendiente: crea el movimiento y lo marca como aplicado.
  Future<void> confirmar(PendienteRecurrencia p) async {
    final mes = ref.read(mesSeleccionadoProvider);
    await _aplicar(p, mes);
    ref.invalidate(movimientosControladorProvider);
    if (p.tipo == 'cuota') ref.invalidate(cuotasControladorProvider);
    ref.invalidateSelf();
  }

  /// Confirma todos los pendientes del mes.
  Future<void> confirmarTodos() async {
    final items = state.valueOrNull ?? [];
    if (items.isEmpty) return;
    final mes = ref.read(mesSeleccionadoProvider);
    var huboCuota = false;
    for (final p in items) {
      await _aplicar(p, mes);
      if (p.tipo == 'cuota') huboCuota = true;
    }
    ref.invalidate(movimientosControladorProvider);
    if (huboCuota) ref.invalidate(cuotasControladorProvider);
    ref.invalidateSelf();
  }

  Future<void> _aplicar(PendienteRecurrencia p, DateTime mes) async {
    final periodo = _periodo(mes);
    final fecha = _fechaDebito(mes, p.diaDebito);

    final id = await _movRepo.insertar(Movimiento(
      monto: p.monto,
      fecha: fecha,
      descripcion: p.nombre,
      tipo: p.esIngreso ? 'ingreso' : 'gasto',
      categoriaId: p.categoriaId,
    ));

    await _recurRepo.registrar(
      tipo: p.tipo,
      referenciaId: p.referenciaId,
      periodo: periodo,
      movimientoId: id,
    );

    if (p.tipo == 'cuota' && p.cuota != null) {
      await _cuotaRepo.registrarPago(p.cuota!);
    }
  }

  String _periodo(DateTime mes) =>
      '${mes.year}-${mes.month.toString().padLeft(2, '0')}';

  /// Fecha del movimiento: el día de débito dentro del mes (acotado al último
  /// día del mes por las dudas).
  DateTime _fechaDebito(DateTime mes, int dia) {
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
    final d = dia.clamp(1, ultimoDia);
    return DateTime(mes.year, mes.month, d, 12);
  }

  int? _categoriaSueldo(List<Categoria> cats) {
    for (final c in cats) {
      if (c.tipo == 'ingreso' && c.nombre.toLowerCase() == 'sueldo') return c.id;
    }
    final ingresos = cats.where((c) => c.tipo == 'ingreso');
    return ingresos.isNotEmpty ? ingresos.first.id : null;
  }

  int _categoriaOtrosGastos(List<Categoria> cats) {
    for (final c in cats) {
      if (c.tipo == 'gasto' && c.nombre.toLowerCase().contains('otros')) return c.id!;
    }
    final gastos = cats.where((c) => c.tipo == 'gasto');
    return gastos.isNotEmpty ? gastos.first.id! : 0;
  }

  int? _categoriaValida(int? id, List<Categoria> cats) {
    if (id == null) return null;
    final coincide = cats.where((c) => c.id == id);
    return coincide.isEmpty ? null : id;
  }
}
