import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../modelo/gasto_fijo.dart';
import '../repositorio/gasto_fijo_repositorio.dart';
import '../../configuracion/logica/servicio_notificaciones.dart';

part 'gastos_fijos_provider.g.dart';

/// Provider que gestiona la lista de gastos fijos mensuales.
@riverpod
class GastosFijosControlador extends _$GastosFijosControlador {
  final GastoFijoRepositorio _repo = GastoFijoRepositorio();

  @override
  FutureOr<List<GastoFijo>> build() async {
    return await _repo.obtenerTodos();
  }

  Future<void> agregar(GastoFijo gasto) async {
    await _repo.insertar(gasto);
    ref.invalidateSelf();
    await _reprogramarAvisos();
  }

  Future<void> actualizar(GastoFijo gasto) async {
    await _repo.actualizar(gasto);
    ref.invalidateSelf();
    await _reprogramarAvisos();
  }

  Future<void> eliminar(int id) async {
    await _repo.eliminar(id);
    ref.invalidateSelf();
    await _reprogramarAvisos();
  }

  Future<void> alternarActivo(GastoFijo gasto) async {
    await _repo.actualizar(gasto.copiaCon(activo: !gasto.activo));
    ref.invalidateSelf();
    await _reprogramarAvisos();
  }

  /// Reprograma los avisos push de débito según los fijos actuales.
  Future<void> _reprogramarAvisos() async {
    try {
      await ServicioNotificaciones.reprogramarFijos(await _repo.obtenerTodos());
    } catch (_) {/* no bloquear la operación por un fallo de notificaciones */}
  }
}
