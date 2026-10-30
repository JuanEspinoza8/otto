import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../modelo/cuota.dart';
import '../repositorio/cuota_repositorio.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../movimientos/modelo/movimiento.dart';
import '../../movimientos/repositorio/movimiento_repositorio.dart';
import '../repositorio/recurrencia_repositorio.dart';

part 'cuotas_provider.g.dart';

/// Provider que gestiona la lista de cuotas en pago.
@riverpod
class CuotasControlador extends _$CuotasControlador {
  final CuotaRepositorio _repo = CuotaRepositorio();
  final MovimientoRepositorio _movRepo = MovimientoRepositorio();
  final RecurrenciaRepositorio _recurRepo = RecurrenciaRepositorio();

  @override
  FutureOr<List<Cuota>> build() async {
    return await _repo.obtenerTodas();
  }

  Future<void> agregar(Cuota cuota) async {
    await _repo.insertar(cuota);
    ref.invalidateSelf();
  }

  Future<void> actualizar(Cuota cuota) async {
    await _repo.actualizar(cuota);
    ref.invalidateSelf();
  }

  Future<void> eliminar(int id) async {
    await _repo.eliminar(id);
    ref.invalidateSelf();
  }

  Future<void> alternarActivo(Cuota cuota) async {
    await _repo.actualizar(cuota.copiaCon(activo: !cuota.activo));
    ref.invalidateSelf();
  }

  /// Paga [cantidad] cuotas: registra el gasto (cantidad × monto de la cuota)
  /// y avanza las cuotas pagadas. Si llega al total, la marca finalizada.
  Future<void> pagar(Cuota cuota, int cantidad) async {
    if (cantidad <= 0) return;
    final restantes = cuota.cuotasRestantes;
    final n = restantes > 0 ? cantidad.clamp(1, restantes) : cantidad;

    // Categoría del movimiento: la de la cuota, o "Deudas"/primer gasto.
    final cats = ref.read(categoriasControladorProvider).valueOrNull ?? [];
    int? catId = cuota.categoriaId;
    if (catId == null || !cats.any((c) => c.id == catId)) {
      final gastos = cats.where((c) => c.tipo == 'gasto');
      if (gastos.isNotEmpty) {
        catId = gastos
            .firstWhere((c) => c.nombre.toLowerCase().contains('deuda'), orElse: () => gastos.first)
            .id;
      }
    }

    int? movId;
    if (catId != null) {
      movId = await _movRepo.insertar(Movimiento(
        monto: cuota.montoCuota * n,
        fecha: DateTime.now(),
        descripcion: 'Cuotas: ${cuota.nombre}${n > 1 ? ' (x$n)' : ''}',
        tipo: 'gasto',
        categoriaId: catId,
      ));
    }

    final pagadas = (cuota.cuotasPagadas + n).clamp(0, cuota.totalCuotas);
    await _repo.actualizar(cuota.copiaCon(
      cuotasPagadas: pagadas,
      activo: pagadas < cuota.totalCuotas,
    ));

    // Fuente de verdad única: marcamos como aplicados el mes actual y los
    // siguientes (n-1), para que el recordatorio mensual de "pendientes" no
    // vuelva a cobrar estas cuotas (antes se podían cobrar dos veces).
    if (cuota.id != null) {
      final ahora = DateTime.now();
      for (int i = 0; i < n; i++) {
        final m = DateTime(ahora.year, ahora.month + i, 1);
        final periodo = '${m.year}-${m.month.toString().padLeft(2, '0')}';
        final aplicadas = await _recurRepo.obtenerAplicadas(periodo);
        if (!aplicadas.contains('cuota:${cuota.id}')) {
          await _recurRepo.registrar(
            tipo: 'cuota',
            referenciaId: cuota.id!,
            periodo: periodo,
            movimientoId: movId,
          );
        }
      }
    }

    ref.invalidate(movimientosControladorProvider);
    ref.invalidateSelf();
  }
}
