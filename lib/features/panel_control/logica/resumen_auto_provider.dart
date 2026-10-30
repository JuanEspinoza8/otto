import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../movimientos/repositorio/movimiento_repositorio.dart';
import '../../recurrentes/repositorio/recurrencia_repositorio.dart';

part 'resumen_auto_provider.g.dart';

/// Indica si hay un resumen del mes anterior por mostrar (al arrancar el mes
/// nuevo). Devuelve la fecha del mes a resumir, o null si ya se vio / no hubo
/// movimientos.
@riverpod
class ResumenAuto extends _$ResumenAuto {
  final RecurrenciaRepositorio _recurRepo = RecurrenciaRepositorio();
  final MovimientoRepositorio _movRepo = MovimientoRepositorio();

  @override
  FutureOr<DateTime?> build() async {
    final ahora = DateTime.now();
    final prev = DateTime(ahora.year, ahora.month - 1, 1);
    final periodo = _periodo(prev);
    final aplicadas = await _recurRepo.obtenerAplicadas(periodo);
    if (aplicadas.contains('resumen:0')) return null;
    final tot = await _movRepo.obtenerTotalesMes(prev);
    if ((tot['ingresos'] ?? 0) == 0 && (tot['gastos'] ?? 0) == 0) return null;
    return prev;
  }

  /// Marca el resumen del mes anterior como visto.
  Future<void> marcarVisto() async {
    final ahora = DateTime.now();
    final prev = DateTime(ahora.year, ahora.month - 1, 1);
    await _recurRepo.registrar(tipo: 'resumen', referenciaId: 0, periodo: _periodo(prev));
    ref.invalidateSelf();
  }

  String _periodo(DateTime m) => '${m.year}-${m.month.toString().padLeft(2, '0')}';
}
