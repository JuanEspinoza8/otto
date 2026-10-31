import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/libro/libro_providers.dart';
import '../../../core/utilidades/fechas.dart';
import '../../recurrentes/repositorio/avisos_repositorio.dart';

part 'resumen_auto_provider.g.dart';

/// Mes anterior a resumir al empezar un mes nuevo, o null si ya se vio o no
/// tuvo movimientos.
@riverpod
class ResumenAuto extends _$ResumenAuto {
  bool _pospuesto = false;

  @override
  Future<Periodo?> build() async {
    if (_pospuesto) return null;
    final consultas = await consultasLibro(ref);
    final db = await ref.watch(baseDatosProvider.future);
    final anterior = Periodo.de(DateTime.now()).anterior;
    if (await AvisosRepositorio(db).resuelto(AvisosRepositorio.resumen, anterior)) return null;
    if ((await consultas.totalesMes(anterior)).vacio) return null;
    return anterior;
  }

  /// "Después": lo oculta hasta la próxima vez que se abra la app (no lo
  /// marca como visto, así se puede ver más tarde).
  void posponer() {
    _pospuesto = true;
    state = const AsyncData(null);
  }

  /// Marca el resumen del mes anterior como visto.
  Future<void> marcarVisto() => escribirEnTransaccion(
      ref, (txn) => AvisosRepositorio(txn).marcar(AvisosRepositorio.resumen, Periodo.de(DateTime.now()).anterior));
}
