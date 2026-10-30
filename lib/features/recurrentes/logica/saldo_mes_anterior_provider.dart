import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../movimientos/repositorio/movimiento_repositorio.dart';
import '../../panel_control/logica/metas_provider.dart';
import '../../panel_control/modelo/meta.dart';
import '../repositorio/recurrencia_repositorio.dart';

part 'saldo_mes_anterior_provider.g.dart';

/// Maneja el "sobrante" del mes anterior: si quedó plata, se ofrece trasladarla
/// al mes actual o aportarla a una meta. Devuelve el monto sobrante (0 si no
/// hay o si ya se resolvió este mes).
@riverpod
class SaldoMesAnterior extends _$SaldoMesAnterior {
  final MovimientoRepositorio _movRepo = MovimientoRepositorio();
  final RecurrenciaRepositorio _recurRepo = RecurrenciaRepositorio();

  @override
  FutureOr<double> build() async {
    final periodo = _periodo();
    final resuelto = await _recurRepo.obtenerMovimientoId(tipo: 'saldoanterior', referenciaId: 0, periodo: periodo);
    // Si ya se registró (aunque sea con movimiento null = descartado), no mostrar.
    final aplicadas = await _recurRepo.obtenerAplicadas(periodo);
    if (resuelto != null || aplicadas.contains('saldoanterior:0')) return 0;

    final ahora = DateTime.now();
    final mesAnterior = DateTime(ahora.year, ahora.month - 1, 1);
    final tot = await _movRepo.obtenerTotalesMes(mesAnterior);
    // El sobrante es la plata libre que quedó: ingresos − gastos − lo que ya se
    // guardó en metas ese mes.
    final sobra = (tot['ingresos'] ?? 0) - (tot['gastos'] ?? 0) - (tot['ahorros'] ?? 0);
    return sobra > 0 ? sobra : 0;
  }

  /// Aporta el sobrante a una meta (convierte a USD si la meta es en dólares).
  Future<void> aportarAMeta(Meta meta, double montoPesos, double blue) async {
    await ref.read(metasControladorProvider.notifier).aportar(meta, montoPesos, blue: blue);
    await _recurRepo.registrar(tipo: 'saldoanterior', referenciaId: 0, periodo: _periodo());
    ref.invalidateSelf();
  }

  /// El usuario decide no hacer nada con el sobrante este mes.
  Future<void> descartar() async {
    await _recurRepo.registrar(tipo: 'saldoanterior', referenciaId: 0, periodo: _periodo());
    ref.invalidateSelf();
  }

  String _periodo() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }
}
